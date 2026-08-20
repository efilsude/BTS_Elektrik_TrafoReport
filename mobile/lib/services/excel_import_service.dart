import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../excel/cell_mapping.dart';
import '../models/report_model.dart';

/// Result summary container for Excel ZIP import operation
class ExcelImportResult {
  final int totalFiles;
  final int successCount;
  final int failureCount;
  final int skippedCount;
  final List<String> successMessages;
  final List<String> failureDetails;
  final List<String> duplicateDetails;

  ExcelImportResult({
    required this.totalFiles,
    required this.successCount,
    required this.failureCount,
    required this.skippedCount,
    required this.successMessages,
    required this.failureDetails,
    required this.duplicateDetails,
  });
}

class ExcelImportService {
  /// Reads a ZIP archive containing past Excel (.xlsx) reports, parses valid TrafoReport templates,
  /// checks for duplicates against existing DB records, and saves new reports to SQLite DB.
  static Future<ExcelImportResult> importReportsFromZip(
    File zipFile, {
    void Function(int current, int total, String currentFilename)? onProgress,
  }) async {
    if (!await zipFile.exists()) {
      throw Exception('ZIP dosyası bulunamadı.');
    }

    final List<int> zipBytes = await zipFile.readAsBytes();
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
      if (archive.files.isEmpty) {
        throw Exception('ZIP dosyası okunamadı veya bozuk.');
      }
    } catch (e) {
      if (e.toString().contains('ZIP dosyası')) {
        rethrow;
      }
      throw Exception('ZIP dosyası okunamadı veya bozuk.');
    }

    // 1. Filter valid .xlsx entries (supporting root and nested subdirectories)
    final List<ArchiveFile> excelEntries = <ArchiveFile>[];
    for (final ArchiveFile entry in archive) {
      if (!entry.isFile) continue;
      final String normalizedPath = entry.name.replaceAll('\\', '/');

      // Security: Guard against path traversal attacks (../)
      if (normalizedPath.contains('../') || normalizedPath.contains('..\\')) {
        continue;
      }

      final String baseName = p.basename(normalizedPath);
      // Skip hidden files, system files, and temp files
      if (baseName.startsWith('.') || baseName.startsWith('~\$') || normalizedPath.contains('__MACOSX')) {
        continue;
      }

      if (baseName.toLowerCase().endsWith('.xlsx')) {
        excelEntries.add(entry);
      }
    }

    if (excelEntries.isEmpty) {
      throw Exception('ZIP dosyasında içe aktarılabilecek Excel raporu bulunamadı.');
    }

    // 2. Fetch existing reports for duplicate detection
    final List<Report> existingReports = await DatabaseHelper.instance.getReports();

    int successCount = 0;
    int failureCount = 0;
    int skippedCount = 0;

    final List<String> successMessages = <String>[];
    final List<String> failureDetails = <String>[];
    final List<String> duplicateDetails = <String>[];

    final int total = excelEntries.length;

    for (int i = 0; i < total; i++) {
      final ArchiveFile fileEntry = excelEntries[i];
      final String filename = p.basename(fileEntry.name.replaceAll('\\', '/'));

      if (onProgress != null) {
        onProgress(i + 1, total, filename);
      }

      try {
        final List<int> fileBytes = fileEntry.content as List<int>;
        if (fileBytes.isEmpty) {
          failureCount++;
          failureDetails.add('$filename — Boş dosya.');
          continue;
        }

        // Decode Excel workbook in memory
        Excel excel;
        try {
          excel = Excel.decodeBytes(fileBytes);
        } catch (_) {
          failureCount++;
          failureDetails.add('$filename — Bozuk Excel dosyası.');
          continue;
        }

        // Validate and parse report from Excel
        final Report? parsedReport = _parseExcelWorkbook(excel, filename);
        if (parsedReport == null) {
          failureCount++;
          failureDetails.add('$filename — Geçersiz TrafoReport Excel formatı.');
          continue;
        }

        // Duplicate check against database and currently imported list
        final bool isDuplicate = _checkDuplicate(parsedReport, existingReports);
        if (isDuplicate) {
          skippedCount++;
          duplicateDetails.add('$filename — Bu rapor zaten içe aktarılmış.');
          continue;
        }

        // Save report to SQLite DB
        final Report saved = await DatabaseHelper.instance.saveOrUpdateReport(parsedReport);
        existingReports.add(saved); // Add to local list to prevent duplicate matching within same ZIP run

        successCount++;
        final String labelInfo = saved.customerName.isNotEmpty ? saved.customerName : (saved.trafoLabel.isNotEmpty ? saved.trafoLabel : filename);
        successMessages.add('$filename ($labelInfo)');
      } catch (e) {
        failureCount++;
        failureDetails.add('$filename — İşleme hatası ($e)');
      }
    }

    return ExcelImportResult(
      totalFiles: total,
      successCount: successCount,
      failureCount: failureCount,
      skippedCount: skippedCount,
      successMessages: successMessages,
      failureDetails: failureDetails,
      duplicateDetails: duplicateDetails,
    );
  }

  /// Finds sheet by case-insensitive name match
  static Sheet? _findSheet(Excel excel, String targetName) {
    final String normTarget = targetName.trim().toLowerCase();
    for (final String sheetName in excel.tables.keys) {
      if (sheetName.trim().toLowerCase() == normTarget) {
        return excel.tables[sheetName];
      }
    }
    return null;
  }

  /// Safely extracts string value from a cell coordinate string (e.g. 'D9')
  static String _getCellValue(Sheet sheet, String cellRef) {
    try {
      final CellIndex index = CellIndex.indexByString(cellRef);
      final Data? cellData = sheet.cell(index);
      if (cellData == null || cellData.value == null) return '';

      final dynamic val = cellData.value;
      if (val is TextCellValue) return val.value.toString().trim();
      if (val is IntCellValue) return val.value.toString().trim();
      if (val is DoubleCellValue) {
        final double d = val.value;
        if (d == d.roundToDouble()) {
          return d.toInt().toString();
        }
        return d.toString().trim();
      }
      if (val is BoolCellValue) return val.value ? 'true' : 'false';
      if (val is DateCellValue) {
        return '${val.day.toString().padLeft(2, '0')}.${val.month.toString().padLeft(2, '0')}.${val.year}';
      }
      return val.toString().trim();
    } catch (_) {
      return '';
    }
  }

  /// Validates format and parses metadata & measurement data into a Report model instance
  static Report? _parseExcelWorkbook(Excel excel, String filename) {
    final Sheet? kapakSheet = _findSheet(excel, 'KAPAK SAYFASI');
    final Sheet? anaSheet = _findSheet(excel, 'ANA SAYFA');

    // Reject non-TrafoReport Excel files immediately
    if (kapakSheet == null || anaSheet == null) {
      return null;
    }

    // Determine transformer type ('hermetik', 'kuru_tip', 'gt')
    String transformerType = 'hermetik';

    bool isMarked(String v) => v.isNotEmpty && v != '0' && v.toLowerCase() != 'false';

    final String markKuru21 = _getCellValue(anaSheet, 'U21');
    final String markKuru19 = _getCellValue(anaSheet, 'U19');
    final String markGt21 = _getCellValue(anaSheet, 'P21');
    final String markGt19 = _getCellValue(anaSheet, 'P19');
    final String markHerm21 = _getCellValue(anaSheet, 'I21');
    final String markHerm19 = _getCellValue(anaSheet, 'I19');

    if (isMarked(markKuru21) || isMarked(markKuru19)) {
      transformerType = 'kuru_tip';
    } else if (isMarked(markGt21) || isMarked(markGt19) || _findSheet(excel, 'YAĞ RAPORU') != null) {
      transformerType = 'gt';
    } else if (isMarked(markHerm21) || isMarked(markHerm19)) {
      transformerType = 'hermetik';
    } else {
      final String tankTypeStr = (_getCellValue(anaSheet, 'G21') + ' ' + _getCellValue(anaSheet, 'G19')).toLowerCase();
      if (tankTypeStr.contains('kuru')) {
        transformerType = 'kuru_tip';
      } else if (tankTypeStr.contains('genleşme') || tankTypeStr.contains('gt')) {
        transformerType = 'gt';
      } else {
        transformerType = 'hermetik';
      }
    }

    // Determine subType ('normal' vs 'kesici')
    final bool hasBreakerSheets = _findSheet(excel, 'ANA SAYFA KESİCİ') != null ||
        _findSheet(excel, 'KESİCİ İZOLASYON') != null ||
        _findSheet(excel, 'KESİCİ KONTAK') != null ||
        _findSheet(excel, 'AÇMA-KAPAMA') != null;

    final String subType = hasBreakerSheets ? 'kesici' : 'normal';

    final Map<String, dynamic> dataJson = <String, dynamic>{
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
      'imported_from_excel': true,
      'source': 'imported',
      'has_breaker': hasBreakerSheets,
      'breaker_included': hasBreakerSheets,
    };

    // Populate dataJson using cell mappings
    final Map<String, Map<String, String>> typeMappings = ExcelCellMapping.cellMappingForType(transformerType);

    typeMappings.forEach((String sheetName, Map<String, String> cellMap) {
      final Sheet? sheet = _findSheet(excel, sheetName);
      if (sheet == null) return;

      cellMap.forEach((String cellRef, String fieldKey) {
        final String val = _getCellValue(sheet, cellRef);
        if (val.isNotEmpty) {
          dataJson[fieldKey] = val;
        }
      });
    });

    // Populate checklist selections
    final Map<String, Map<String, Map<String, String>>> checklistMaps = ExcelCellMapping.checklistPairs;
    final Map<String, Map<String, String>> typeChecklists = checklistMaps[transformerType] ?? checklistMaps['hermetik']!;

    typeChecklists.forEach((String checkKey, Map<String, String> pair) {
      final String evetCell = pair['evet'] ?? '';
      final String hayirCell = pair['hayir'] ?? '';

      if (evetCell.isNotEmpty) {
        final String evetVal = _getCellValue(anaSheet, evetCell);
        if (isMarked(evetVal)) {
          dataJson[checkKey] = true;
        }
      }
      if (hayirCell.isNotEmpty) {
        final String hayirVal = _getCellValue(anaSheet, hayirCell);
        if (isMarked(hayirVal)) {
          dataJson[checkKey] = false;
        }
      }
    });

    // Extract core metadata
    final String customerName = dataJson['customer_name']?.toString().trim() ?? '';
    final String trafoLabel = dataJson['trafo_label']?.toString().trim() ?? '';
    final String reportDateStr = dataJson['report_date']?.toString().trim() ?? '';
    final String testDateStr = dataJson['test_date']?.toString().trim() ?? '';

    final DateTime createdAt = ExcelCellMapping.parseDateTime(testDateStr.isNotEmpty ? testDateStr : reportDateStr);

    String title;
    if (customerName.isNotEmpty && trafoLabel.isNotEmpty) {
      final String displayDate = ExcelCellMapping.formatDateDisplay(testDateStr.isNotEmpty ? testDateStr : reportDateStr, fallback: createdAt);
      title = '$customerName - $trafoLabel - $displayDate';
    } else {
      title = filename.replaceAll(RegExp(r'\.xlsx$', caseSensitive: false), '');
    }

    final String reportId = 'rep_imp_${createdAt.millisecondsSinceEpoch}_${filename.hashCode.abs()}';
    final String? operatorName = dataJson['operator_name']?.toString().trim();
    final String? operatorTitle = dataJson['operator_title']?.toString().trim();

    String? creatorDisplayName;
    if (operatorName != null && operatorName.isNotEmpty) {
      creatorDisplayName = (operatorTitle != null && operatorTitle.isNotEmpty) ? '$operatorName ($operatorTitle)' : operatorName;
    }

    return Report(
      id: reportId,
      title: title,
      reportType: 'bakim',
      subType: subType,
      transformerType: transformerType,
      customerName: customerName,
      trafoLabel: trafoLabel,
      status: 'finalized',
      creatorDisplayName: creatorDisplayName,
      dataJson: dataJson,
      currentStep: 6,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Checks if report matches an existing report record in SQLite
  static bool _checkDuplicate(Report newReport, List<Report> existingReports) {
    final String newTitle = newReport.title.trim().toLowerCase();
    final String newCust = newReport.customerName.trim().toLowerCase();
    final String newLabel = newReport.trafoLabel.trim().toLowerCase();
    final String newSerial = (newReport.dataJson['serial_no'] ?? '').toString().trim().toLowerCase();
    final String newTestDate = ExcelCellMapping.formatDateDisplay(newReport.dataJson['test_date'], fallback: newReport.createdAt);

    for (final Report existing in existingReports) {
      final String exTitle = existing.title.trim().toLowerCase();
      final String exCust = existing.customerName.trim().toLowerCase();
      final String exLabel = existing.trafoLabel.trim().toLowerCase();
      final String exSerial = (existing.dataJson['serial_no'] ?? '').toString().trim().toLowerCase();
      final String exTestDate = ExcelCellMapping.formatDateDisplay(existing.dataJson['test_date'], fallback: existing.createdAt);

      // 1. Exact title match
      if (newTitle.isNotEmpty && newTitle == exTitle) {
        return true;
      }

      // 2. Customer name + Trafo label + Test date match
      if (newCust.isNotEmpty && newLabel.isNotEmpty && newCust == exCust && newLabel == exLabel && newTestDate == exTestDate) {
        return true;
      }

      // 3. Serial number + Customer name + Test date match
      if (newSerial.isNotEmpty && exSerial.isNotEmpty && newSerial == exSerial && newCust == exCust && newTestDate == exTestDate) {
        return true;
      }
    }

    return false;
  }
}
