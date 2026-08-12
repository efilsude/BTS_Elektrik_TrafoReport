import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../excel/cell_mapping.dart';
import '../excel/excel_generator.dart';
import '../models/report_model.dart';

class ReportService extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Report? _activeReport;
  bool _isLoading = false;
  Timer? _debounceTimer;

  Report? get activeReport => _activeReport;
  bool get isLoading => _isLoading;
  bool get hasActiveReport => _activeReport != null;

  /// Start a new report creation flow
  void startNewReport({
    required String reportType,
    required String subType,
    required String transformerType,
  }) {
    final String dateStr =
        '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}';

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
        'photos': <String, dynamic>{},
      },
      currentStep: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Update a single form field in dataJson
  void updateField(String key, dynamic value) {
    if (_activeReport == null) return;

    final Map<String, dynamic> updatedData =
        Map<String, dynamic>.from(_activeReport!.dataJson);

    if (key.contains('.')) {
      final List<String> parts = key.split('.');
      final String parentKey = parts[0];
      final String childKey = parts[1];

      final Map<String, dynamic> parentMap = Map<String, dynamic>.from(
          updatedData[parentKey] as Map? ?? <String, dynamic>{});
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
      final String dateStr = ExcelCellMapping.formatDateDisplay(updatedData['test_date'], fallback: _activeReport!.createdAt);
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

  /// Copy picked photo to app documents directory and save path locally in both top-level and photos map
  Future<String?> savePhotoLocally(String photoKey, File pickedFile) async {
    if (_activeReport == null) return null;

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String photoDir = p.join(appDir.path, 'photos', _activeReport!.id);
      final Directory dir = Directory(photoDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String ext = p.extension(pickedFile.path).isEmpty ? '.jpg' : p.extension(pickedFile.path);
      final String fileName = '${photoKey}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final String targetPath = p.join(photoDir, fileName);

      final File savedFile = await pickedFile.copy(targetPath);

      // Save photo entry in local DB report_photos table
      await _dbHelper.addReportPhoto(_activeReport!.id, photoKey, savedFile.path);

      // Update dataJson: both top-level (e.g. photo_label) AND dataJson['photos'][photoKey]
      final Map<String, dynamic> updatedData = Map<String, dynamic>.from(_activeReport!.dataJson);
      updatedData[photoKey] = savedFile.path;

      final Map<String, dynamic> photosMap = Map<String, dynamic>.from(updatedData['photos'] as Map? ?? <String, dynamic>{});
      photosMap[photoKey] = savedFile.path;
      updatedData['photos'] = photosMap;

      _activeReport = _activeReport!.copyWith(dataJson: updatedData);
      notifyListeners();

      await saveDraft();
      return savedFile.path;
    } catch (e) {
      debugPrint('[TrafoReport] Fotoğraf kaydetme hatası: $e');
      return null;
    }
  }

  /// Delete photo locally (clears top-level key, photos map, DB entry, and physical file)
  Future<void> deletePhotoLocally(String photoKey) async {
    if (_activeReport == null) return;

    try {
      final Map<String, dynamic> updatedData = Map<String, dynamic>.from(_activeReport!.dataJson);
      final dynamic existingPath = updatedData[photoKey] ?? (updatedData['photos'] is Map ? updatedData['photos'][photoKey] : null);

      // Clear top-level key
      updatedData.remove(photoKey);

      // Clear nested photos map
      if (updatedData['photos'] is Map) {
        final Map<String, dynamic> photosMap = Map<String, dynamic>.from(updatedData['photos'] as Map);
        photosMap.remove(photoKey);
        updatedData['photos'] = photosMap;
      }

      // Delete physical file if exists
      if (existingPath is String && existingPath.isNotEmpty) {
        final File file = File(existingPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete photo record from DB report_photos table if present
      final List<Map<String, String>> dbPhotos = await _dbHelper.getReportPhotos(_activeReport!.id);
      for (final Map<String, String> photoMap in dbPhotos) {
        if (photoMap['kind'] == photoKey) {
          final String? photoId = photoMap['id'];
          if (photoId != null) {
            await _dbHelper.deleteReportPhoto(photoId);
          }
        }
      }

      _activeReport = _activeReport!.copyWith(dataJson: updatedData);
      notifyListeners();

      await saveDraft();
    } catch (e) {
      debugPrint('[TrafoReport] Fotoğraf silme hatası: $e');
    }
  }

  /// Immediately save draft when stepping or navigating
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

  /// Auto-save and Manual save logic to local SQLite
  Future<void> saveDraft({bool isAutoSave = false}) async {
    if (_activeReport == null) return;

    try {
      _activeReport = await _dbHelper.saveOrUpdateReport(_activeReport!);
    } catch (e) {
      debugPrint('[TrafoReport] Yerel taslak kaydetme hatası: $e');
    }
  }

  /// Load a single draft from SQLite
  Future<Report?> loadDraft(String reportId) async {
    try {
      return await _dbHelper.getReportById(reportId);
    } catch (e) {
      return null;
    }
  }

  /// Delete a draft from local SQLite
  Future<void> deleteDraft(String reportId) async {
    try {
      await _dbHelper.deleteReport(reportId);
    } catch (e) {
      debugPrint('[TrafoReport] Rapor silme hatası: $e');
    }

    if (_activeReport?.id == reportId) {
      clearActiveReport();
    }
    notifyListeners();
  }

  /// Fetch reports list from local SQLite with optional filters
  Future<List<Report>> getReports({
    String? search,
    String? reportType,
    String? maintenanceType,
    String? status,
  }) async {
    try {
      final List<Report> allReports = await _dbHelper.getReports();

      return allReports.where((Report r) {
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
    } catch (e) {
      debugPrint('[TrafoReport] Rapor havuzu çekme hatası: $e');
      return <Report>[];
    }
  }

  /// Fetch user drafts from local SQLite
  Future<List<Report>> getDrafts() async {
    return await getReports(status: 'draft');
  }

  /// Finalize report locally in SQLite and generate native Excel file
  Future<File?> finalizeReport(String reportId, {String? signaturePath}) async {
    _isLoading = true;
    notifyListeners();

    try {
      Report? reportToFinalize = _activeReport?.id == reportId
          ? _activeReport!
          : await loadDraft(reportId);

      if (reportToFinalize == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // Generate filled native Excel file from asset template
      final File excelFile = await ExcelGenerator.generateReportExcel(
        report: reportToFinalize,
        signaturePath: signaturePath,
      );

      final Map<String, dynamic> updatedData = Map<String, dynamic>.from(reportToFinalize.dataJson);
      updatedData['excel_path'] = excelFile.path;

      final Report finalizedReport = reportToFinalize.copyWith(
        status: 'finalized',
        dataJson: updatedData,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.saveOrUpdateReport(finalizedReport);

      if (_activeReport?.id == reportId) {
        _activeReport = finalizedReport;
      }

      _isLoading = false;
      notifyListeners();
      return excelFile;
    } catch (e, stackTrace) {
      debugPrint('[TrafoReport] Rapor kesinleştirme/Excel üretme hatası: $e\n$stackTrace');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Fetch all final reports from local SQLite
  Future<List<Report>> getFinalReports() async {
    return await getReports(status: 'finalized');
  }

  /// Get report by ID
  Future<Report?> getReportById(String reportId) async {
    return await _dbHelper.getReportById(reportId);
  }

  /// Download / Get generated Excel file on device
  Future<File?> downloadExcelFile(String reportId, String title) async {
    final Report? report = await getReportById(reportId);
    if (report == null) return null;

    final String? excelPath = report.dataJson['excel_path'] as String?;
    if (excelPath != null && await File(excelPath).exists()) {
      return File(excelPath);
    }

    // Re-generate if file missing
    return await ExcelGenerator.generateReportExcel(report: report);
  }

  /// Open Excel file on device using native intent
  Future<void> openExcelFile(File file) async {
    try {
      final OpenResult result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        debugPrint('[TrafoReport] Dosya açılamadı: ${result.message}');
      }
    } catch (e) {
      debugPrint('[TrafoReport] Dosya açma hatası: $e');
    }
  }

  /// Share Excel file via native share sheet
  Future<void> shareExcelFile(File file, String title) async {
    try {
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: 'BTS Elektrik Trafo Bakım & Test Raporu: $title',
      );
    } catch (e) {
      debugPrint('[TrafoReport] Dosya paylaşma hatası: $e');
    }
  }
}
