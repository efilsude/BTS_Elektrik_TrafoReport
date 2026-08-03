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
  }) async {
    final String transformerType = report.transformerType.toLowerCase().trim();
    final String assetPath = ExcelCellMapping.templateAssetPaths[transformerType] ??
        ExcelCellMapping.templateAssetPaths['hermetik']!;

    // Select type-based cell mapping matrix (hermetik | kuru_tip | gt)
    final Map<String, Map<String, String>> typeMapping =
        ExcelCellMapping.cellMappingForType(transformerType);

    // Load template bytes from Flutter bundled assets
    final ByteData data = await rootBundle.load(assetPath);
    final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    final Excel excel = Excel.decodeBytes(bytes);

    // Flatten values map from Report attributes and dataJson
    final Map<String, dynamic> dataDict = <String, dynamic>{};
    if (report.dataJson.isNotEmpty) {
      dataDict.addAll(report.dataJson);
    }

    // Mandatory overrides from Report properties
    dataDict['customer_name'] = report.customerName;
    dataDict['trafo_label'] = report.trafoLabel;

    // Address & Location alias
    dataDict['address'] = dataDict['address'] ?? dataDict['location'] ?? '';

    // Dates
    dataDict['report_date'] = dataDict['report_date'] ?? ExcelCellMapping.formatDateDisplay(report.createdAt);
    dataDict['test_date'] = dataDict['test_date'] ?? ExcelCellMapping.formatDateDisplay(report.createdAt);

    // Personnel display name
    dataDict['creator_display_name'] = report.creatorDisplayName ??
        dataDict['operator_title'] ??
        dataDict['operator_name'] ??
        '';

    // Tank mark checkmark auto-set ('ü')
    if (transformerType == 'hermetik') {
      dataDict['tank_mark_hermetik'] = 'ü';
    } else if (transformerType == 'gt') {
      dataDict['tank_mark_gt'] = 'ü';
    } else if (transformerType == 'kuru_tip') {
      dataDict['tank_mark_kuru'] = 'ü';
    }

    // Legacy nested aliases (safety fallback)
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

    // Iterate through type-specific mapped sheets and cells
    for (final String targetSheetName in typeMapping.keys) {
      final String normTarget = ExcelCellMapping.normalizeSheetName(targetSheetName);

      // Match sheet in workbook trying exact name first, then trimmed name (e.g. 'İZOLASYON ')
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
        // Skip TODO_VERIFY sızıntı entries
        if (fieldKey.startsWith('TODO_VERIFY')) return;

        if (!dataDict.containsKey(fieldKey)) return;
        final dynamic rawVal = dataDict[fieldKey];
        if (rawVal == null) return;

        final CellIndex cellIndex = CellIndex.indexByString(cellRef);

        // Formula protection: preserve existing template formulas (=...)
        final Data? existingCell = sheet!.cell(cellIndex);
        if (existingCell != null && existingCell.value != null) {
          final String existingStr = existingCell.value.toString().trim();
          if (existingStr.startsWith('=')) {
            return; // Skip overwriting template formula cell
          }
        }

        // Value writing logic
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

    // Prepare output directory and filename: {Customer} - {TrafoLabel} - {DD.MM.YYYY}.xlsx
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
