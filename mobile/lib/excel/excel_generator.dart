import 'dart:convert';
import 'dart:io';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'cell_mapping.dart';
import '../models/report_model.dart';

class ExcelGenerator {
  /// Generates a filled Excel (.xlsx) file on device using official templates
  static Future<File> generateReportExcel({
    required Report report,
    String? signaturePath,
  }) async {
    if (Platform.isWindows) {
      return await _generateReportExcelWindowsCli(
        report: report,
        signaturePath: signaturePath,
      );
    }
    return await _generateReportExcelFallback(
      report: report,
      signaturePath: signaturePath,
    );
  }

  /// Windows implementation: executes local openpyxl CLI (tools/generate_excel.py) via Process.run
  static Future<File> _generateReportExcelWindowsCli({
    required Report report,
    String? signaturePath,
  }) async {
    final Map<String, dynamic> dataDict = <String, dynamic>{};
    if (report.dataJson.isNotEmpty) {
      dataDict.addAll(report.dataJson);
    }

    dataDict['customer_name'] = report.customerName;
    dataDict['trafo_label'] = report.trafoLabel;
    dataDict['address'] = dataDict['address'] ?? dataDict['location'] ?? '';
    dataDict['report_date'] = dataDict['report_date'] ?? ExcelCellMapping.formatDateDisplay(report.createdAt);
    dataDict['test_date'] = dataDict['test_date'] ?? ExcelCellMapping.formatDateDisplay(report.createdAt);
    dataDict['creator_display_name'] = report.creatorDisplayName ??
        dataDict['operator_title'] ??
        dataDict['operator_name'] ??
        '';

    final String transformerType = report.transformerType.toLowerCase().trim();
    if (transformerType == 'hermetik') {
      dataDict['tank_mark_hermetik'] = 'ü';
    } else if (transformerType == 'gt') {
      dataDict['tank_mark_gt'] = 'ü';
    } else if (transformerType == 'kuru_tip') {
      dataDict['tank_mark_kuru'] = 'ü';
    }

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory reportsDir = Directory('${appDocDir.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final String dateStr = ExcelCellMapping.formatDateDisplay(dataDict['test_date'] ?? report.createdAt);
    final String customerStr = report.customerName.isEmpty ? 'Musteri' : report.customerName;
    final String labelStr = report.trafoLabel.isEmpty ? 'Trafo' : report.trafoLabel;

    final String rawFilename = '$customerStr - $labelStr - $dateStr.xlsx';
    final String cleanFilename = ExcelCellMapping.sanitizeFilename(rawFilename);
    final String outputPath = '${reportsDir.path}/$cleanFilename';

    // Temporary JSON file for CLI argument
    final File tempJsonFile = File('${reportsDir.path}/temp_report_${report.id}.json');
    await tempJsonFile.writeAsString(jsonEncode(dataDict));

    final String? scriptPath = _findPythonScriptPath();
    if (scriptPath == null) {
      if (await tempJsonFile.exists()) {
        await tempJsonFile.delete();
      }
      throw Exception(
        'Excel şablon üretim aracı bulunamadı (tools/generate_excel.py).\n'
        'Lütfen proje dizininde tools/generate_excel.py dosyasının bulunduğundan emin olun.',
      );
    }

    final List<String> pythonExecutables = <String>['python', 'py', 'python3'];
    ProcessResult? result;
    String? lastError;

    for (final String pyExe in pythonExecutables) {
      final List<String> cliArgs = <String>[
        scriptPath,
        '--json',
        tempJsonFile.path,
        '--template-type',
        transformerType,
        '--output',
        outputPath,
      ];

      final String? effectiveSigPath = signaturePath ??
          dataDict['signature_path']?.toString() ??
          dataDict['signature']?.toString();

      if (effectiveSigPath != null && effectiveSigPath.isNotEmpty && File(effectiveSigPath).existsSync()) {
        cliArgs.addAll(<String>['--signature', effectiveSigPath]);
      }

      dynamic photoBefore = dataDict['photo_before'];
      if (photoBefore == null && dataDict['photos'] is Map) {
        photoBefore = dataDict['photos']['photo_before'];
      }
      if (photoBefore is String && photoBefore.isNotEmpty && File(photoBefore).existsSync()) {
        cliArgs.addAll(<String>['--photo-before', photoBefore]);
      }

      dynamic photoAfter = dataDict['photo_after'];
      if (photoAfter == null && dataDict['photos'] is Map) {
        photoAfter = dataDict['photos']['photo_after'];
      }
      if (photoAfter is String && photoAfter.isNotEmpty && File(photoAfter).existsSync()) {
        cliArgs.addAll(<String>['--photo-after', photoAfter]);
      }

      dynamic photoLabel = dataDict['photo_label'];
      if (photoLabel == null && dataDict['photos'] is Map) {
        photoLabel = dataDict['photos']['photo_label'];
      }
      if (photoLabel is String && photoLabel.isNotEmpty && File(photoLabel).existsSync()) {
        cliArgs.addAll(<String>['--photo-label', photoLabel]);
      }

      try {
        result = await Process.run(pyExe, cliArgs);
        if (result.exitCode == 0 && result.stdout.toString().contains('OUTPUT_OK:')) {
          if (await tempJsonFile.exists()) {
            await tempJsonFile.delete();
          }
          final File outputFile = File(outputPath);
          if (await outputFile.exists()) {
            return outputFile;
          }
        } else {
          lastError = result.stderr.toString().trim();
          if (lastError.isEmpty) {
            lastError = result.stdout.toString().trim();
          }
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    if (await tempJsonFile.exists()) {
      await tempJsonFile.delete();
    }

    throw Exception(
      'Excel raporu üretilemedi.\n'
      'Lütfen bilgisayarınızda Python ve "openpyxl" kütüphanesinin yüklü olduğundan emin olun.\n'
      'Hata Detayı: $lastError',
    );
  }

  static String? _findPythonScriptPath() {
    final String? envToolsDir = Platform.environment['TRAFO_TOOLS_DIR'];
    if (envToolsDir != null && envToolsDir.isNotEmpty) {
      final File envScript = File('$envToolsDir/generate_excel.py');
      if (envScript.existsSync()) return envScript.path;
    }

    final String cwd = Directory.current.path;
    final List<String> candidatePaths = <String>[
      '$cwd/tools/generate_excel.py',
      '$cwd/../tools/generate_excel.py',
      '$cwd/../../tools/generate_excel.py',
      'tools/generate_excel.py',
      'C:/Users/User/OneDrive/Desktop/BTS_Elektrik/tools/generate_excel.py',
    ];

    for (final String path in candidatePaths) {
      final File f = File(path);
      if (f.existsSync()) {
        return f.absolute.path;
      }
    }

    return null;
  }

  /// Fallback implementation for mobile/non-Windows platforms using excel_plus
  static Future<File> _generateReportExcelFallback({
    required Report report,
    String? signaturePath,
  }) async {
    final String transformerType = report.transformerType.toLowerCase().trim();
    final String assetPath = ExcelCellMapping.templateAssetPaths[transformerType] ??
        ExcelCellMapping.templateAssetPaths['hermetik']!;

    final Map<String, Map<String, String>> typeMapping =
        ExcelCellMapping.cellMappingForType(transformerType);

    final ByteData data = await rootBundle.load(assetPath);
    final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    final Excel excel = Excel.decodeBytes(bytes);

    final Map<String, dynamic> dataDict = <String, dynamic>{};
    if (report.dataJson.isNotEmpty) {
      dataDict.addAll(report.dataJson);
    }

    dataDict['customer_name'] = report.customerName;
    dataDict['trafo_label'] = report.trafoLabel;
    dataDict['address'] = dataDict['address'] ?? dataDict['location'] ?? '';
    dataDict['report_date'] = dataDict['report_date'] ?? ExcelCellMapping.formatDateDisplay(report.createdAt);
    dataDict['test_date'] = dataDict['test_date'] ?? ExcelCellMapping.formatDateDisplay(report.createdAt);
    dataDict['creator_display_name'] = report.creatorDisplayName ??
        dataDict['operator_title'] ??
        dataDict['operator_name'] ??
        '';

    if (transformerType == 'hermetik') {
      dataDict['tank_mark_hermetik'] = 'ü';
    } else if (transformerType == 'gt') {
      dataDict['tank_mark_gt'] = 'ü';
    } else if (transformerType == 'kuru_tip') {
      dataDict['tank_mark_kuru'] = 'ü';
    }

    final Map<dynamic, dynamic> wr = dataDict['winding_resistance'] as Map? ?? <dynamic, dynamic>{};
    dataDict['og_rab'] ??= wr['r_phase'];
    dataDict['og_rbc'] ??= wr['s_phase'];
    dataDict['og_rca'] ??= wr['t_phase'];

    final Map<dynamic, dynamic> gr = dataDict['grounding'] as Map? ?? <dynamic, dynamic>{};
    dataDict['ground_r_trafo_body'] ??= dataDict['ground_trafo_body'] ?? gr['value'];

    final Map<dynamic, dynamic> ttr = dataDict['ttr'] as Map? ?? <dynamic, dynamic>{};
    dataDict['ttr_tap1_a'] ??= ttr['r_phase'];
    dataDict['ttr_tap1_b'] ??= ttr['s_phase'];
    dataDict['ttr_tap1_c'] ??= ttr['t_phase'];

    final Map<dynamic, dynamic> br = dataDict['breaker'] as Map? ?? <dynamic, dynamic>{};
    dataDict['breaker_contact_r'] ??= br['contact_resistance'];
    dataDict['breaker_timing_open'] ??= br['open_time'];
    dataDict['breaker_timing_close'] ??= br['close_time'];
    dataDict['breaker_phase_diff'] ??= br['phase_diff'];

    for (final String targetSheetName in typeMapping.keys) {
      final String normTarget = ExcelCellMapping.normalizeSheetName(targetSheetName);

      Sheet? sheet;
      for (final String sName in excel.tables.keys) {
        if (sName == targetSheetName || ExcelCellMapping.normalizeSheetName(sName) == normTarget) {
          sheet = excel.tables[sName];
          break;
        }
      }

      if (sheet == null) continue;

      final Map<String, String> cellMap = typeMapping[targetSheetName]!;

      cellMap.forEach((String cellRef, String fieldKey) {
        if (fieldKey.startsWith('TODO_VERIFY')) return;

        if (!dataDict.containsKey(fieldKey)) return;
        final dynamic rawVal = dataDict[fieldKey];
        if (rawVal == null) return;

        final CellIndex cellIndex = CellIndex.indexByString(cellRef);

        final Data? existingCell = sheet!.cell(cellIndex);
        if (existingCell != null && existingCell.value != null) {
          final String existingStr = existingCell.value.toString().trim();
          if (existingStr.startsWith('=')) {
            return;
          }
        }

        if (fieldKey == 'report_date' || fieldKey == 'test_date') {
          final double? serial = ExcelCellMapping.dateToExcelSerial(rawVal);
          if (serial != null) {
            sheet.updateCell(cellIndex, DoubleCellValue(serial));
          } else {
            sheet.updateCell(cellIndex, TextCellValue(rawVal.toString()));
          }
        } else if (fieldKey.startsWith('checklist_') || fieldKey.startsWith('tank_mark_')) {
          if (rawVal == true || rawVal.toString().trim() == 'ü') {
            sheet.updateCell(cellIndex, TextCellValue('ü'));
          }
        } else if (rawVal is int) {
          sheet.updateCell(cellIndex, IntCellValue(rawVal));
        } else if (rawVal is double) {
          sheet.updateCell(cellIndex, DoubleCellValue(rawVal));
        } else {
          final String strVal = rawVal.toString();
          if (strVal.startsWith('=')) {
            final String sanitized = ExcelCellMapping.sanitizeFormula(strVal);
            sheet.updateCell(cellIndex, FormulaCellValue(sanitized));
          } else {
            final String cleanNumStr = strVal.replaceAll(',', '.');
            final double? dblVal = double.tryParse(cleanNumStr);
            if (dblVal != null && !strVal.startsWith('0')) {
              sheet.updateCell(cellIndex, DoubleCellValue(dblVal));
            } else {
              sheet.updateCell(cellIndex, TextCellValue(strVal));
            }
          }
        }
      });
    }

    final Sheet? kapakSheet = excel.tables['KAPAK SAYFASI'];
    if (kapakSheet != null) {
      final String? effectiveSigPath = signaturePath ??
          dataDict['signature_path']?.toString() ??
          dataDict['signature']?.toString();

      if (effectiveSigPath != null && effectiveSigPath.isNotEmpty) {
        final File sigFile = File(effectiveSigPath);
        if (sigFile.existsSync()) {
          try {
            final List<int> sigBytes = await sigFile.readAsBytes();
            kapakSheet.insertImage(
              sigBytes,
              anchor: CellIndex.indexByString('G56'),
              width: 140,
              height: 50,
            );
          } catch (_) {}
        }
      }

      final List<String> photoSlotCells = <String>['A35', 'F35', 'A43', 'F43'];
      final List<String> photoKeys = <String>[
        'photo_before',
        'photo_after',
        'photo_label',
        'photo_extra',
      ];

      int photoIndex = 0;
      for (final String photoKey in photoKeys) {
        if (photoIndex >= photoSlotCells.length) break;

        dynamic pathVal = dataDict[photoKey];
        if (pathVal == null && dataDict['photos'] is Map) {
          pathVal = dataDict['photos'][photoKey];
        }

        if (pathVal is String && pathVal.isNotEmpty) {
          final File photoFile = File(pathVal);
          if (photoFile.existsSync()) {
            try {
              final List<int> photoBytes = await photoFile.readAsBytes();
              final String anchorCell = photoSlotCells[photoIndex];
              kapakSheet.insertImage(
                photoBytes,
                anchor: CellIndex.indexByString(anchorCell),
                width: 180,
                height: 120,
              );
              photoIndex++;
            } catch (_) {}
          }
        }
      }
    }

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory reportsDir = Directory('${appDocDir.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final String dateStr = ExcelCellMapping.formatDateDisplay(dataDict['test_date'] ?? report.createdAt);
    final String customerStr = report.customerName.isEmpty ? 'Musteri' : report.customerName;
    final String labelStr = report.trafoLabel.isEmpty ? 'Trafo' : report.trafoLabel;

    final String rawFilename = '$customerStr - $labelStr - $dateStr.xlsx';
    final String cleanFilename = ExcelCellMapping.sanitizeFilename(rawFilename);
    final String outputPath = '${reportsDir.path}/$cleanFilename';

    final List<int>? fileBytes = excel.save();
    if (fileBytes == null) {
      throw Exception('Excel dosyası kaydedilemedi.');
    }

    final File outputFile = File(outputPath);
    await outputFile.writeAsBytes(fileBytes);
    return outputFile;
  }
}
