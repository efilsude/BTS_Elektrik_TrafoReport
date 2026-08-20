import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trafo_report_mobile/database/database_helper.dart';
import 'package:trafo_report_mobile/models/report_model.dart';
import 'package:trafo_report_mobile/services/excel_import_service.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  MockPathProviderPlatform(this.tempPath);

  @override
  Future<String?> getApplicationSupportPath() async => tempPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

List<int> createMockTrafoExcel({
  required String customerName,
  required String trafoLabel,
  required String reportDate,
  required String testDate,
  bool isValidFormat = true,
  bool isKuru = false,
}) {
  final Excel excel = Excel.createExcel();
  if (isValidFormat) {
    excel.rename('Sheet1', 'KAPAK SAYFASI');
    final Sheet kapak = excel['KAPAK SAYFASI'];
    kapak.cell(CellIndex.indexByString('D9')).value = TextCellValue(customerName);
    kapak.cell(CellIndex.indexByString('D10')).value = TextCellValue(trafoLabel);
    kapak.cell(CellIndex.indexByString('D12')).value = TextCellValue(reportDate);
    kapak.cell(CellIndex.indexByString('D14')).value = TextCellValue(testDate);

    final Sheet ana = excel['ANA SAYFA'];
    ana.cell(CellIndex.indexByString('G11')).value = TextCellValue('ABB');
    ana.cell(CellIndex.indexByString('G13')).value = TextCellValue('1000');
    ana.cell(CellIndex.indexByString('G15')).value = TextCellValue('34.5/0.4');
    ana.cell(CellIndex.indexByString('O15')).value = TextCellValue('SN123456');

    if (isKuru) {
      ana.cell(CellIndex.indexByString('U21')).value = TextCellValue('ü');
    } else {
      ana.cell(CellIndex.indexByString('I21')).value = TextCellValue('ü');
    }
  } else {
    excel.rename('Sheet1', 'FINANS_RAPORU');
  }

  final List<int>? bytes = excel.encode();
  return bytes ?? <int>[];
}

File createZipWithFiles(Directory tempDir, String zipName, Map<String, List<int>> files) {
  final Archive archive = Archive();
  files.forEach((String filePath, List<int> bytes) {
    archive.addFile(ArchiveFile(filePath, bytes.length, bytes));
  });
  final List<int>? zipBytes = ZipEncoder().encode(archive);
  final File zipFile = File('${tempDir.path}/$zipName');
  zipFile.writeAsBytesSync(zipBytes!);
  return zipFile;
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('trafo_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir.path);
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('ExcelImportService Unit & Integration Tests', () {
    test('1. Valid ZIP + 1 Excel imports successfully into SQLite as finalized', () async {
      final List<int> excelBytes = createMockTrafoExcel(
        customerName: 'BTS Fabrika',
        trafoLabel: 'TR-1',
        reportDate: '15.08.2026',
        testDate: '15.08.2026',
      );

      final File zipFile = createZipWithFiles(tempDir, 'test_single.zip', <String, List<int>>{
        'rapor1.xlsx': excelBytes,
      });

      final ExcelImportResult res = await ExcelImportService.importReportsFromZip(zipFile);

      expect(res.totalFiles, equals(1));
      expect(res.successCount, equals(1));
      expect(res.failureCount, equals(0));
      expect(res.skippedCount, equals(0));

      final List<Report> reports = await DatabaseHelper.instance.getReports(statusFilter: 'finalized');
      expect(reports.any((Report r) => r.customerName == 'BTS Fabrika' && r.trafoLabel == 'TR-1'), isTrue);
    });

    test('2. Empty ZIP or ZIP with no .xlsx files throws clear Turkish exception', () async {
      final File zipFile = createZipWithFiles(tempDir, 'test_empty.zip', <String, List<int>>{
        'readme.txt': <int>[65, 66, 67],
        'image.png': <int>[1, 2, 3],
      });

      expect(
        () async => await ExcelImportService.importReportsFromZip(zipFile),
        throwsA(isA<Exception>().having(
          (Exception e) => e.toString(),
          'description',
          contains('ZIP dosyasında içe aktarılabilecek Excel raporu bulunamadı'),
        )),
      );
    });

    test('3. Corrupt ZIP throws clear Turkish exception', () async {
      final File zipFile = File('${tempDir.path}/corrupt.zip');
      zipFile.writeAsStringSync('NOT_A_VALID_ZIP_HEADER');

      expect(
        () async => await ExcelImportService.importReportsFromZip(zipFile),
        throwsA(isA<Exception>().having(
          (Exception e) => e.toString(),
          'description',
          contains('ZIP dosyası okunamadı veya bozuk'),
        )),
      );
    });

    test('4. Handles duplicate report gracefully by skipping duplicate', () async {
      final List<int> excelBytes = createMockTrafoExcel(
        customerName: 'Duplicate Test A.Ş.',
        trafoLabel: 'TR-DUP',
        reportDate: '10.08.2026',
        testDate: '10.08.2026',
      );

      final File zipFile1 = createZipWithFiles(tempDir, 'test_dup1.zip', <String, List<int>>{
        'rapor_dup.xlsx': excelBytes,
      });

      final ExcelImportResult res1 = await ExcelImportService.importReportsFromZip(zipFile1);
      expect(res1.successCount, equals(1));

      // Re-import same Excel
      final File zipFile2 = createZipWithFiles(tempDir, 'test_dup2.zip', <String, List<int>>{
        'rapor_dup_copy.xlsx': excelBytes,
      });

      final ExcelImportResult res2 = await ExcelImportService.importReportsFromZip(zipFile2);
      expect(res2.successCount, equals(0));
      expect(res2.skippedCount, equals(1));
      expect(res2.duplicateDetails.first, contains('zaten içe aktarılmış'));
    });

    test('5. Handles partial successes with subfolders in ZIP (2024/rapor.xlsx)', () async {
      final List<int> validBytes = createMockTrafoExcel(
        customerName: 'Klasörlü Sanayi',
        trafoLabel: 'TR-2024',
        reportDate: '01.01.2024',
        testDate: '01.01.2024',
      );
      final List<int> invalidBytes = createMockTrafoExcel(
        customerName: 'Hatalı',
        trafoLabel: 'H-1',
        reportDate: '',
        testDate: '',
        isValidFormat: false,
      );

      final File zipFile = createZipWithFiles(tempDir, 'test_nested.zip', <String, List<int>>{
        '2024/subfolder/rapor_valid.xlsx': validBytes,
        '2024/subfolder/rapor_invalid.xlsx': invalidBytes,
        'non_excel.txt': <int>[1, 2, 3],
      });

      final ExcelImportResult res = await ExcelImportService.importReportsFromZip(zipFile);

      expect(res.totalFiles, equals(2));
      expect(res.successCount, equals(1));
      expect(res.failureCount, equals(1));
      expect(res.failureDetails.first, contains('Geçersiz TrafoReport Excel formatı'));
    });
  });
}
