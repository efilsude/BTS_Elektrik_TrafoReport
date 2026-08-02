class ExcelCellMapping {
  /// Asset paths mapped to normalized transformer types
  static const Map<String, String> templateAssetPaths = <String, String>{
    'hermetik': 'assets/templates/hermetik.xlsx',
    'kuru_tip': 'assets/templates/kuru_tip.xlsx',
    'gt': 'assets/templates/gt.xlsx',
  };

  /// Cell mappings per sheet name
  static const Map<String, Map<String, String>> cellMapping = <String, Map<String, String>>{
    'KAPAK SAYFASI': <String, String>{
      'D9': 'customer_name',
      'D10': 'trafo_label',
      'D11': 'address',
      'D12': 'report_date',
      'D14': 'test_date',
      'D54': 'test_date',
      'D55': 'report_date',
      'D56': 'creator_display_name',
      'D57': 'sicil_no',
      'D58': 'ekipnet_no',
      'B31': 'summary_text',
    },
    'ANA SAYFA': <String, String>{
      'K2': 'customer_name',
      'K5': 'trafo_label',
      'G11': 'brand',
      'O11': 'tap_info',
      'G13': 'power_kva',
      'O13': 'manufacture_year',
      'G15': 'voltage',
      'O15': 'serial_no',
      'G17': 'oil_brand',
      'O17': 'oil_weight',
      'G19': 'connection_group',
      'O19': 'short_circuit_imp_pct',
      'G21': 'tank_type',
    },
    'OG SARGI MEVCUT KADEME': <String, String>{
      'K24': 'og_r_a',
      'K25': 'og_r_b',
      'K26': 'og_r_c',
    },
    'AG SARGI': <String, String>{
      'K24': 'ag_r_a',
      'K25': 'ag_r_b',
      'K26': 'ag_r_c',
    },
  };

  /// Converts a date string (DD.MM.YYYY or YYYY-MM-DD) into an Excel serial date number (epoch 1899-12-30)
  static double? dateToExcelSerial(dynamic dateInput) {
    if (dateInput == null) return null;
    final String str = dateInput.toString().trim();
    if (str.isEmpty) return null;

    try {
      DateTime? dt;
      if (str.contains('.')) {
        final List<String> parts = str.split('.');
        if (parts.length >= 3) {
          dt = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else if (str.contains('-')) {
        final List<String> parts = str.split('-');
        if (parts.length >= 3) {
          dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      }

      if (dt != null) {
        final DateTime epoch = DateTime(1899, 12, 30);
        return dt.difference(epoch).inDays.toDouble();
      }
    } catch (_) {}
    return null;
  }

  /// Formats date display to DD.MM.YYYY for filenames
  static String formatDateDisplay(dynamic dateInput) {
    if (dateInput == null) {
      final DateTime now = DateTime.now();
      return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    }
    final String str = dateInput.toString().trim();
    if (str.isEmpty) {
      final DateTime now = DateTime.now();
      return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
    }

    try {
      if (str.contains('.')) {
        final List<String> parts = str.split('.');
        if (parts.length >= 3) {
          return '${int.parse(parts[0]).toString().padLeft(2, '0')}.${int.parse(parts[1]).toString().padLeft(2, '0')}.${parts[2]}';
        }
      } else if (str.contains('-')) {
        final List<String> parts = str.split('-');
        if (parts.length >= 3) {
          return '${int.parse(parts[2]).toString().padLeft(2, '0')}.${int.parse(parts[1]).toString().padLeft(2, '0')}.${parts[0]}';
        }
      }
    } catch (_) {}
    return str;
  }

  /// Sanitizes OS filename characters
  static String sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_');
  }
}
