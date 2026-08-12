import 'package:flutter_test/flutter_test.dart';
import 'package:excel_plus/excel_plus.dart';

void main() {
  test('excel_plus column width and number format verification test', () {
    final Excel excel = Excel.createExcel();
    final Sheet kapakSheet = excel['KAPAK SAYFASI'];
    kapakSheet.setColumnWidth(3, 14.0);

    final CellIndex d12Index = CellIndex.indexByString('D12');
    final NumFormat dateFmt = NumFormat.custom(formatCode: 'dd.mm.yyyy');
    kapakSheet.updateCell(
      d12Index,
      DateCellValue(year: 2026, month: 8, day: 3),
      cellStyle: CellStyle().copyWith(
        numberFormat: dateFmt,
      ),
    );

    final Sheet izoSheet = excel['İZOLASYON '];
    izoSheet.setColumnWidth(7, 13.0);
    final CellIndex h18Index = CellIndex.indexByString('H18');
    final NumFormat numFmt = NumFormat.custom(formatCode: '0.00');
    izoSheet.updateCell(
      h18Index,
      DoubleCellValue(2500.87),
      cellStyle: CellStyle().copyWith(
        numberFormat: numFmt,
      ),
    );

    expect(kapakSheet.getColumnWidth(3), equals(14.0));
    expect(kapakSheet.cell(d12Index).cellStyle?.numberFormat.formatCode, equals(dateFmt.formatCode));

    expect(izoSheet.getColumnWidth(7), equals(13.0));
    expect(izoSheet.cell(h18Index).cellStyle?.numberFormat.formatCode, equals(numFmt.formatCode));
  });
}
