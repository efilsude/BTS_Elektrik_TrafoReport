import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/report_model.dart';

class ReportService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyDraftsPrefix = 'report_draft_';
  static const String _keyFinalReports = 'final_reports_list';

  Report? _activeReport;
  bool _isLoading = false;
  Timer? _debounceTimer;

  Report? get activeReport => _activeReport;
  bool get isLoading => _isLoading;
  bool get hasActiveReport => _activeReport != null;

  // Start new report creation flow
  void startNewReport({
    required String reportType,
    required String subType,
    required String transformerType,
  }) {
    _activeReport = Report(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Yeni Rapor - ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
      reportType: reportType,
      subType: subType,
      transformerType: transformerType,
      customerName: '',
      trafoLabel: '',
      status: 'draft',
      dataJson: <String, dynamic>{
        'report_date': '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
        'test_date': '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
        // Measurement sub-structures to avoid null checks
        'winding_resistance': <String, dynamic>{},
        'insulation': <String, dynamic>{},
        'ttr': <String, dynamic>{},
        'grounding': <String, dynamic>{},
        'breaker_contact_resistance': <String, dynamic>{},
        'breaker_timing': <String, dynamic>{},
        'oil_checks': <String, dynamic>{},
        'dry_checks': <String, dynamic>{},
        'hermetic_checks': <String, dynamic>{},
      },
      currentStep: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // Update a single form field in dataJson
  void updateField(String key, dynamic value) {
    if (_activeReport == null) return;

    final Map<String, dynamic> updatedData = Map<String, dynamic>.from(_activeReport!.dataJson);
    
    // Support nested updating, e.g. "winding_resistance.r_phase"
    if (key.contains('.')) {
      final List<String> parts = key.split('.');
      final String parentKey = parts[0];
      final String childKey = parts[1];
      
      final Map<String, dynamic> parentMap = Map<String, dynamic>.from(updatedData[parentKey] as Map? ?? <String, dynamic>{});
      parentMap[childKey] = value;
      updatedData[parentKey] = parentMap;
    } else {
      updatedData[key] = value;
    }

    // Dynamic field updates for customer name and label
    String customer = _activeReport!.customerName;
    String label = _activeReport!.trafoLabel;
    if (key == 'customer_name') {
      customer = value.toString();
    } else if (key == 'trafo_label') {
      label = value.toString();
    }

    // Generate standard filename as title
    String title = _activeReport!.title;
    if (customer.isNotEmpty && label.isNotEmpty) {
      final String dateStr = updatedData['test_date'] ?? '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}';
      title = '$customer - $label - $dateStr';
    }

    _activeReport = _activeReport!.copyWith(
      dataJson: updatedData,
      customerName: customer,
      trafoLabel: label,
      title: title,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Trigger auto-save debounce (2-3 seconds)
    _triggerAutoSaveDebounce();
  }

  // Immediately save draft when stepping or navigating
  Future<void> updateStep(int step) async {
    if (_activeReport == null) return;
    _activeReport = _activeReport!.copyWith(currentStep: step);
    notifyListeners();
    await saveDraft();
  }

  // Set active report directly (e.g. when resuming a draft)
  void resumeReport(Report report) {
    _activeReport = report;
    notifyListeners();
  }

  // Discard/clear active report creation
  void clearActiveReport() {
    _activeReport = null;
    _debounceTimer?.cancel();
    notifyListeners();
  }

  // Trigger Debounced Auto-save
  void _triggerAutoSaveDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      await saveDraft(isAutoSave: true);
    });
  }

  // Auto-save and Manual save logic
  Future<void> saveDraft({bool isAutoSave = false}) async {
    if (_activeReport == null) return;

    try {
      final String draftJson = jsonEncode(_activeReport!.toJson());
      await _secureStorage.write(
        key: '$_keyDraftsPrefix${_activeReport!.id}',
        value: draftJson,
      );
      debugPrint(isAutoSave ? '[TrafoReport] Otomatik kaydedildi.' : '[TrafoReport] Taslak kaydedildi.');
    } catch (e) {
      debugPrint('[TrafoReport] Taslak kaydetme hatasi: $e');
    }
  }

  // Load a single draft
  Future<Report?> loadDraft(String reportId) async {
    try {
      final String? jsonStr = await _secureStorage.read(key: '$_keyDraftsPrefix$reportId');
      if (jsonStr == null) return null;
      return Report.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // Delete a draft from secure storage
  Future<void> deleteDraft(String reportId) async {
    await _secureStorage.delete(key: '$_keyDraftsPrefix$reportId');
    if (_activeReport?.id == reportId) {
      clearActiveReport();
    }
    notifyListeners();
  }

  // Fetch all local drafts
  Future<List<Report>> getDrafts() async {
    final List<Report> drafts = <Report>[];
    try {
      final Map<String, String> allKeys = await _secureStorage.readAll();
      for (final String key in allKeys.keys) {
        if (key.startsWith(_keyDraftsPrefix)) {
          final String? jsonStr = allKeys[key];
          if (jsonStr != null) {
            drafts.add(Report.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>));
          }
        }
      }
      // Sort by last updated
      drafts.sort((Report a, Report b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      debugPrint('[TrafoReport] Taslak listesi yukleme hatasi: $e');
    }
    return drafts;
  }

  // Finalize report (Mark status = 'final', delete draft, save to final list)
  Future<bool> finalizeReport(String reportId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      Report? reportToFinalize;
      
      if (_activeReport?.id == reportId) {
        reportToFinalize = _activeReport!.copyWith(status: 'final');
      } else {
        final Report? loaded = await loadDraft(reportId);
        if (loaded != null) {
          reportToFinalize = loaded.copyWith(status: 'final');
        }
      }

      if (reportToFinalize == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Add to final list
      final List<Report> finalReports = await getFinalReports();
      finalReports.insert(0, reportToFinalize);
      
      final List<Map<String, dynamic>> jsonList = finalReports.map((Report r) => r.toJson()).toList();
      await _secureStorage.write(key: _keyFinalReports, value: jsonEncode(jsonList));

      // Remove from drafts
      await deleteDraft(reportId);
      clearActiveReport();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch all final reports
  Future<List<Report>> getFinalReports() async {
    final List<Report> list = <Report>[];
    try {
      final String? jsonStr = await _secureStorage.read(key: _keyFinalReports);
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
        for (final dynamic item in decoded) {
          list.add(Report.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (e) {
      debugPrint('[TrafoReport] Kesin rapor listesi yukleme hatasi: $e');
    }
    return list;
  }
}
