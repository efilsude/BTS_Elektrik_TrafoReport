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

    // Load template bytes from Flutter bundled assets
    final ByteData data = await rootBundle.load(assetPath);
    final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    final Excel excel = Excel.decodeBytes(bytes);

    // Flatten values map from Report attributes and dataJson
    final Map<String, dynamic> dataDict = <String, dynamic>{};
    dataDict.addAll(report.dataJson);
    dataDict['customer_name'] = report.customerName;
    dataDict['trafo_label'] = report.trafoLabel;
    dataDict['report_date'] = report.dataJson['report_date'] ?? report.createdAt.toIso8601String();
    dataDict['test_date'] = report.dataJson['test_date'] ?? report.createdAt.toIso8601String();
    dataDict['creator_display_name'] = report.creatorDisplayName ?? '';

    // Iterate through mapped sheets and cells
    for (final String sheetName in ExcelCellMapping.cellMapping.keys) {
      if (excel.tables.containsKey(sheetName)) {
        final Sheet sheet = excel.tables[sheetName]!;
        final Map<String, String> cellMap = ExcelCellMapping.cellMapping[sheetName]!;

        cellMap.forEach((String cellRef, String fieldKey) {
          if (dataDict.containsKey(fieldKey)) {
            final dynamic val = dataDict[fieldKey];
            if (val != null) {
              final CellIndex cellIndex = CellIndex.indexByString(cellRef);

              if (fieldKey == 'report_date' || fieldKey == 'test_date') {
                final double? serial = ExcelCellMapping.dateToExcelSerial(val);
                if (serial != null) {
                  sheet.updateCell(cellIndex, DoubleCellValue(serial));
                } else {
                  sheet.updateCell(cellIndex, TextCellValue(val.toString()));
                }
              } else {
                // Numeric, formula, or string cell value
                if (val is int) {
                  sheet.updateCell(cellIndex, IntCellValue(val));
                } else if (val is double) {
                  sheet.updateCell(cellIndex, DoubleCellValue(val));
                } else {
                  final String strVal = val.toString();
                  if (strVal.startsWith('=')) {
                    // Formula cell: sanitize Turkish names, ';' separators, and decimal commas
                    final String sanitizedFormula = ExcelCellMapping.sanitizeFormula(strVal);
                    sheet.updateCell(cellIndex, FormulaCellValue(sanitizedFormula));
                  } else {
                    // Parse numeric string safely using dot decimal separator
                    final String cleanNumStr = strVal.replaceAll(',', '.');
                    final double? dblVal = double.tryParse(cleanNumStr);
                    if (dblVal != null && !strVal.startsWith('0')) {
                      sheet.updateCell(cellIndex, DoubleCellValue(dblVal));
                    } else {
                      sheet.updateCell(cellIndex, TextCellValue(strVal));
                    }
                  }
                }
              }
            }
          }
        });
      }
    }

    // Prepare output directory and filename: {Customer} - {TrafoLabel} - {DD.MM.YYYY}.xlsx
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory reportsDir = Directory('${appDocDir.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final String dateStr = ExcelCellMapping.formatDateDisplay(report.dataJson['test_date'] ?? report.createdAt);
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
