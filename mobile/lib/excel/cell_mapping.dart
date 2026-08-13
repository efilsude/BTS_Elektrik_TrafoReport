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
        'D56': 'operator_title',
        'D57': 'sicil_no',
        'D58': 'ekipnet_no',
        'G56': 'operator_name',
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
        'C55': 'og_rab',
        'C57': 'og_rbc',
        'C59': 'og_rca',
        'J55': 'ag_ran',
        'J57': 'ag_rbn',
        'J59': 'ag_rcn',
        'O55': 'ag_rab',
        'O57': 'ag_rbc',
        'O59': 'ag_rca',
        'B73': 'notes',
        'F80': 'operator_title',
        'F81': 'sicil_no',
        'F82': 'ekipnet_no',
        'K79': 'operator_name',
      },
      'OG SARGI MEVCUT KADEME': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
      },
      'AG SARGI': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
      },
      'İZOLASYON ': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
        'D16': 'iso_og_gnd',
        'D17': 'iso_ag_gnd',
        'D30': 'iso_temp',
        'D31': 'iso_humidity',
      },
      'Ç.O 34500': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
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
        'D9': 'operator_name',
        'J9': 'device_model',
        'O9': 'device_serial',
        'D17': 'ground_r_trafo_body',
        'D18': 'ground_r_neutral',
        'D19': 'ground_r_tank',
        'D32': 'ground_r_og_lightning',
        'D33': 'ground_r_panel',
        'D34': 'ground_r_fence',
      },
      'HV PF': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
        'P17': 'pf_hv_humidity',
      },
      'LV PF': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
        'P17': 'pf_lv_humidity',
      },
      'ANA SAYFA KESİCİ': <String, String>{
        'G11': 'breaker_brand',
        'O11': 'breaker_serial_no',
        'G13': 'breaker_model',
        'O13': 'breaker_year',
      },
      'KESİCİ İZOLASYON': <String, String>{
        'D10': 'operator_name',
        'J10': 'device_model',
        'O10': 'device_serial',
        'D10_VAL': 'breaker_iso_r_gnd',
      },
      'KESİCİ KONTAK': <String, String>{
        'D10': 'operator_name',
        'J10': 'device_model',
        'O10': 'device_serial',
        'D10_VAL': 'breaker_contact_r',
      },
      'AÇMA-KAPAMA': <String, String>{
        'D9': 'operator_name',
        'J9': 'device_model',
        'O9': 'device_serial',
        'D10': 'breaker_timing_open',
      },
      'DİĞER': <String, String>{
        'D9': 'operator_name',
        'J9': 'device_model',
        'O9': 'device_serial',
        'D16': 'device_model',
        'D17': 'device_serial',
      },
      'AKIM TRAFOLARI': <String, String>{
        'D9': 'operator_name',
        'J9': 'device_model',
        'O9': 'device_serial',
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
        'D56': 'operator_title',
        'D57': 'sicil_no',
        'D58': 'ekipnet_no',
        'G56': 'operator_name',
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
        'C49': 'og_rab',
        'C51': 'og_rbc',
        'C53': 'og_rca',
        'J49': 'ag_ran',
        'J51': 'ag_rbn',
        'J53': 'ag_rcn',
        'O49': 'ag_rab',
        'O51': 'ag_rbc',
        'O53': 'ag_rca',
        'C55': 'ground_r_trafo_body',
        'F55': 'ground_r_neutral',
        'J55': 'ground_r_tank',
        'C57': 'ground_r_og_lightning',
        'F57': 'ground_r_panel',
        'J57': 'ground_r_fence',
        'B67': 'notes',
        'F74': 'operator_title',
        'F75': 'sicil_no',
        'F76': 'ekipnet_no',
        'K73': 'operator_name',
      },
      'OG SARGI MEVCUT KADEME': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
      },
      'AG SARGI': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
      },
      'İZOLASYON ': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
        'D16': 'iso_og_gnd',
        'D17': 'iso_ag_gnd',
        'D30': 'iso_temp',
        'D31': 'iso_humidity',
      },
      'Ç.O 34500': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
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
        'D9': 'operator_name',
        'J9': 'device_model',
        'O9': 'device_serial',
        'D17': 'ground_r_trafo_body',
        'D18': 'ground_r_neutral',
        'D19': 'ground_r_tank',
        'D32': 'ground_r_og_lightning',
        'D33': 'ground_r_panel',
        'D34': 'ground_r_fence',
      },
      'HV PF': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
        'P17': 'pf_hv_humidity',
      },
      'LV PF': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
        'P17': 'pf_lv_humidity',
      },
      'ANA SAYFA KESİCİ': <String, String>{
        'G11': 'breaker_brand',
        'O11': 'breaker_serial_no',
        'G13': 'breaker_model',
        'O13': 'breaker_year',
      },
      'KESİCİ İZOLASYON': <String, String>{
        'D10': 'operator_name',
        'J10': 'device_model',
        'O10': 'device_serial',
        'D10_VAL': 'breaker_iso_r_gnd',
      },
      'KESİCİ KONTAK': <String, String>{
        'D10': 'operator_name',
        'J10': 'device_model',
        'O10': 'device_serial',
        'D10_VAL': 'breaker_contact_r',
      },
      'AÇMA-KAPAMA': <String, String>{
        'D9': 'operator_name',
        'J9': 'device_model',
        'O9': 'device_serial',
        'D10': 'breaker_timing_open',
      },
      'DİĞER': <String, String>{
        'D9': 'operator_name',
        'J9': 'device_model',
        'O9': 'device_serial',
        'D16': 'device_model',
        'D17': 'device_serial',
      },
      'AKIM TRAFOLARI': <String, String>{
        'D9': 'operator_name',
        'J9': 'device_model',
        'O9': 'device_serial',
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
        'D56': 'operator_title',
        'D57': 'sicil_no',
        'D58': 'ekipnet_no',
        'G56': 'operator_name',
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
        'C55': 'og_rab',
        'C57': 'og_rbc',
        'C59': 'og_rca',
        'J55': 'ag_ran',
        'J57': 'ag_rbn',
        'J59': 'ag_rcn',
        'O55': 'ag_rab',
        'O57': 'ag_rbc',
        'O59': 'ag_rca',
        'C61': 'ground_r_trafo_body',
        'F61': 'ground_r_neutral',
        'J61': 'ground_r_tank',
        'C63': 'ground_r_og_lightning',
        'F63': 'ground_r_panel',
        'J63': 'ground_r_fence',
        'B73': 'notes',
        'F80': 'operator_title',
        'F81': 'sicil_no',
        'F82': 'ekipnet_no',
        'K79': 'operator_name',
      },
      'OG SARGI MEVCUT KADEME': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
      },
      'AG SARGI': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
      },
      'İZOLASYON ': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
        'D16': 'iso_og_gnd',
        'D17': 'iso_ag_gnd',
        'D30': 'iso_temp',
        'D31': 'iso_humidity',
      },
      'Ç.O 34500': <String, String>{
        'D11': 'operator_name',
        'J11': 'device_model',
        'O11': 'device_serial',
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
        'D9': 'operator_name',
        'J9': 'device_model',
        'O9': 'device_serial',
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
        'D10': 'operator_name',
        'J10': 'device_model',
        'O10': 'device_serial',
        'D10_VAL': 'breaker_iso_r_gnd',
      },
      'KESİCİ KONTAK': <String, String>{
        'D10': 'operator_name',
        'J10': 'device_model',
        'O10': 'device_serial',
        'D10_VAL': 'breaker_contact_r',
      },
      'AÇMA-KAPAMA': <String, String>{
        'D9': 'operator_name',
        'J9': 'device_model',
        'O9': 'device_serial',
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

  /// Sheet signature anchor cells per transformer type
  static const Map<String, Map<String, String>> sheetSignatureAnchors = <String, Map<String, String>>{
    'hermetik': <String, String>{
      'KAPAK SAYFASI': 'G56',
      'ANA SAYFA': 'K79',
      'ANA SAYFA KESİCİ': 'K75',
      'OG SARGI MEVCUT KADEME': 'J46',
      'AG SARGI': 'J46',
      'İZOLASYON ': 'J51',
      'Ç.O 34500': 'J51',
      'TOPRAKLAMALAR': 'J48',
      'HV PF': 'J45',
      'LV PF': 'J45',
      'KESİCİ İZOLASYON': 'J41',
      'KESİCİ KONTAK': 'J51',
      'AÇMA-KAPAMA': 'J49',
      'DİĞER': 'J45',
      'AKIM TRAFOLARI': 'J45',
      'HERMETİK YAĞ DİLEKÇESİ': 'J53',
    },
    'kuru_tip': <String, String>{
      'KAPAK SAYFASI': 'G56',
      'ANA SAYFA': 'K73',
      'ANA SAYFA KESİCİ': 'K75',
      'OG SARGI MEVCUT KADEME': 'J46',
      'AG SARGI': 'J46',
      'İZOLASYON ': 'J51',
      'Ç.O 34500': 'J51',
      'TOPRAKLAMALAR': 'J48',
      'HV PF': 'J45',
      'LV PF': 'J45',
      'KESİCİ İZOLASYON': 'J51',
      'KESİCİ KONTAK': 'J51',
      'AÇMA-KAPAMA': 'J49',
      'DİĞER': 'J45',
      'AKIM TRAFOLARI': 'J45',
    },
    'gt': <String, String>{
      'KAPAK SAYFASI': 'G56',
      'ANA SAYFA': 'K79',
      'ANA SAYFA KESİCİ': 'K75',
      'OG SARGI MEVCUT KADEME': 'J46',
      'AG SARGI': 'J46',
      'İZOLASYON ': 'J51',
      'Ç.O 34500': 'J51',
      'TOPRAKLAMALAR': 'J48',
      'KESİCİ İZOLASYON': 'J51',
      'KESİCİ KONTAK': 'J51',
      'AÇMA-KAPAMA': 'J49',
      'YAĞ RAPORU': 'J53',
      'HERMETİK YAĞ DİLEKÇESİ': 'J53',
    },
  };

  /// Evet/Hayır cell pairs for ANA SAYFA checklist items per transformer type
  static const Map<String, Map<String, Map<String, String>>> checklistPairs = <String, Map<String, Map<String, String>>>{
    'hermetik': <String, Map<String, String>>{
      'checklist_1': <String, String>{'evet': 'I27', 'hayir': 'J27'},
      'checklist_2': <String, String>{'evet': 'I29', 'hayir': 'J29'},
      'checklist_3': <String, String>{'evet': 'I31', 'hayir': 'J31'},
      'checklist_4': <String, String>{'evet': 'I33', 'hayir': 'J33'},
      'checklist_5': <String, String>{'evet': 'I35', 'hayir': 'J35'},
      'checklist_6': <String, String>{'evet': 'I37', 'hayir': 'J37'},
      'checklist_7': <String, String>{'evet': 'I39', 'hayir': 'J39'},
      'checklist_8': <String, String>{'evet': 'I41', 'hayir': 'J41'},
      'checklist_9': <String, String>{'evet': 'R27', 'hayir': 'S27'},
      'checklist_10': <String, String>{'evet': 'R29', 'hayir': 'S29'},
      'checklist_11': <String, String>{'evet': 'R31', 'hayir': 'S31'},
      'checklist_12': <String, String>{'evet': 'R33', 'hayir': 'S33'},
      'checklist_13': <String, String>{'evet': 'R35', 'hayir': 'S35'},
      'checklist_14': <String, String>{'evet': 'R37', 'hayir': 'S37'},
      'checklist_15': <String, String>{'evet': 'R39', 'hayir': 'S39'},
      'checklist_16': <String, String>{'evet': 'R41', 'hayir': 'S41'},
    },
    'kuru_tip': <String, Map<String, String>>{
      'checklist_1': <String, String>{'evet': 'I26', 'hayir': 'J26'},
      'checklist_2': <String, String>{'evet': 'I28', 'hayir': 'J28'},
      'checklist_3': <String, String>{'evet': 'I30', 'hayir': 'J30'},
      'checklist_4': <String, String>{'evet': 'I32', 'hayir': 'J32'},
      'checklist_5': <String, String>{'evet': 'I34', 'hayir': 'J34'},
      'checklist_6': <String, String>{'evet': 'I36', 'hayir': 'J36'},
      'checklist_7': <String, String>{'evet': 'R26', 'hayir': 'S26'},
      'checklist_8': <String, String>{'evet': 'R28', 'hayir': 'S28'},
      'checklist_9': <String, String>{'evet': 'R30', 'hayir': 'S30'},
      'checklist_10': <String, String>{'evet': 'R32', 'hayir': 'S32'},
      'checklist_11': <String, String>{'evet': 'R34', 'hayir': 'S34'},
      'checklist_12': <String, String>{'evet': 'R36', 'hayir': 'S36'},
    },
    'gt': <String, Map<String, String>>{
      'checklist_1': <String, String>{'evet': 'I27', 'hayir': 'J27'},
      'checklist_2': <String, String>{'evet': 'I29', 'hayir': 'J29'},
      'checklist_3': <String, String>{'evet': 'I31', 'hayir': 'J31'},
      'checklist_4': <String, String>{'evet': 'I33', 'hayir': 'J33'},
      'checklist_5': <String, String>{'evet': 'I35', 'hayir': 'J35'},
      'checklist_6': <String, String>{'evet': 'I37', 'hayir': 'J37'},
      'checklist_7': <String, String>{'evet': 'I39', 'hayir': 'J39'},
      'checklist_8': <String, String>{'evet': 'I41', 'hayir': 'J41'},
      'checklist_9': <String, String>{'evet': 'R27', 'hayir': 'S27'},
      'checklist_10': <String, String>{'evet': 'R29', 'hayir': 'S29'},
      'checklist_11': <String, String>{'evet': 'R31', 'hayir': 'S31'},
      'checklist_12': <String, String>{'evet': 'R33', 'hayir': 'S33'},
      'checklist_13': <String, String>{'evet': 'R35', 'hayir': 'S35'},
      'checklist_14': <String, String>{'evet': 'R37', 'hayir': 'S37'},
      'checklist_15': <String, String>{'evet': 'R39', 'hayir': 'S39'},
      'checklist_16': <String, String>{'evet': 'R41', 'hayir': 'S41'},
    },
  };

  /// Safely parses dynamic date input (DateTime, String, null) into a DateTime object
  static DateTime parseDateTime(dynamic input, {DateTime? fallback}) {
    if (input == null) return fallback ?? DateTime.now();
    if (input is DateTime) return input;

    final String str = input.toString().trim();
    if (str.isEmpty) return fallback ?? DateTime.now();

    try {
      if (str.contains('.')) {
        final List<String> parts = str.split('.');
        if (parts.length == 3) {
          final int p1 = int.parse(parts[0]);
          final int p2 = int.parse(parts[1]);
          final int p3 = int.parse(parts[2]);
          if (p3 > 1000) {
            return DateTime(p3, p2, p1);
          } else if (p1 > 1000) {
            return DateTime(p1, p2, p3);
          }
        }
      } else if (str.contains('-')) {
        final DateTime? parsed = DateTime.tryParse(str);
        if (parsed != null) return parsed;
      }
    } catch (_) {}

    final DateTime? parsedIso = DateTime.tryParse(str);
    if (parsedIso != null) return parsedIso;

    return fallback ?? DateTime.now();
  }

  /// Formats dynamic date input (DateTime, String, null) safely to DD.MM.YYYY string
  static String formatDateDisplay(dynamic dateInput, {DateTime? fallback}) {
    if (dateInput == null) {
      final DateTime dt = fallback ?? DateTime.now();
      final String day = dt.day.toString().padLeft(2, '0');
      final String month = dt.month.toString().padLeft(2, '0');
      return '$day.$month.${dt.year}';
    }
    if (dateInput is DateTime) {
      final String day = dateInput.day.toString().padLeft(2, '0');
      final String month = dateInput.month.toString().padLeft(2, '0');
      return '$day.$month.${dateInput.year}';
    }
    final String str = dateInput.toString().trim();
    if (str.isEmpty) {
      final DateTime dt = fallback ?? DateTime.now();
      final String day = dt.day.toString().padLeft(2, '0');
      final String month = dt.month.toString().padLeft(2, '0');
      return '$day.$month.${dt.year}';
    }
    if (RegExp(r'^\d{1,2}\.\d{1,2}\.\d{4}$').hasMatch(str)) {
      return str;
    }
    final DateTime dt = parseDateTime(dateInput, fallback: fallback);
    final String day = dt.day.toString().padLeft(2, '0');
    final String month = dt.month.toString().padLeft(2, '0');
    return '$day.$month.${dt.year}';
  }

  /// Removes invalid OS filename characters
  static String sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[\\/*?:"<>|]'), '_');
  }

  /// Sanitizes formula string by translating Turkish function names to English
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

  /// Returns cell mapping dictionary for given transformer type
  static Map<String, Map<String, String>> cellMappingForType(String type) {
    final String normType = type.toLowerCase().trim();
    if (normType.contains('kuru')) {
      return typeCellMapping['kuru_tip'] ?? typeCellMapping['hermetik']!;
    } else if (normType.contains('gt') || normType.contains('tank')) {
      return typeCellMapping['gt'] ?? typeCellMapping['hermetik']!;
    }
    return typeCellMapping['hermetik']!;
  }

  /// Normalizes sheet name for comparison
  static String normalizeSheetName(String name) {
    return name.trim().toLowerCase();
  }

  /// Converts a date string or DateTime into Excel serial date number (epoch: 1899-12-30)
  static double? dateToExcelSerial(dynamic dateInput) {
    if (dateInput == null) return null;
    try {
      final DateTime dObj = parseDateTime(dateInput);
      final DateTime epoch = DateTime(1899, 12, 30);
      return dObj.difference(epoch).inDays.toDouble();
    } catch (_) {}
    return null;
  }
}
