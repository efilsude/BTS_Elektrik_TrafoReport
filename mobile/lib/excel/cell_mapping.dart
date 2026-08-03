class ExcelCellMapping {
  /// Asset paths mapped to normalized transformer types
  static const Map<String, String> templateAssetPaths = <String, String>{
    'hermetik': 'assets/templates/hermetik.xlsx',
    'kuru_tip': 'assets/templates/kuru_tip.xlsx',
    'gt': 'assets/templates/gt.xlsx',
  };

  /// Type-specific cell mappings per sheet name
  static const Map<String, Map<String, Map<String, String>>> typeCellMapping =
      <String, Map<String, Map<String, String>>>{
    'hermetik': <String, Map<String, String>>{
      'KAPAK SAYFASI': <String, String>{
        'D9': 'customer_name',
        'D10': 'trafo_label',
        'D11': 'address',
        'D12': 'report_date',
        'D14': 'test_date',
        'A31': 'summary_text',
        'D56': 'creator_display_name',
        'D57': 'sicil_no',
        'D58': 'ekipnet_no',
      },
      'ANA SAYFA': <String, String>{
        'G11': 'brand',
        'O11': 'tap_info_1',
        'Q11': 'tap_info_2',
        'S11': 'tap_info_3',
        'G13': 'power_kva',
        'O13': 'manufacture_year',
        'G15': 'voltage',
        'O15': 'serial_no',
        'G17': 'oil_brand',
        'O17': 'oil_weight',
        'G19': 'connection_group',
        'O19': 'short_circuit_imp_pct',
        'G21': 'tank_type',
        'I21': 'tank_mark_hermetik',
        'P21': 'tank_mark_gt',
        'U21': 'tank_mark_kuru',
        'J27': 'checklist_1',
        'J28': 'checklist_2',
        'J29': 'checklist_3',
        'J30': 'checklist_4',
        'J31': 'checklist_5',
        'J32': 'checklist_6',
        'J33': 'checklist_7',
        'J34': 'checklist_8',
        'J35': 'checklist_9',
        'J36': 'checklist_10',
        'J37': 'checklist_11',
        'J38': 'checklist_12',
        'J39': 'checklist_13',
        'J40': 'checklist_14',
        'J41': 'checklist_15',
        'J42': 'checklist_16',
        'U27': 'checklist_17',
        'U28': 'checklist_18',
        'U29': 'checklist_19',
        'U30': 'checklist_20',
        'U31': 'checklist_21',
        'U32': 'checklist_22',
        'U33': 'checklist_23',
        'U34': 'checklist_24',
        'U35': 'checklist_25',
        'U36': 'checklist_26',
        'U37': 'checklist_27',
        'U38': 'checklist_28',
        'U39': 'checklist_29',
        'U40': 'checklist_30',
        'U41': 'checklist_31',
        'U42': 'checklist_32',
        'C55': 'og_rab',
        'C57': 'og_rbc',
        'C59': 'og_rca',
        'J55': 'ag_ran',
        'J57': 'ag_rbn',
        'J59': 'ag_rcn',
        'O55': 'ag_rab',
        'O57': 'ag_rbc',
        'O59': 'ag_rca',
        'C61': 'ground_trafo_body',
        'F61': 'ground_neutral',
        'J61': 'ground_tank',
        'C63': 'ground_og_lightning',
        'F63': 'ground_panel',
        'J63': 'ground_fence',
      },
      'İZOLASYON ': <String, String>{
        'D16': 'iso_og_gnd',
        'D17': 'iso_ag_gnd',
        'D30': 'iso_temp',
        'D31': 'iso_humidity',
      },
      'Ç.O 34500': <String, String>{
        'B16': 'ttr_tap1_a',
        'C16': 'ttr_tap1_b',
        'D16': 'ttr_tap1_c',
        'B17': 'ttr_tap2_a',
        'C17': 'ttr_tap2_b',
        'D17': 'ttr_tap2_c',
        'B18': 'ttr_tap3_a',
        'C18': 'ttr_tap3_b',
        'D18': 'ttr_tap3_c',
        'B19': 'ttr_tap4_a',
        'C19': 'ttr_tap4_b',
        'D19': 'ttr_tap4_c',
        'B20': 'ttr_tap5_a',
        'C20': 'ttr_tap5_b',
        'D20': 'ttr_tap5_c',
      },
      'TOPRAKLAMALAR': <String, String>{
        'D17': 'ground_r_trafo_body',
        'D18': 'ground_r_neutral',
        'D19': 'ground_r_tank',
        'D32': 'ground_r_og_lightning',
        'D33': 'ground_r_panel',
        'D34': 'ground_r_fence',
      },
      'HV PF': <String, String>{
        'P17': 'pf_hv_humidity',
      },
      'LV PF': <String, String>{
        'P17': 'pf_lv_humidity',
      },
      'ANA SAYFA KESİCİ': <String, String>{
        'G11': 'breaker_brand',
        'O11': 'breaker_serial_no',
        'G13': 'breaker_model',
        'O13': 'breaker_year',
      },
      'KESİCİ İZOLASYON': <String, String>{
        'D10': 'breaker_iso_r_gnd',
      },
      'KESİCİ KONTAK': <String, String>{
        'D10': 'breaker_contact_r',
      },
      'AÇMA-KAPAMA': <String, String>{
        'D10': 'breaker_timing_open',
      },
      'DİĞER': <String, String>{
        'D16': 'device_model',
        'D17': 'device_serial',
      },
      'AKIM TRAFOLARI': <String, String>{
        'D16': 'ct_ratio',
      },
      'HERMETİK YAĞ DİLEKÇESİ': <String, String>{
        'D16': 'oil_test_breakdown_voltage',
        'D18': 'oil_test_water_content',
      },
    },
    'kuru_tip': <String, Map<String, String>>{
      'KAPAK SAYFASI': <String, String>{
        'D9': 'customer_name',
        'D10': 'trafo_label',
        'D11': 'address',
        'D12': 'report_date',
        'D14': 'test_date',
        'A31': 'summary_text',
        'D56': 'creator_display_name',
        'D57': 'sicil_no',
        'D58': 'ekipnet_no',
      },
      'ANA SAYFA': <String, String>{
        'G11': 'brand',
        'O11': 'tap_info_1',
        'Q11': 'tap_info_2',
        'S11': 'tap_info_3',
        'G13': 'power_kva',
        'O13': 'manufacture_year',
        'G15': 'voltage',
        'O15': 'serial_no',
        'G17': 'connection_group',
        'O17': 'short_circuit_imp_pct',
        'G19': 'tank_type',
        'I19': 'tank_mark_hermetik',
        'P19': 'tank_mark_gt',
        'U19': 'tank_mark_kuru',
        'J24': 'checklist_1',
        'J25': 'checklist_2',
        'J26': 'checklist_3',
        'J27': 'checklist_4',
        'J28': 'checklist_5',
        'J29': 'checklist_6',
        'J30': 'checklist_7',
        'J31': 'checklist_8',
        'J32': 'checklist_9',
        'J33': 'checklist_10',
        'J34': 'checklist_11',
        'J35': 'checklist_12',
        'J36': 'checklist_13',
        'J37': 'checklist_14',
        'J38': 'checklist_15',
        'J39': 'checklist_16',
        'U24': 'checklist_17',
        'U25': 'checklist_18',
        'U26': 'checklist_19',
        'U27': 'checklist_20',
        'U28': 'checklist_21',
        'U29': 'checklist_22',
        'U30': 'checklist_23',
        'U31': 'checklist_24',
        'U32': 'checklist_25',
        'U33': 'checklist_26',
        'U34': 'checklist_27',
        'U35': 'checklist_28',
        'U36': 'checklist_29',
        'U37': 'checklist_30',
        'U38': 'checklist_31',
        'U39': 'checklist_32',
        'C49': 'og_rab',
        'C51': 'og_rbc',
        'C53': 'og_rca',
        'J49': 'ag_ran',
        'J51': 'ag_rbn',
        'J53': 'ag_rcn',
        'O49': 'ag_rab',
        'O51': 'ag_rbc',
        'O53': 'ag_rca',
        'C55': 'ground_trafo_body',
        'F55': 'ground_neutral',
        'J55': 'ground_tank',
        'C57': 'ground_og_lightning',
        'F57': 'ground_panel',
        'J57': 'ground_fence',
      },
      'İZOLASYON ': <String, String>{
        'D16': 'iso_og_gnd',
        'D17': 'iso_ag_gnd',
        'D30': 'iso_temp',
        'D31': 'iso_humidity',
      },
      'Ç.O 34500': <String, String>{
        'B16': 'ttr_tap1_a',
        'C16': 'ttr_tap1_b',
        'D16': 'ttr_tap1_c',
        'B17': 'ttr_tap2_a',
        'C17': 'ttr_tap2_b',
        'D17': 'ttr_tap2_c',
        'B18': 'ttr_tap3_a',
        'C18': 'ttr_tap3_b',
        'D18': 'ttr_tap3_c',
        'B19': 'ttr_tap4_a',
        'C19': 'ttr_tap4_b',
        'D19': 'ttr_tap4_c',
        'B20': 'ttr_tap5_a',
        'C20': 'ttr_tap5_b',
        'D20': 'ttr_tap5_c',
      },
      'TOPRAKLAMALAR': <String, String>{
        'D17': 'ground_r_trafo_body',
        'D18': 'ground_r_neutral',
        'D19': 'ground_r_tank',
        'D32': 'ground_r_og_lightning',
        'D33': 'ground_r_panel',
        'D34': 'ground_r_fence',
      },
      'HV PF': <String, String>{
        'P17': 'pf_hv_humidity',
      },
      'LV PF': <String, String>{
        'P17': 'pf_lv_humidity',
      },
      'ANA SAYFA KESİCİ': <String, String>{
        'G11': 'breaker_brand',
        'O11': 'breaker_serial_no',
        'G13': 'breaker_model',
        'O13': 'breaker_year',
      },
      'KESİCİ İZOLASYON': <String, String>{
        'D10': 'breaker_iso_r_gnd',
      },
      'KESİCİ KONTAK': <String, String>{
        'D10': 'breaker_contact_r',
      },
      'AÇMA-KAPAMA': <String, String>{
        'D10': 'breaker_timing_open',
      },
      'DİĞER': <String, String>{
        'D16': 'device_model',
        'D17': 'device_serial',
      },
      'AKIM TRAFOLARI': <String, String>{
        'D16': 'ct_ratio',
      },
    },
    'gt': <String, Map<String, String>>{
      'KAPAK SAYFASI': <String, String>{
        'D9': 'customer_name',
        'D10': 'trafo_label',
        'D11': 'address',
        'D12': 'report_date',
        'D14': 'test_date',
        'A31': 'summary_text',
        'D56': 'creator_display_name',
        'D57': 'sicil_no',
        'D58': 'ekipnet_no',
      },
      'ANA SAYFA': <String, String>{
        'G11': 'brand',
        'O11': 'tap_info_1',
        'Q11': 'tap_info_2',
        'S11': 'tap_info_3',
        'G13': 'power_kva',
        'O13': 'manufacture_year',
        'G15': 'voltage',
        'O15': 'serial_no',
        'G17': 'oil_brand',
        'O17': 'oil_weight',
        'G19': 'connection_group',
        'O19': 'short_circuit_imp_pct',
        'G21': 'tank_type',
        'I21': 'tank_mark_hermetik',
        'P21': 'tank_mark_gt',
        'U21': 'tank_mark_kuru',
        'J27': 'checklist_1',
        'J28': 'checklist_2',
        'J29': 'checklist_3',
        'J30': 'checklist_4',
        'J31': 'checklist_5',
        'J32': 'checklist_6',
        'J33': 'checklist_7',
        'J34': 'checklist_8',
        'J35': 'checklist_9',
        'J36': 'checklist_10',
        'J37': 'checklist_11',
        'J38': 'checklist_12',
        'J39': 'checklist_13',
        'J40': 'checklist_14',
        'J41': 'checklist_15',
        'J42': 'checklist_16',
        'U27': 'checklist_17',
        'U28': 'checklist_18',
        'U29': 'checklist_19',
        'U30': 'checklist_20',
        'U31': 'checklist_21',
        'U32': 'checklist_22',
        'U33': 'checklist_23',
        'U34': 'checklist_24',
        'U35': 'checklist_25',
        'U36': 'checklist_26',
        'U37': 'checklist_27',
        'U38': 'checklist_28',
        'U39': 'checklist_29',
        'U40': 'checklist_30',
        'U41': 'checklist_31',
        'U42': 'checklist_32',
        'C55': 'og_rab',
        'C57': 'og_rbc',
        'C59': 'og_rca',
        'J55': 'ag_ran',
        'J57': 'ag_rbn',
        'J59': 'ag_rcn',
        'O55': 'ag_rab',
        'O57': 'ag_rbc',
        'O59': 'ag_rca',
        'C61': 'ground_trafo_body',
        'F61': 'ground_neutral',
        'J61': 'ground_tank',
        'C63': 'ground_og_lightning',
        'F63': 'ground_panel',
        'J63': 'ground_fence',
      },
      'İZOLASYON ': <String, String>{
        'D16': 'iso_og_gnd',
        'D17': 'iso_ag_gnd',
        'D30': 'iso_temp',
        'D31': 'iso_humidity',
      },
      'Ç.O 34500': <String, String>{
        'B16': 'ttr_tap1_a',
        'C16': 'ttr_tap1_b',
        'D16': 'ttr_tap1_c',
        'B17': 'ttr_tap2_a',
        'C17': 'ttr_tap2_b',
        'D17': 'ttr_tap2_c',
        'B18': 'ttr_tap3_a',
        'C18': 'ttr_tap3_b',
        'D18': 'ttr_tap3_c',
        'B19': 'ttr_tap4_a',
        'C19': 'ttr_tap4_b',
        'D19': 'ttr_tap4_c',
        'B20': 'ttr_tap5_a',
        'C20': 'ttr_tap5_b',
        'D20': 'ttr_tap5_c',
      },
      'TOPRAKLAMALAR': <String, String>{
        'D17': 'ground_r_trafo_body',
        'D18': 'ground_r_neutral',
        'D19': 'ground_r_tank',
        'D32': 'ground_r_og_lightning',
        'D33': 'ground_r_panel',
        'D34': 'ground_r_fence',
      },
      'ANA SAYFA KESİCİ': <String, String>{
        'G11': 'breaker_brand',
        'O11': 'breaker_serial_no',
        'G13': 'breaker_model',
        'O13': 'breaker_year',
      },
      'KESİCİ İZOLASYON': <String, String>{
        'D10': 'breaker_iso_r_gnd',
      },
      'KESİCİ KONTAK': <String, String>{
        'D10': 'breaker_contact_r',
      },
      'AÇMA-KAPAMA': <String, String>{
        'D10': 'breaker_timing_open',
      },
      'YAĞ RAPORU': <String, String>{
        'D16': 'oil_test_breakdown_voltage',
        'D18': 'oil_test_water_content',
      },
      'HERMETİK YAĞ DİLEKÇESİ': <String, String>{
        'D16': 'oil_test_breakdown_voltage',
        'D18': 'oil_test_water_content',
      },
    },
  };

  /// Backward-compatible global cell mapping
  static Map<String, Map<String, String>> get cellMapping =>
      typeCellMapping['hermetik']!;

  /// Retrieves cell mapping for specific transformer type with fallback
  static Map<String, Map<String, String>> cellMappingForType(String transformerType) {
    final String key = transformerType.toLowerCase().trim();
    return typeCellMapping[key] ?? typeCellMapping['hermetik']!;
  }

  /// Normalizes sheet name by trimming whitespace
  static String normalizeSheetName(String sheetName) {
    return sheetName.trim();
  }

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

  /// Sanitizes formula string: translates Turkish names to English, converts ';' to ',', and fixes decimal separators
  static String sanitizeFormula(String formula) {
    if (formula.isEmpty) return formula;

    String clean = formula;

    // 1. Translate Turkish Formula Names to English (case-insensitive)
    final Map<Pattern, String> translations = <Pattern, String>{
      RegExp(r'\bEĞER\b', caseSensitive: false): 'IF',
      RegExp(r'\bTOPLA\b', caseSensitive: false): 'SUM',
      RegExp(r'\bORTALAMA\b', caseSensitive: false): 'AVERAGE',
      RegExp(r'\bMAK\b', caseSensitive: false): 'MAX',
      RegExp(r'\bMİN\b', caseSensitive: false): 'MIN',
      RegExp(r'\bEĞERSAY\b', caseSensitive: false): 'COUNTIF',
      RegExp(r'\bDÜŞEYARA\b', caseSensitive: false): 'VLOOKUP',
      RegExp(r'\bEĞERHATA\b', caseSensitive: false): 'IFERROR',
      RegExp(r'\bYADA\b', caseSensitive: false): 'OR',
      RegExp(r'\bVE\b', caseSensitive: false): 'AND',
      RegExp(r'\bYUVARLA\b', caseSensitive: false): 'ROUND',
      RegExp(r'\bAŞAĞIYUVARLA\b', caseSensitive: false): 'ROUNDDOWN',
      RegExp(r'\bYUKARIYUVARLA\b', caseSensitive: false): 'ROUNDUP',
    };

    translations.forEach((Pattern pattern, String replacement) {
      clean = clean.replaceAll(pattern, replacement);
    });

    // 2. Replace parameter separator ';' with ','
    clean = clean.replaceAll(';', ',');

    // 3. Fix decimal comma separators inside numeric literals in formulas (e.g. 12,54 -> 12.54)
    clean = clean.replaceAllMapped(RegExp(r'(\d+),(\d+)'), (Match m) => '${m[1]}.${m[2]}');

    return clean;
  }

  /// Ensures double is formatted with dot (.) decimal separator
  static String formatDouble(double val) {
    return val.toString().replaceAll(',', '.');
  }
}
