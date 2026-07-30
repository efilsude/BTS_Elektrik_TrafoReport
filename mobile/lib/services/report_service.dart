import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/config.dart';
import '../models/report_model.dart';
import 'storage_service.dart';

class ReportService extends ChangeNotifier {
  final StorageService _storageService = StorageService();
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
    final String dateStr = '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}';
    _activeReport = Report(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Yeni Rapor - $dateStr',
      reportType: reportType,
      subType: subType,
      transformerType: transformerType,
      customerName: '',
      trafoLabel: '',
      status: 'draft',
      dataJson: <String, dynamic>{
        'report_date': dateStr,
        'test_date': dateStr,
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

    String customer = _activeReport!.customerName;
    String label = _activeReport!.trafoLabel;
    if (key == 'customer_name') {
      customer = value.toString();
    } else if (key == 'trafo_label') {
      label = value.toString();
    }

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

    _triggerAutoSaveDebounce();
  }

  // Immediately save draft when stepping or navigating
  Future<void> updateStep(int step) async {
    if (_activeReport == null) return;
    _activeReport = _activeReport!.copyWith(currentStep: step);
    notifyListeners();
    await saveDraft();
  }

  void resumeReport(Report report) {
    _activeReport = report;
    notifyListeners();
  }

  void clearActiveReport() {
    _activeReport = null;
    _debounceTimer?.cancel();
    notifyListeners();
  }

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
      
      // If server is available, attempt syncing draft: POST/PUT /reports
      final String? token = await _storageService.getAccessToken();
      if (token != null && !token.startsWith('mock_')) {
        try {
          final Map<String, dynamic> body = <String, dynamic>{
            'title': _activeReport!.title,
            'report_type': _activeReport!.reportType,
            'maintenance_type': _activeReport!.subType,
            'status': 'draft',
            'customer_name': _activeReport!.customerName,
            'trafo_label': _activeReport!.trafoLabel,
            'test_date': _activeReport!.dataJson['test_date'] ?? '',
            'report_date': _activeReport!.dataJson['report_date'] ?? '',
            'data_json': _activeReport!.dataJson,
          };

          if (_activeReport!.id.startsWith('rep_')) {
            // First time posting to backend API
            final http.Response response = await http.post(
              Uri.parse('${AppConfig.apiBaseUrl}/reports'),
              headers: <String, String>{
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(body),
            ).timeout(const Duration(seconds: 5));

            if (response.statusCode == 201 || response.statusCode == 200) {
              final Map<String, dynamic> resData = jsonDecode(response.body) as Map<String, dynamic>;
              if (resData.containsKey('id')) {
                _activeReport = _activeReport!.copyWith(id: resData['id'].toString());
              }
            }
          } else {
            // Updating existing report on backend API
            await http.put(
              Uri.parse('${AppConfig.apiBaseUrl}/reports/${_activeReport!.id}'),
              headers: <String, String>{
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(body),
            ).timeout(const Duration(seconds: 5));
          }
        } catch (_) {}
      }
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

  // Delete a draft from secure storage & API
  Future<void> deleteDraft(String reportId) async {
    await _secureStorage.delete(key: '$_keyDraftsPrefix$reportId');
    
    // Also attempt deleting on API if non-mock token exists
    final String? token = await _storageService.getAccessToken();
    if (token != null && !token.startsWith('mock_') && !reportId.startsWith('rep_')) {
      try {
        await http.delete(
          Uri.parse('${AppConfig.apiBaseUrl}/reports/$reportId'),
          headers: <String, String>{'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }

    if (_activeReport?.id == reportId) {
      clearActiveReport();
    }
    notifyListeners();
  }

  // Fetch reports list (Online from API_CONTRACT §5.1 or fallback to local)
  Future<List<Report>> getReports({
    String? search,
    String? reportType,
    String? maintenanceType,
    String? status,
  }) async {
    final String? token = await _storageService.getAccessToken();
    
    // 1. Online API call if real token exists
    if (token != null && !token.startsWith('mock_')) {
      try {
        final Map<String, String> queryParams = <String, String>{};
        if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();
        if (reportType != null && reportType.isNotEmpty) queryParams['report_type'] = reportType;
        if (maintenanceType != null && maintenanceType.isNotEmpty) queryParams['maintenance_type'] = maintenanceType;
        if (status != null && status.isNotEmpty) queryParams['status'] = status;

        final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}/reports').replace(queryParameters: queryParams);
        final http.Response response = await http.get(
          uri,
          headers: <String, String>{'Authorization': 'Bearer $token'},
        ).timeout(AppConfig.requestTimeout);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
          final List<dynamic> items = data['items'] as List<dynamic>? ?? <dynamic>[];
          final List<Report> apiReports = items.map((dynamic json) => Report.fromJson(json as Map<String, dynamic>)).toList();
          return apiReports;
        }
      } catch (e) {
        debugPrint('[TrafoReport] Online rapor havuzu alinirken hata, yerel bellege geciliyor: $e');
      }
    }

    // 2. Offline / Local fallback: combine final reports and local drafts
    final List<Report> localReports = <Report>[];
    localReports.addAll(await getFinalReports());
    localReports.addAll(await getDrafts());

    // Apply filtering on local reports
    return localReports.where((Report r) {
      if (reportType != null && reportType.isNotEmpty && r.reportType != reportType) return false;
      if (maintenanceType != null && maintenanceType.isNotEmpty && r.subType != maintenanceType) return false;
      if (status != null && status.isNotEmpty && r.status != status) return false;
      if (search != null && search.trim().isNotEmpty) {
        final String query = search.trim().toLowerCase();
        final bool matchTitle = r.title.toLowerCase().contains(query);
        final bool matchCustomer = r.customerName.toLowerCase().contains(query);
        final bool matchLabel = r.trafoLabel.toLowerCase().contains(query);
        if (!matchTitle && !matchCustomer && !matchLabel) return false;
      }
      return true;
    }).toList();
  }

  // Fetch user drafts (GET /drafts per API_CONTRACT §5.2 or local)
  Future<List<Report>> getDrafts() async {
    final String? token = await _storageService.getAccessToken();
    
    if (token != null && !token.startsWith('mock_')) {
      try {
        final http.Response response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/drafts'),
          headers: <String, String>{'Authorization': 'Bearer $token'},
        ).timeout(AppConfig.requestTimeout);

        if (response.statusCode == 200) {
          final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;
          return list.map((dynamic item) => Report.fromJson(item as Map<String, dynamic>)).toList();
        }
      } catch (_) {}
    }

    // Local secure storage fallback
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
      drafts.sort((Report a, Report b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      debugPrint('[TrafoReport] Yerel taslak listesi yukleme hatasi: $e');
    }
    return drafts;
  }

  // Finalize report (POST /reports/{id}/finalize per API_CONTRACT §5.8 or local)
  Future<bool> finalizeReport(String reportId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      Report? reportToFinalize = _activeReport?.id == reportId
          ? _activeReport!.copyWith(status: 'final')
          : await loadDraft(reportId);

      if (reportToFinalize == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      reportToFinalize = reportToFinalize.copyWith(status: 'final');

      final String? token = await _storageService.getAccessToken();
      if (token != null && !token.startsWith('mock_') && !reportId.startsWith('rep_')) {
        try {
          final http.Response response = await http.post(
            Uri.parse('${AppConfig.apiBaseUrl}/reports/$reportId/finalize'),
            headers: <String, String>{'Authorization': 'Bearer $token'},
          ).timeout(AppConfig.requestTimeout);

          if (response.statusCode == 200) {
            debugPrint('[TrafoReport] Rapor API üzerinde kesinleştirildi.');
          }
        } catch (_) {}
      }

      // Add to local final list & remove from drafts
      final List<Report> finalReports = await getFinalReports();
      finalReports.insert(0, reportToFinalize);
      
      final List<Map<String, dynamic>> jsonList = finalReports.map((Report r) => r.toJson()).toList();
      await _secureStorage.write(key: _keyFinalReports, value: jsonEncode(jsonList));

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

  // Download & Save Excel file (GET /reports/{id}/download per API_CONTRACT §5.9 or generate placeholder)
  Future<File?> downloadExcelFile(String reportId, String title) async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String cleanFileName = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final String filePath = '${appDocDir.path}/$cleanFileName.xlsx';
    final File localFile = File(filePath);

    final String? token = await _storageService.getAccessToken();

    if (token != null && !token.startsWith('mock_') && !reportId.startsWith('rep_')) {
      try {
        final http.Response response = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/reports/$reportId/download'),
          headers: <String, String>{'Authorization': 'Bearer $token'},
        ).timeout(AppConfig.requestTimeout);

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await localFile.writeAsBytes(response.bodyBytes);
          return localFile;
        }
      } catch (e) {
        debugPrint('[TrafoReport] Excel indirme hatasi: $e');
      }
    }

    // Fallback: Write local placeholder file
    final String mockContent = 'TrafoReport Excel Raporu: $title\nRapor ID: $reportId\nTarih: ${DateTime.now()}';
    await localFile.writeAsString(mockContent);
    return localFile;
  }

  // Open Excel file on device using native intent
  Future<void> openExcelFile(File file) async {
    try {
      final OpenResult result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        debugPrint('[TrafoReport] Dosya acilamadi: ${result.message}');
      }
    } catch (e) {
      debugPrint('[TrafoReport] Dosya acma hatasi: $e');
    }
  }

  // Share Excel file via native share sheet
  Future<void> shareExcelFile(File file, String title) async {
    try {
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: 'BTS Elektrik Trafo Bakım & Test Raporu: $title',
      );
    } catch (e) {
      debugPrint('[TrafoReport] Dosya paylasma hatasi: $e');
    }
  }
}
