import 'package:flutter_test/flutter_test.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:trafo_report_mobile/excel/excel_generator.dart';

void main() {
  test('ExcelGenerator.applyFormatAndColumnWidthFixes modifies column widths and cell formats', () {
    final Excel excel = Excel.createExcel();

    // 1. Setup KAPAK SAYFASI sheet with unformatted D12 cell and initial width
    final Sheet kapakSheet = excel['KAPAK SAYFASI'];
    kapakSheet.setColumnWidth(3, 8.43); // Initial narrow width
    final CellIndex d12Index = CellIndex.indexByString('D12');
    kapakSheet.updateCell(
      d12Index,
      DateCellValue(year: 2026, month: 8, day: 3),
      cellStyle: const CellStyle(), // Initial default format
    );

    // 2. Setup İZOLASYON sheet with unformatted H18 cell and initial narrow width
    final Sheet izoSheet = excel['İZOLASYON '];
    izoSheet.setColumnWidth(7, 6.57); // Initial narrow width
    final CellIndex h18Index = CellIndex.indexByString('H18');
    izoSheet.updateCell(
      h18Index,
      DoubleCellValue(2500.87),
      cellStyle: const CellStyle(), // Initial General format
    );

    // 3. Setup AG SARGI sheet with unformatted G24 cell and initial width
    final Sheet agSheet = excel['AG SARGI'];
    agSheet.setColumnWidth(6, 13.0); // Initial width
    final CellIndex g24Index = CellIndex.indexByString('G24');
    agSheet.updateCell(
      g24Index,
      DoubleCellValue(24.123456),
      cellStyle: const CellStyle(), // Initial General format
    );

    // Verify BEFORE calling fix: widths and formats are unadjusted
    expect(kapakSheet.getColumnWidth(3), equals(8.43));
    expect(izoSheet.getColumnWidth(7), equals(6.57));
    expect(agSheet.getColumnWidth(6), equals(13.0));
    expect(kapakSheet.cell(d12Index).cellStyle?.numberFormat.formatCode, isNot(equals('dd.mm.yyyy')));

    // CALL THE REAL APPLICATION FUNCTION
    ExcelGenerator.applyFormatAndColumnWidthFixes(excel);

    // Verify AFTER calling fix: widths and formats ARE correctly adjusted
    expect(kapakSheet.getColumnWidth(3), equals(14.0));
    expect(kapakSheet.cell(d12Index).cellStyle?.numberFormat.formatCode, equals('dd.mm.yyyy'));

    expect(izoSheet.getColumnWidth(7), equals(13.0));
    expect(izoSheet.cell(h18Index).cellStyle?.numberFormat.formatCode, equals('0.00'));

    expect(agSheet.getColumnWidth(6), equals(15.0));
    expect(agSheet.cell(g24Index).cellStyle?.numberFormat.formatCode, equals('0.00'));
  });
}
