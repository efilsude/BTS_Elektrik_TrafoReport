import 'package:flutter_test/flutter_test.dart';
import 'package:trafo_report_mobile/excel/cell_mapping.dart';
import 'package:trafo_report_mobile/models/report_model.dart';

void main() {
  group('Year Filter & Test Date Parsing / Sorting Tests', () {
    test('1. ExcelCellMapping.tryParseDateTime parses various formats securely', () {
      expect(ExcelCellMapping.tryParseDateTime('2025-08-20'), equals(DateTime(2025, 8, 20)));
      expect(ExcelCellMapping.tryParseDateTime('20.08.2025'), equals(DateTime(2025, 8, 20)));
      expect(ExcelCellMapping.tryParseDateTime('20/08/2025'), equals(DateTime(2025, 8, 20)));
      expect(ExcelCellMapping.tryParseDateTime('2025/08/20'), equals(DateTime(2025, 8, 20)));
      expect(ExcelCellMapping.tryParseDateTime('2025-08-20T14:30:00.000'), equals(DateTime(2025, 8, 20, 14, 30)));

      // Invalid / empty inputs return null
      expect(ExcelCellMapping.tryParseDateTime(null), isNull);
      expect(ExcelCellMapping.tryParseDateTime(''), isNull);
      expect(ExcelCellMapping.tryParseDateTime('-'), isNull);
      expect(ExcelCellMapping.tryParseDateTime('invalid_date_str'), isNull);
    });

    test('2. Extract unique years in descending order (newest to oldest)', () {
      final List<Report> reports = <Report>[
        Report(
          id: 'r1',
          title: 'Rep 1',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Firm A',
          trafoLabel: 'TR1',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': '15.03.2024'},
          createdAt: DateTime(2024, 3, 15),
          updatedAt: DateTime(2024, 3, 15),
        ),
        Report(
          id: 'r2',
          title: 'Rep 2',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Firm B',
          trafoLabel: 'TR2',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': '20.12.2026'},
          createdAt: DateTime(2026, 12, 20),
          updatedAt: DateTime(2026, 12, 20),
        ),
        Report(
          id: 'r3',
          title: 'Rep 3',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Firm C',
          trafoLabel: 'TR3',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': '10.05.2025'},
          createdAt: DateTime(2025, 5, 10),
          updatedAt: DateTime(2025, 5, 10),
        ),
        Report(
          id: 'r4',
          title: 'Rep 4',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Firm D',
          trafoLabel: 'TR4',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': ''},
          createdAt: DateTime(2023, 1, 1),
          updatedAt: DateTime(2023, 1, 1),
        ),
      ];

      final Set<int> yearsSet = <int>{};
      for (final Report r in reports) {
        final DateTime? dt = ExcelCellMapping.tryParseDateTime(r.dataJson['test_date']);
        if (dt != null) {
          yearsSet.add(dt.year);
        }
      }

      final List<int> sortedYears = yearsSet.toList()..sort((int a, int b) => b.compareTo(a));
      expect(sortedYears, equals(<int>[2026, 2025, 2024]));
    });

    test('3. Filtering by specific year filters accurately and excludes invalid date reports', () {
      final List<Report> reports = <Report>[
        Report(
          id: 'r1',
          title: 'Rep 1',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Firm A',
          trafoLabel: 'TR1',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': '10.01.2025'},
          createdAt: DateTime(2025, 1, 10),
          updatedAt: DateTime(2025, 1, 10),
        ),
        Report(
          id: 'r2',
          title: 'Rep 2',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Firm B',
          trafoLabel: 'TR2',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': '20.12.2025'},
          createdAt: DateTime(2025, 12, 20),
          updatedAt: DateTime(2025, 12, 20),
        ),
        Report(
          id: 'r3',
          title: 'Rep 3',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Firm C',
          trafoLabel: 'TR3',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': '05.08.2024'},
          createdAt: DateTime(2024, 8, 5),
          updatedAt: DateTime(2024, 8, 5),
        ),
        Report(
          id: 'r4_invalid',
          title: 'Rep 4',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Firm D',
          trafoLabel: 'TR4',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': 'gecersiz_tarih'},
          createdAt: DateTime(2025, 5, 5),
          updatedAt: DateTime(2025, 5, 5),
        ),
      ];

      // Filter for year 2025
      final List<Report> filtered2025 = reports.where((Report r) {
        final DateTime? dt = ExcelCellMapping.tryParseDateTime(r.dataJson['test_date']);
        return dt != null && dt.year == 2025;
      }).toList();

      expect(filtered2025.length, equals(2));
      expect(filtered2025.map((Report r) => r.id), containsAll(<String>['r1', 'r2']));
      expect(filtered2025.map((Report r) => r.id), isNot(contains('r4_invalid')));
    });

    test('4. Sort reports strictly by test date from NEWEST to OLDEST (EN YENİ → EN ESKİ)', () {
      final List<Report> reports = <Report>[
        Report(
          id: 'r_jan',
          title: 'Jan 2025',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Cust',
          trafoLabel: 'TR',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': '10.01.2025'},
          createdAt: DateTime(2025, 1, 10),
          updatedAt: DateTime(2025, 1, 10),
        ),
        Report(
          id: 'r_dec',
          title: 'Dec 2025',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Cust',
          trafoLabel: 'TR',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': '20.12.2025'},
          createdAt: DateTime(2025, 12, 20),
          updatedAt: DateTime(2025, 12, 20),
        ),
        Report(
          id: 'r_nov',
          title: 'Nov 2025',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Cust',
          trafoLabel: 'TR',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': '15.11.2025'},
          createdAt: DateTime(2025, 11, 15),
          updatedAt: DateTime(2025, 11, 15),
        ),
        Report(
          id: 'r_aug',
          title: 'Aug 2025',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'Cust',
          trafoLabel: 'TR',
          status: 'finalized',
          currentStep: 6,
          dataJson: <String, dynamic>{'test_date': '03.08.2025'},
          createdAt: DateTime(2025, 8, 3),
          updatedAt: DateTime(2025, 8, 3),
        ),
      ];

      reports.sort((Report a, Report b) {
        final DateTime? dtA = ExcelCellMapping.tryParseDateTime(a.dataJson['test_date']);
        final DateTime? dtB = ExcelCellMapping.tryParseDateTime(b.dataJson['test_date']);
        if (dtA != null && dtB != null) {
          return dtB.compareTo(dtA); // Newest to oldest
        }
        return 0;
      });

      final List<String> sortedIds = reports.map((Report r) => r.id).toList();
      expect(sortedIds, equals(<String>['r_dec', 'r_nov', 'r_aug', 'r_jan']));
    });
  });
}
