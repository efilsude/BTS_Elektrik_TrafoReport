import 'dart:convert';
import 'dart:io';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path/path.dart' as p;
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
    dataDict['report_date'] = ExcelCellMapping.formatDateDisplay(dataDict['report_date'], fallback: report.createdAt);
    dataDict['test_date'] = ExcelCellMapping.formatDateDisplay(dataDict['test_date'], fallback: report.createdAt);
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
    final Directory reportsDir = Directory(p.join(appDocDir.path, 'reports'));
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final String dateStr = ExcelCellMapping.formatDateDisplay(dataDict['test_date'], fallback: report.createdAt);
    final String customerStr = report.customerName.isEmpty ? 'Musteri' : report.customerName;
    final String labelStr = report.trafoLabel.isEmpty ? 'Trafo' : report.trafoLabel;

    final String rawFilename = '$customerStr - $labelStr - $dateStr.xlsx';
    final String cleanFilename = ExcelCellMapping.sanitizeFilename(rawFilename);
    final String outputPath = p.join(reportsDir.path, cleanFilename);

    // Temporary JSON file for CLI argument
    final File tempJsonFile = File(p.join(reportsDir.path, 'temp_report_${report.id}.json'));
    await tempJsonFile.writeAsString(jsonEncode(dataDict));

    final String? scriptPath = _findPythonScriptPath();
    final String? templatePath = _findTemplatePath(transformerType);

    debugPrint('[ExcelGenerator] Script Path: $scriptPath');
    debugPrint('[ExcelGenerator] Template Path: $templatePath');

    if (scriptPath == null) {
      if (await tempJsonFile.exists()) {
        await tempJsonFile.delete();
      }
      throw Exception(
        'Excel şablon üretim aracı bulunamadı (generate_excel.py).\n'
        'Lütfen TRAFO_TOOLS_DIR ortam değişkenini ayarlayın veya uygulamanın yanındaki "tools" klasörünü kontrol edin.',
      );
    }

    // Candidate python execution commands
    final List<List<String>> pythonCommands = <List<String>>[
      <String>['python'],
      <String>['py', '-3'],
      <String>['py'],
      <String>['python3'],
    ];

    // Check known Windows installation paths as fallbacks
    final List<String> knownPythonPaths = <String>[
      r'C:\Python314\python.exe',
      r'C:\Python313\python.exe',
      r'C:\Python312\python.exe',
      r'C:\Python311\python.exe',
      r'C:\Python310\python.exe',
    ];

    final String? localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.isNotEmpty) {
      knownPythonPaths.add(p.join(localAppData, 'Programs', 'Python', 'Python314', 'python.exe'));
      knownPythonPaths.add(p.join(localAppData, 'Programs', 'Python', 'Python313', 'python.exe'));
      knownPythonPaths.add(p.join(localAppData, 'Programs', 'Python', 'Python312', 'python.exe'));
      knownPythonPaths.add(p.join(localAppData, 'Programs', 'Python', 'Python311', 'python.exe'));
      knownPythonPaths.add(p.join(localAppData, 'Programs', 'Python', 'Python310', 'python.exe'));
    }

    for (final String path in knownPythonPaths) {
      if (File(path).existsSync()) {
        pythonCommands.add(<String>[path]);
      }
    }

    String? lastErrorMsg;

    for (final List<String> cmd in pythonCommands) {
      final String exeName = cmd.first;
      final List<String> extraArgs = cmd.sublist(1);

      final List<String> cliArgs = <String>[
        ...extraArgs,
        scriptPath,
        '--json',
        tempJsonFile.path,
        '--template-type',
        transformerType,
        '--output',
        outputPath,
      ];

      if (templatePath != null) {
        cliArgs.addAll(<String>['--template', templatePath]);
      }

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

      debugPrint('[ExcelGenerator] Deneniyor: $exeName ${cliArgs.join(" ")}');

      try {
        final ProcessResult result = await Process.run(exeName, cliArgs);
        debugPrint('[ExcelGenerator] exitCode: ${result.exitCode}');
        debugPrint('[ExcelGenerator] stdout: ${result.stdout}');
        debugPrint('[ExcelGenerator] stderr: ${result.stderr}');

        if (result.exitCode == 0 && result.stdout.toString().contains('OUTPUT_OK:')) {
          if (await tempJsonFile.exists()) {
            await tempJsonFile.delete();
          }
          final File outputFile = File(outputPath);
          if (await outputFile.exists()) {
            return outputFile;
          }
        } else {
          final String stderrStr = result.stderr.toString().trim();
          final String stdoutStr = result.stdout.toString().trim();
          lastErrorMsg = stderrStr.isNotEmpty ? stderrStr : stdoutStr;
        }
      } catch (e) {
        debugPrint('[ExcelGenerator] $exeName çalıştırma hatası: $e');
        lastErrorMsg = e.toString();
      }
    }

    if (await tempJsonFile.exists()) {
      await tempJsonFile.delete();
    }

    final String cleanErrorStr = (lastErrorMsg != null && lastErrorMsg.isNotEmpty)
        ? lastErrorMsg
        : 'Python veya openpyxl kütüphanesi çalıştırılamadı.';

    throw Exception(
      'Excel raporu üretilemedi.\n'
      'Script Yolu: $scriptPath\n'
      'Hata Detayı: $cleanErrorStr\n\n'
      'Lütfen Python ve "openpyxl" kütüphanesinin yüklü olduğundan ve PATH ortam değişkenine eklendiğinden emin olun.',
    );
  }

  static String? _findPythonScriptPath() {
    final String? envToolsDir = Platform.environment['TRAFO_TOOLS_DIR'];
    if (envToolsDir != null && envToolsDir.isNotEmpty) {
      final File envScript = File(p.join(envToolsDir, 'generate_excel.py'));
      if (envScript.existsSync()) return envScript.absolute.path;
    }

    final String? envRepoRoot = Platform.environment['TRAFO_REPO_ROOT'];
    if (envRepoRoot != null && envRepoRoot.isNotEmpty) {
      final File envRepoScript = File(p.join(envRepoRoot, 'tools', 'generate_excel.py'));
      if (envRepoScript.existsSync()) return envRepoScript.absolute.path;
    }

    try {
      final Directory exeDir = File(Platform.resolvedExecutable).parent;
      final List<String> exeCandidates = <String>[
        p.join(exeDir.path, 'tools', 'generate_excel.py'),
        p.join(exeDir.path, 'generate_excel.py'),
        p.join(exeDir.path, '..', 'tools', 'generate_excel.py'),
        p.join(exeDir.path, '..', '..', 'tools', 'generate_excel.py'),
        p.join(exeDir.path, '..', '..', '..', 'tools', 'generate_excel.py'),
      ];
      for (final String path in exeCandidates) {
        final File f = File(path);
        if (f.existsSync()) return f.absolute.path;
      }
    } catch (_) {}

    try {
      final String cwd = Directory.current.path;
      final List<String> cwdCandidates = <String>[
        p.join(cwd, 'tools', 'generate_excel.py'),
        p.join(cwd, '..', 'tools', 'generate_excel.py'),
        p.join(cwd, '..', '..', 'tools', 'generate_excel.py'),
        'tools/generate_excel.py',
      ];
      for (final String path in cwdCandidates) {
        final File f = File(path);
        if (f.existsSync()) return f.absolute.path;
      }
    } catch (_) {}

    const String defaultFallback = 'C:/Users/User/OneDrive/Desktop/BTS_Elektrik/tools/generate_excel.py';
    if (File(defaultFallback).existsSync()) {
      return File(defaultFallback).absolute.path;
    }

    return null;
  }

  static String? _findTemplatePath(String transformerType) {
    final String normType = transformerType.toLowerCase().trim();
    String filename;
    if (normType.contains('kuru')) {
      filename = 'KURU TİP HİLMİ.xlsx';
    } else if (normType.contains('gt') || normType.contains('tank')) {
      filename = 'TR BAKIM RAPORU GT HİLMİ.xlsx';
    } else {
      filename = 'HERMETİK TRAFO BAKIM RAPORU HİLMİ.xlsx';
    }

    final List<String> dirsToSearch = <String>[];

    final String? envRepoRoot = Platform.environment['TRAFO_REPO_ROOT'];
    if (envRepoRoot != null && envRepoRoot.isNotEmpty) {
      dirsToSearch.add(p.join(envRepoRoot, 'backend', 'templates'));
    }

    final String? envToolsDir = Platform.environment['TRAFO_TOOLS_DIR'];
    if (envToolsDir != null && envToolsDir.isNotEmpty) {
      dirsToSearch.add(p.join(envToolsDir, '..', 'backend', 'templates'));
      dirsToSearch.add(p.join(envToolsDir, 'templates'));
    }

    try {
      final Directory exeDir = File(Platform.resolvedExecutable).parent;
      dirsToSearch.addAll(<String>[
        p.join(exeDir.path, 'templates'),
        p.join(exeDir.path, 'backend', 'templates'),
        p.join(exeDir.path, '..', 'backend', 'templates'),
        p.join(exeDir.path, '..', '..', 'backend', 'templates'),
      ]);
    } catch (_) {}

    final String cwd = Directory.current.path;
    dirsToSearch.addAll(<String>[
      p.join(cwd, 'backend', 'templates'),
      p.join(cwd, 'templates'),
      p.join(cwd, '..', 'backend', 'templates'),
      'C:/Users/User/OneDrive/Desktop/BTS_Elektrik/backend/templates',
    ]);

    for (final String dir in dirsToSearch) {
      final File f = File(p.join(dir, filename));
      if (f.existsSync()) return f.absolute.path;
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
    dataDict['report_date'] = ExcelCellMapping.formatDateDisplay(dataDict['report_date'], fallback: report.createdAt);
    dataDict['test_date'] = ExcelCellMapping.formatDateDisplay(dataDict['test_date'], fallback: report.createdAt);
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

    final String? effectiveSigPath = signaturePath ??
        dataDict['signature_path']?.toString() ??
        dataDict['signature']?.toString();

    if (effectiveSigPath != null && effectiveSigPath.isNotEmpty) {
      final File sigFile = File(effectiveSigPath);
      if (sigFile.existsSync()) {
        final Map<String, String> sigAnchors =
            ExcelCellMapping.sheetSignatureAnchors[transformerType] ??
                ExcelCellMapping.sheetSignatureAnchors['hermetik']!;

        try {
          final List<int> sigBytes = await sigFile.readAsBytes();
          for (final String sName in excel.tables.keys) {
            String? targetCell;
            for (final String keySheet in sigAnchors.keys) {
              if (keySheet.trim() == sName.trim()) {
                targetCell = sigAnchors[keySheet];
                break;
              }
            }
            if (targetCell != null) {
              final Sheet? targetSheet = excel.tables[sName];
              if (targetSheet != null) {
                targetSheet.insertImage(
                  sigBytes,
                  anchor: CellIndex.indexByString(targetCell),
                  width: 140,
                  height: 50,
                );
              }
            }
          }
        } catch (_) {}
      }
    }

    final Sheet? kapakSheet = excel.tables['KAPAK SAYFASI'];
    if (kapakSheet != null) {

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

    final String dateStr = ExcelCellMapping.formatDateDisplay(dataDict['test_date'], fallback: report.createdAt);
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
