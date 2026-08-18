import 'package:flutter/services.dart';
import '../../utils/decimal_comma_input_formatter.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/report_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/photo_picker_widget.dart';
import '../../widgets/qr_scanner_dialog.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _currentStepIndex = 0;
  bool _isAutoSaving = false;

  // Step 1: Genel Bilgiler Controllers
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _trafoLabelController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _reportDateController = TextEditingController();
  final TextEditingController _testDateController = TextEditingController();
  final TextEditingController _operatorNameController = TextEditingController();
  final TextEditingController _deviceModelController = TextEditingController();
  final TextEditingController _deviceSerialController = TextEditingController();
  final TextEditingController _operatorTitleController = TextEditingController();

  // Step 2: Etiket Bilgileri Controllers
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _powerController = TextEditingController();
  final TextEditingController _voltageController = TextEditingController();
  final TextEditingController _serialNoController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _connectionGroupController = TextEditingController();
  final TextEditingController _tapInfo1Controller = TextEditingController();
  final TextEditingController _tapInfo2Controller = TextEditingController();
  final TextEditingController _tapInfo3Controller = TextEditingController();
  final TextEditingController _shortCircuitImpController = TextEditingController();
  final TextEditingController _oilBrandController = TextEditingController();
  final TextEditingController _oilWeightController = TextEditingController();

  // Step 4: Sargı Ölçümleri Controllers
  final TextEditingController _ogRabController = TextEditingController();
  final TextEditingController _ogRbcController = TextEditingController();
  final TextEditingController _ogRcaController = TextEditingController();
  final TextEditingController _agRanController = TextEditingController();
  final TextEditingController _agRbnController = TextEditingController();
  final TextEditingController _agRcnController = TextEditingController();
  final TextEditingController _agRabController = TextEditingController();
  final TextEditingController _agRbcController = TextEditingController();
  final TextEditingController _agRcaController = TextEditingController();

  // Step 5: İzolasyon Controllers
  final TextEditingController _isoTempController = TextEditingController();
  final TextEditingController _isoHumidityController = TextEditingController();
  final TextEditingController _isoOgGndController = TextEditingController();
  final TextEditingController _isoAgGndController = TextEditingController();
  final TextEditingController _isoOgAgController = TextEditingController();
  final TextEditingController _isoCoreGndController = TextEditingController();

  // Step 6: TTR & Toprak Controllers
  final TextEditingController _ttrNominalController = TextEditingController();
  final TextEditingController _ttrTap1AController = TextEditingController();
  final TextEditingController _ttrTap1BController = TextEditingController();
  final TextEditingController _ttrTap1CController = TextEditingController();
  final TextEditingController _ttrTap2AController = TextEditingController();
  final TextEditingController _ttrTap2BController = TextEditingController();
  final TextEditingController _ttrTap2CController = TextEditingController();
  final TextEditingController _ttrTap3AController = TextEditingController();
  final TextEditingController _ttrTap3BController = TextEditingController();
  final TextEditingController _ttrTap3CController = TextEditingController();
  final TextEditingController _ttrTap4AController = TextEditingController();
  final TextEditingController _ttrTap4BController = TextEditingController();
  final TextEditingController _ttrTap4CController = TextEditingController();
  final TextEditingController _ttrTap5AController = TextEditingController();
  final TextEditingController _ttrTap5BController = TextEditingController();
  final TextEditingController _ttrTap5CController = TextEditingController();

  final TextEditingController _groundTrafoBodyController = TextEditingController();
  final TextEditingController _groundNeutralController = TextEditingController();
  final TextEditingController _groundTankController = TextEditingController();
  final TextEditingController _groundOgLightningController = TextEditingController();
  final TextEditingController _groundPanelController = TextEditingController();
  final TextEditingController _groundFenceController = TextEditingController();

  // Step 7: Kesici Controllers
  final TextEditingController _breakerBrandController = TextEditingController();
  final TextEditingController _breakerModelController = TextEditingController();
  final TextEditingController _breakerSerialController = TextEditingController();
  final TextEditingController _breakerYearController = TextEditingController();
  final TextEditingController _breakerRatedCurrentController = TextEditingController();
  final TextEditingController _breakerVoltageController = TextEditingController();
  final TextEditingController _breakerMotorVoltageController = TextEditingController();
  final TextEditingController _breakerCoilVoltageController = TextEditingController();
  final TextEditingController _breakerContactController = TextEditingController();
  final TextEditingController _breakerOpenController = TextEditingController();
  final TextEditingController _breakerCloseController = TextEditingController();
  final TextEditingController _breakerDiffController = TextEditingController();
  final TextEditingController _breakerIsoGndController = TextEditingController();
  final TextEditingController _breakerNotesController = TextEditingController();


  // Step 9: Yağ Testi Controllers
  final TextEditingController _oilBreakdownVoltageController = TextEditingController();
  final TextEditingController _oilWaterContentController = TextEditingController();

  // Step 11: Özet Controller
  final TextEditingController _summaryTextController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  @override
  void dispose() {
    _customerController.dispose();
    _trafoLabelController.dispose();
    _addressController.dispose();
    _reportDateController.dispose();
    _testDateController.dispose();
    _operatorNameController.dispose();
    _deviceModelController.dispose();
    _deviceSerialController.dispose();
    _operatorTitleController.dispose();

    _brandController.dispose();
    _powerController.dispose();
    _voltageController.dispose();
    _serialNoController.dispose();
    _yearController.dispose();
    _connectionGroupController.dispose();
    _tapInfo1Controller.dispose();
    _tapInfo2Controller.dispose();
    _tapInfo3Controller.dispose();
    _shortCircuitImpController.dispose();
    _oilBrandController.dispose();
    _oilWeightController.dispose();

    _ogRabController.dispose();
    _ogRbcController.dispose();
    _ogRcaController.dispose();
    _agRanController.dispose();
    _agRbnController.dispose();
    _agRcnController.dispose();
    _agRabController.dispose();
    _agRbcController.dispose();
    _agRcaController.dispose();

    _isoTempController.dispose();
    _isoHumidityController.dispose();
    _isoOgGndController.dispose();
    _isoAgGndController.dispose();
    _isoOgAgController.dispose();
    _isoCoreGndController.dispose();

    _ttrNominalController.dispose();
    _ttrTap1AController.dispose();
    _ttrTap1BController.dispose();
    _ttrTap1CController.dispose();
    _ttrTap2AController.dispose();
    _ttrTap2BController.dispose();
    _ttrTap2CController.dispose();
    _ttrTap3AController.dispose();
    _ttrTap3BController.dispose();
    _ttrTap3CController.dispose();
    _ttrTap4AController.dispose();
    _ttrTap4BController.dispose();
    _ttrTap4CController.dispose();
    _ttrTap5AController.dispose();
    _ttrTap5BController.dispose();
    _ttrTap5CController.dispose();

    _groundTrafoBodyController.dispose();
    _groundNeutralController.dispose();
    _groundTankController.dispose();
    _groundOgLightningController.dispose();
    _groundPanelController.dispose();
    _groundFenceController.dispose();
    _breakerBrandController.dispose();
    _breakerModelController.dispose();
    _breakerSerialController.dispose();
    _breakerYearController.dispose();
    _breakerRatedCurrentController.dispose();
    _breakerVoltageController.dispose();
    _breakerMotorVoltageController.dispose();
    _breakerCoilVoltageController.dispose();
    _breakerContactController.dispose();
    _breakerOpenController.dispose();
    _breakerCloseController.dispose();
    _breakerDiffController.dispose();
    _breakerIsoGndController.dispose();
    _breakerNotesController.dispose();


    _oilBreakdownVoltageController.dispose();
    _oilWaterContentController.dispose();

    _summaryTextController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final ReportService reportService = Provider.of<ReportService>(context, listen: false);
    final Report? report = reportService.activeReport;
    if (report == null) return;
    final Map<String, dynamic> data = report.dataJson;

    setState(() {
      _customerController.text = report.customerName;
      _trafoLabelController.text = report.trafoLabel;
      _addressController.text = data['address']?.toString() ?? data['location']?.toString() ?? '';

      _reportDateController.text = data['report_date']?.toString() ?? '';
      _testDateController.text = data['test_date']?.toString() ?? '';
      _operatorNameController.text = data['operator_name']?.toString() ?? '';
      _deviceModelController.text = data['device_model']?.toString() ?? '';
      _deviceSerialController.text = data['device_serial']?.toString() ?? '';
      _operatorTitleController.text = data['operator_title']?.toString() ?? '';

      _brandController.text = data['brand']?.toString() ?? '';
      _powerController.text = data['power_kva']?.toString() ?? '';
      _voltageController.text = data['voltage']?.toString() ?? '';
      _serialNoController.text = data['serial_no']?.toString() ?? '';
      _yearController.text = data['manufacture_year']?.toString() ?? '';
      _connectionGroupController.text = data['connection_group']?.toString() ?? '';
      _tapInfo1Controller.text = data['tap_info_1']?.toString() ?? '';
      _tapInfo2Controller.text = data['tap_info_2']?.toString() ?? '';
      _tapInfo3Controller.text = data['tap_info_3']?.toString() ?? '';
      _shortCircuitImpController.text = data['short_circuit_imp_pct']?.toString() ?? '';
      _oilBrandController.text = data['oil_brand']?.toString() ?? '';
      _oilWeightController.text = data['oil_weight']?.toString() ?? '';

      // Og Sargı
      _ogRabController.text = data['og_rab']?.toString() ?? '';
      _ogRbcController.text = data['og_rbc']?.toString() ?? '';
      _ogRcaController.text = data['og_rca']?.toString() ?? '';

      // Ag Sargı
      _agRanController.text = data['ag_ran']?.toString() ?? '';
      _agRbnController.text = data['ag_rbn']?.toString() ?? '';
      _agRcnController.text = data['ag_rcn']?.toString() ?? '';
      _agRabController.text = data['ag_rab']?.toString() ?? '';
      _agRbcController.text = data['ag_rbc']?.toString() ?? '';
      _agRcaController.text = data['ag_rca']?.toString() ?? '';

      // İzolasyon
      _isoTempController.text = data['iso_temp']?.toString() ?? '';
      _isoHumidityController.text = data['iso_humidity']?.toString() ?? '';
      _isoOgGndController.text = data['iso_og_gnd']?.toString() ?? '';
      _isoAgGndController.text = data['iso_ag_gnd']?.toString() ?? '';
      _isoOgAgController.text = data['iso_og_ag']?.toString() ?? '';
      _isoCoreGndController.text = data['iso_core_gnd']?.toString() ?? '';

      // TTR
      _ttrNominalController.text = data['ttr_nominal']?.toString() ?? '';
      _ttrTap1AController.text = data['ttr_tap1_a']?.toString() ?? '';
      _ttrTap1BController.text = data['ttr_tap1_b']?.toString() ?? '';
      _ttrTap1CController.text = data['ttr_tap1_c']?.toString() ?? '';
      _ttrTap2AController.text = data['ttr_tap2_a']?.toString() ?? '';
      _ttrTap2BController.text = data['ttr_tap2_b']?.toString() ?? '';
      _ttrTap2CController.text = data['ttr_tap2_c']?.toString() ?? '';
      _ttrTap3AController.text = data['ttr_tap3_a']?.toString() ?? '';
      _ttrTap3BController.text = data['ttr_tap3_b']?.toString() ?? '';
      _ttrTap3CController.text = data['ttr_tap3_c']?.toString() ?? '';
      _ttrTap4AController.text = data['ttr_tap4_a']?.toString() ?? '';
      _ttrTap4BController.text = data['ttr_tap4_b']?.toString() ?? '';
      _ttrTap4CController.text = data['ttr_tap4_c']?.toString() ?? '';
      _ttrTap5AController.text = data['ttr_tap5_a']?.toString() ?? '';
      _ttrTap5BController.text = data['ttr_tap5_b']?.toString() ?? '';
      _ttrTap5CController.text = data['ttr_tap5_c']?.toString() ?? '';

      // Grounding
      _groundTrafoBodyController.text = data['ground_r_trafo_body']?.toString() ?? data['ground_trafo_body']?.toString() ?? '';
      _groundNeutralController.text = data['ground_r_neutral']?.toString() ?? data['ground_neutral']?.toString() ?? '';
      _groundTankController.text = data['ground_r_tank']?.toString() ?? data['ground_tank']?.toString() ?? '';
      _groundOgLightningController.text = data['ground_r_og_lightning']?.toString() ?? data['ground_og_lightning']?.toString() ?? '';
      _groundPanelController.text = data['ground_r_panel']?.toString() ?? data['ground_panel']?.toString() ?? '';
      _groundFenceController.text = data['ground_r_fence']?.toString() ?? data['ground_fence']?.toString() ?? '';

      // Breaker
      final Map<dynamic, dynamic> br = data['breaker'] as Map? ?? <dynamic, dynamic>{};
      _breakerBrandController.text = data['breaker_brand']?.toString() ?? '';
      _breakerModelController.text = data['breaker_model']?.toString() ?? '';
      _breakerSerialController.text = data['breaker_serial_no']?.toString() ?? '';
      _breakerYearController.text = data['breaker_year']?.toString() ?? '';
      _breakerRatedCurrentController.text = data['breaker_rated_current']?.toString() ?? '';
      _breakerVoltageController.text = data['breaker_voltage']?.toString() ?? '';
      _breakerMotorVoltageController.text = data['breaker_motor_voltage']?.toString() ?? '';
      _breakerCoilVoltageController.text = data['breaker_coil_voltage']?.toString() ?? '';
      _breakerContactController.text = data['breaker_contact_r']?.toString() ?? br['contact_resistance']?.toString() ?? '';
      _breakerOpenController.text = data['breaker_timing_open']?.toString() ?? br['open_time']?.toString() ?? '';
      _breakerCloseController.text = data['breaker_timing_close']?.toString() ?? br['close_time']?.toString() ?? '';
      _breakerDiffController.text = data['breaker_phase_diff']?.toString() ?? br['phase_diff']?.toString() ?? '';
      _breakerIsoGndController.text = data['breaker_iso_r_gnd']?.toString() ?? '';
      _breakerNotesController.text = data['breaker_notes']?.toString() ?? '';


      // Oil Test
      _oilBreakdownVoltageController.text = data['oil_test_breakdown_voltage']?.toString() ?? '';
      _oilWaterContentController.text = data['oil_test_water_content']?.toString() ?? '';

      // Summary & Notes
      _summaryTextController.text = data['summary_text']?.toString() ?? '';
      _notesController.text = data['notes']?.toString() ?? data['notes_text']?.toString() ?? 'NOTLAR : Trafonun, trafo odasının, hücre odasının, trafo koruma hücresinin, kesicinin test, kontrol ve temizliği yapıldı. Test sonuçlarının değerlendirilmesi kapak sayfasında yapılmıştır.';

      _currentStepIndex = report.currentStep;
    });

    _autoSetTankMark(report.transformerType);
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    if (data['dc_redresor_voltage'] == null) {
      service.updateField('dc_redresor_voltage', '24 VDC');
    }
  }

  void _autoSetTankMark(String type) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final String normType = type.toLowerCase().trim();

    if (normType == 'hermetik') {
      service.updateField('tank_mark_hermetik', 'ü');
      service.updateField('tank_mark_gt', null);
      service.updateField('tank_mark_kuru', null);
    } else if (normType == 'gt') {
      service.updateField('tank_mark_gt', 'ü');
      service.updateField('tank_mark_hermetik', null);
      service.updateField('tank_mark_kuru', null);
    } else if (normType == 'kuru_tip') {
      service.updateField('tank_mark_kuru', 'ü');
      service.updateField('tank_mark_hermetik', null);
      service.updateField('tank_mark_gt', null);
    }
  }

  Future<bool> _onWillPop() async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Formdan Çık', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text('Kaydedilmemiş değişiklikleriniz kaybolabilir. Ayrılmak istediğinizden emin misiniz?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kal'),
          ),
          TextButton(
            onPressed: () {
              final ReportService reportService = Provider.of<ReportService>(context, listen: false);
              reportService.clearActiveReport();
              Navigator.of(context).pop(true);
            },
            child: const Text('Çık', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  Future<void> _simulateQrScan() async {
    final String? scannedCode = await QrScannerDialog.scan(context);
    if (scannedCode != null && scannedCode.trim().isNotEmpty && mounted) {
      final String code = scannedCode.trim();

      // 1. JSON parse
      if (code.startsWith('{') && code.endsWith('}')) {
        try {
          final Map<String, dynamic> jsonMap = jsonDecode(code) as Map<String, dynamic>;
          final Map<String, String> parsed = <String, String>{};

          if (jsonMap.containsKey('brand')) parsed['brand'] = jsonMap['brand'].toString();
          if (jsonMap.containsKey('power_kva') || jsonMap.containsKey('power')) {
            parsed['power_kva'] = (jsonMap['power_kva'] ?? jsonMap['power']).toString();
          }
          if (jsonMap.containsKey('voltage')) parsed['voltage'] = jsonMap['voltage'].toString();
          if (jsonMap.containsKey('serial_no') || jsonMap.containsKey('serial')) {
            parsed['serial_no'] = (jsonMap['serial_no'] ?? jsonMap['serial']).toString();
          }
          if (jsonMap.containsKey('manufacture_year') || jsonMap.containsKey('year')) {
            parsed['manufacture_year'] = (jsonMap['manufacture_year'] ?? jsonMap['year']).toString();
          }
          if (jsonMap.containsKey('connection_group') || jsonMap.containsKey('connection')) {
            parsed['connection_group'] = (jsonMap['connection_group'] ?? jsonMap['connection']).toString();
          }
          if (jsonMap.containsKey('oil_weight') || jsonMap.containsKey('oil')) {
            parsed['oil_weight'] = (jsonMap['oil_weight'] ?? jsonMap['oil']).toString();
          }

          if (parsed.isNotEmpty) {
            _applyParsedQrFields(parsed);
            return;
          }
        } catch (_) {}
      }

      // 2. Key-Value Regex parse (flexible spacing & concatenated texts)
      final Map<String, RegExp> patterns = <String, RegExp>{
        'brand': RegExp(
          r'(?:Brand|Marka|Manufacturer|Üretici)\s*:?\s*([A-Za-z0-9_\-\s]+?)(?=(?:Rated|Power|Voltage|Serial|Seri|Year|İmal|Vector|Connection|Bağlantı|[A-Z][a-zA-Z\s]+:|\s|$))',
          caseSensitive: false,
        ),
        'power_kva': RegExp(
          r'(?:Rated\s*Power|Power|kVA|Güç)\s*:?\s*([0-9]+(?:[.,][0-9]+)?)',
          caseSensitive: false,
        ),
        'voltage': RegExp(
          r'(?:Rated\s*Voltage|Voltage|Gerilim)\s*:?\s*([0-9.,]+(?:\s*/\s*[0-9.,]+)?(?:\s*k?V)?)',
          caseSensitive: false,
        ),
        'manufacture_year': RegExp(
          r'(?:Production\s*(?:Year|Date)?|Manufacture\s*(?:Year|Date)?|Year|İmal\s*(?:Yılı|Tarihi)?)\s*:?\s*(\d{2}\.\d{2}\.\d{4}|\d{4})',
          caseSensitive: false,
        ),
        'serial_no': RegExp(
          r'(?:Serial\s*(?:No)?|Seri\s*(?:No)?|S/N)\s*:?\s*([A-Za-z0-9_-]+)',
          caseSensitive: false,
        ),
        'connection_group': RegExp(
          r'(?:Vector\s*(?:Type|Group)?|Connection\s*(?:Group)?|Bağlantı\s*Grubu)\s*:?\s*([A-Za-z0-9]+?)(?=(?:Production|Rated|Serial|Year|Voltage|Marka|Güç|Gerilim|[A-Z][a-zA-Z\s]+:|\s|$))',
          caseSensitive: false,
        ),
        'oil_weight': RegExp(
          r'(?:Oil\s*Weight|Oil|Yağ\s*Ağırlığı|Yağ\s*Miktarı|Yağ)\s*:?\s*([0-9]+)',
          caseSensitive: false,
        ),
      };

      final Map<String, String> extracted = <String, String>{};
      patterns.forEach((String key, RegExp regex) {
        final Match? match = regex.firstMatch(code);
        if (match != null && match.groupCount >= 1) {
          final String matchedVal = match.group(1)!.trim();
          if (matchedVal.isNotEmpty) {
            extracted[key] = matchedVal;
          }
        }
      });

      if (extracted.isNotEmpty) {
        _applyParsedQrFields(extracted);
        return;
      }

      // 3. Fallback: Write raw string to serial_no if no fields matched
      _applyParsedQrFields(<String, String>{'serial_no': code});
    }
  }

  void _applyParsedQrFields(Map<String, String> fields) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);

    setState(() {
      if (fields.containsKey('brand')) {
        _brandController.text = fields['brand']!;
        service.updateField('brand', fields['brand']!);
      }
      if (fields.containsKey('power_kva')) {
        _powerController.text = fields['power_kva']!;
        service.updateField('power_kva', fields['power_kva']!);
      }
      if (fields.containsKey('voltage')) {
        _voltageController.text = fields['voltage']!;
        service.updateField('voltage', fields['voltage']!);
      }
      if (fields.containsKey('serial_no')) {
        _serialNoController.text = fields['serial_no']!;
        service.updateField('serial_no', fields['serial_no']!);
      }
      if (fields.containsKey('manufacture_year')) {
        _yearController.text = fields['manufacture_year']!;
        service.updateField('manufacture_year', fields['manufacture_year']!);
      }
      if (fields.containsKey('connection_group')) {
        _connectionGroupController.text = fields['connection_group']!;
        service.updateField('connection_group', fields['connection_group']!);
      }
      if (fields.containsKey('oil_weight')) {
        _oilWeightController.text = fields['oil_weight']!;
        service.updateField('oil_weight', fields['oil_weight']!);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'QR Kod Başarıyla Okundu: ${fields.length} alan dolduruldu',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _changeStep(int direction) async {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final int nextStep = _currentStepIndex + direction;

    setState(() {
      _isAutoSaving = true;
    });

    await service.updateStep(nextStep);

    setState(() {
      _currentStepIndex = nextStep;
      _isAutoSaving = false;
    });
  }

  Map<String, dynamic> _calculateWindingUnbalance() {
    final double? r = double.tryParse(_ogRabController.text.replaceAll(',', '.'));
    final double? s = double.tryParse(_ogRbcController.text.replaceAll(',', '.'));
    final double? t = double.tryParse(_ogRcaController.text.replaceAll(',', '.'));

    if (r == null || s == null || t == null) {
      return <String, dynamic>{'unbalance': null, 'status': 'Eksik'};
    }

    final double max = <double>[r, s, t].reduce((double a, double b) => a > b ? a : b);
    final double min = <double>[r, s, t].reduce((double a, double b) => a < b ? a : b);
    final double avg = (r + s + t) / 3.0;

    if (avg == 0) return <String, dynamic>{'unbalance': 0.0, 'status': 'UYGUN'};

    final double unbalance = ((max - min) / avg) * 100.0;
    final bool ok = unbalance <= 5.0;

    return <String, dynamic>{
      'unbalance': unbalance,
      'status': ok ? 'UYGUN' : 'UYGUN DEĞİL',
      'color': ok ? AppTheme.successColor : AppTheme.errorColor,
    };
  }

  Map<String, dynamic> _calculateTtrError() {
    final double? nom = double.tryParse(_ttrNominalController.text.replaceAll(',', '.'));
    final double? r = double.tryParse(_ttrTap1AController.text.replaceAll(',', '.'));
    final double? s = double.tryParse(_ttrTap1BController.text.replaceAll(',', '.'));
    final double? t = double.tryParse(_ttrTap1CController.text.replaceAll(',', '.'));

    if (nom == null || r == null || s == null || t == null || nom == 0) {
      return <String, dynamic>{'error': null, 'status': 'Eksik'};
    }

    final double errR = ((r - nom).abs() / nom) * 100.0;
    final double errS = ((s - nom).abs() / nom) * 100.0;
    final double errT = ((t - nom).abs() / nom) * 100.0;

    final double maxErr = <double>[errR, errS, errT].reduce((double a, double b) => a > b ? a : b);
    final bool ok = maxErr <= 0.5;

    return <String, dynamic>{
      'error': maxErr,
      'status': ok ? 'UYGUN' : 'UYGUN DEĞİL',
      'color': ok ? AppTheme.successColor : AppTheme.errorColor,
    };
  }

  void _generateSummaryProposal(Report report) {
    final Map<String, dynamic> windingEval = _calculateWindingUnbalance();
    final Map<String, dynamic> ttrEval = _calculateTtrError();

    final String unbalanceStr = windingEval['unbalance'] != null
        ? ' %${(windingEval['unbalance'] as double).toStringAsFixed(2)} faz dengesizliği (${windingEval['status']})'
        : '';

    final String ttrStr = ttrEval['error'] != null
        ? ' %${(ttrEval['error'] as double).toStringAsFixed(2)} maks TTR sapması (${ttrEval['status']})'
        : '';

    final String proposal =
        'Kontroller yapıldıktan sonra trafoya enerji verildi. OG Sargı direnç ölçümünde$unbalanceStr, Çevirme oranı (TTR) ölçümünde$ttrStr tespit edilmiştir. Mevcut şartların korunması halinde bir sonraki periyodik kontrol tarihine kadar trafonun kullanımı UYGUNDUR. Aksi belirtilmediği sürece periyodik kontroller 1 (bir) yıl sonra tekrarlanır.';

    setState(() {
      _summaryTextController.text = proposal;
    });

    final ReportService service = Provider.of<ReportService>(context, listen: false);
    service.updateField('summary_text', proposal);
  }

  void _showProfileWarningDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: <Widget>[
            Icon(Icons.person_off_outlined, color: AppTheme.warningColor),
            SizedBox(width: 8),
            Text('Profil Bilgisi Eksik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeReport() async {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final Report? report = service.activeReport;

    if (report == null) return;

    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    final User? currentUser = authService.currentUser;

    if (currentUser == null) {
      _showProfileWarningDialog('Oturum açmış kullanıcı bilgisi bulunamadı. Lütfen sisteme giriş yapın.');
      return;
    }

    final String opName = currentUser.fullName.trim();
    final String opTitle = (currentUser.operatorTitle ?? '').trim();
    final String? signaturePath = currentUser.signaturePath ?? await authService.getSignaturePath();

    if (opName.isEmpty || opTitle.isEmpty) {
      _showProfileWarningDialog(
        'Raporu kesinleştirmek için profilinizde Operatör Adı (Ad Soyad) ve Operatör Unvanı bilgilerinin eksiksiz girilmiş olması zorunludur.\n\n'
        'Lütfen profil sayfanızdan bilgilerinizi güncelleyin.',
      );
      return;
    }

    final bool hasBreaker = report.dataJson['has_breaker'] == true ||
        (report.dataJson['has_breaker'] == null && (report.dataJson['breaker_included'] == true || report.subType == 'kesici'));
    service.updateField('has_breaker', hasBreaker);
    service.updateField('breaker_included', hasBreaker);
    service.updateField('operator_name', opName);
    service.updateField('operator_title', opTitle);
    service.updateField('creator_display_name', '$opName ($opTitle)');

    if (_notesController.text.trim().isNotEmpty) {
      service.updateField('notes', _notesController.text.trim());
    }
    if (signaturePath != null && signaturePath.isNotEmpty) {
      service.updateField('signature_path', signaturePath);
    }

    try {
      final File? excelFile = await service.finalizeReport(
        report.id,
        currentUser: currentUser,
        signaturePath: signaturePath,
      );

      if (mounted && excelFile != null) {
        _showPostProductionDialog(report.title, report.id, excelFile);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel raporu üretilirken beklenmeyen bir durum oluştu.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final String rawErr = e.toString().replaceFirst('Exception: ', '');
        final String displayErr = rawErr.length > 500 ? '${rawErr.substring(0, 500)}...' : rawErr;
        showDialog<void>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: <Widget>[
                Icon(Icons.error_outline, color: AppTheme.errorColor),
                SizedBox(width: 8),
                Text('Excel Üretim Hatası', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: SelectableText(
                displayErr,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showPostProductionDialog(String reportTitle, String reportId, File excelFile) {
    showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 54),
            ),
            const SizedBox(height: 16),
            Text(
              'Rapor Başarıyla Kesinleştirildi!',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Excel (.xlsx) raporu şablon hücre haritasına göre üretildi ve cihazınızın yerel belgeler klasörüne kaydedildi.',
              style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Text(
                excelFile.path.split(Platform.pathSeparator).last,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final ReportService service = Provider.of<ReportService>(context, listen: false);
                await service.openExcelFile(excelFile);
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Excel\'i Aç'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final ReportService service = Provider.of<ReportService>(context, listen: false);
                await service.shareExcelFile(excelFile, reportTitle);
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text('Paylaş'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'Kapat',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textLight),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ReportService reportService = Provider.of<ReportService>(context);
    final Report? report = reportService.activeReport;

    if (report == null) {
      return const Scaffold(body: Center(child: Text('Aktif Rapor Bulunamadı.')));
    }

    final bool isKesici = report.dataJson['has_breaker'] == true ||
        (report.dataJson['has_breaker'] == null && (report.dataJson['breaker_included'] == true || report.subType == 'kesici'));
    final String type = report.transformerType.toLowerCase().trim();
    final bool isKuru = type == 'kuru_tip';

    // Steps list for Wizard Navigation
    final List<String> stepsList = <String>[
      'Genel Bilgiler',
      'Etiket Bilgileri',
      'Kontroller',
      'Sargı Ölçümleri',
      'İzolasyon',
      'TTR & Toprak',
      if (isKesici) 'Kesici',
      if (!isKuru) 'Yağ Raporu',
      'Fotoğraflar',
      'Özet & Bitir',
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(report.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.textDark,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: <Widget>[
                  if (_isAutoSaving) ...<Widget>[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primaryLight),
                    ),
                    const SizedBox(width: 8),
                    Text('Kaydediliyor...', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryLight)),
                  ] else ...<Widget>[
                    const Icon(Icons.cloud_done_outlined, color: AppTheme.successColor, size: 18),
                    const SizedBox(width: 6),
                    Text('Taslak Kaydedildi', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.successColor)),
                  ],
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            // Form Progress Bar
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: stepsList.length,
                itemBuilder: (BuildContext context, int index) {
                  final bool isCurrent = index == _currentStepIndex;
                  final bool isPassed = index < _currentStepIndex;
                  return Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          if (index < _currentStepIndex) {
                            _changeStep(index - _currentStepIndex);
                          }
                        },
                        child: Chip(
                          backgroundColor: isCurrent
                              ? AppTheme.primaryColor
                              : isPassed
                                  ? AppTheme.primaryColor.withOpacity(0.12)
                                  : Colors.white,
                          shape: const CircleBorder(),
                          side: BorderSide(
                            color: isCurrent
                                ? AppTheme.primaryColor
                                : isPassed
                                    ? AppTheme.primaryColor.withOpacity(0.2)
                                    : AppTheme.borderLight,
                          ),
                          label: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              color: isCurrent
                                  ? Colors.white
                                  : isPassed
                                      ? AppTheme.primaryColor
                                      : AppTheme.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        stepsList[index],
                        style: GoogleFonts.inter(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? AppTheme.primaryColor : AppTheme.textLight,
                          fontSize: 13,
                        ),
                      ),
                      if (index < stepsList.length - 1) ...<Widget>[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.borderLight),
                        const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
            ),

            // Form Content Step Switcher
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: _getStepWidget(report, stepsList[_currentStepIndex]),
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: _currentStepIndex > 0
                        ? () => _changeStep(-1)
                        : () => _onWillPop().then((bool exit) {
                              if (exit && mounted) Navigator.pop(context);
                            }),
                    child: Text(_currentStepIndex > 0 ? 'Geri' : 'İptal Et'),
                  ),
                  ElevatedButton(
                    onPressed: _currentStepIndex < stepsList.length - 1
                        ? () => _changeStep(1)
                        : _finalizeReport,
                    child: Text(
                      _currentStepIndex < stepsList.length - 1 ? 'Devam Et' : 'Raporu Kesinleştir',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStepWidget(Report report, String stepTitle) {
    switch (stepTitle) {
      case 'Genel Bilgiler':
        return _buildGeneralStep(report);
      case 'Etiket Bilgileri':
        return _buildLabelStep(report);
      case 'Kontroller':
        return _buildChecklistStep(report);
      case 'Sargı Ölçümleri':
        return _buildWindingStep(report);
      case 'İzolasyon':
        return _buildInsulationStep(report);
      case 'TTR & Toprak':
        return _buildTtrStep(report);
      case 'Kesici':
        return _buildBreakerStep(report);
      case 'Yağ Raporu':
        return _buildOilTestStep(report);
      case 'Fotoğraflar':
        return _buildPhotosStep(report);
      case 'Özet & Bitir':
        return _buildFinalizeStep(report);
      default:
        return _buildGeneralStep(report);
    }
  }

  // Step 1: Genel Bilgiler
  Widget _buildGeneralStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final AuthService authService = Provider.of<AuthService>(context);
    final User? currentUser = authService.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Genel Rapor Bilgileri', 'Rapor kapak sayfasında gösterilecek müşteri, lokasyon ve personel detayları.'),
        const SizedBox(height: 24),
        TextFormField(
          controller: _customerController,
          decoration: const InputDecoration(
            labelText: 'Müşteri / Şalt Sahası Adı *',
            hintText: 'Örn: ABC Tekstil Fabrikası',
            prefixIcon: Icon(Icons.business_outlined),
          ),
          onChanged: (String val) => service.updateField('customer_name', val),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _trafoLabelController,
          decoration: const InputDecoration(
            labelText: 'Trafo Etiketi / Tanımı *',
            hintText: 'Örn: TRAFO 1',
            prefixIcon: Icon(Icons.label_outlined),
          ),
          onChanged: (String val) => service.updateField('trafo_label', val),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Adres / Lokasyon *',
            hintText: 'Örn: OSB 2. Cadde No: 8 Bursa',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          onChanged: (String val) {
            service.updateField('address', val);
            service.updateField('location', val);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _reportDateController,
                decoration: const InputDecoration(
                  labelText: 'Rapor Tarihi (DD.MM.YYYY)',
                  hintText: '19.01.2024',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                onChanged: (String val) => service.updateField('report_date', val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _testDateController,
                decoration: const InputDecoration(
                  labelText: 'Test Tarihi (DD.MM.YYYY)',
                  hintText: '16.01.2024',
                  prefixIcon: Icon(Icons.edit_calendar_outlined),
                ),
                onChanged: (String val) => service.updateField('test_date', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Operatör Profil Özeti', 'Rapor kapak ve onay bilgileri oturum açan profilden otomatik alınır (Formda tekrar sorulmaz).'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      currentUser?.fullName.isNotEmpty == true ? currentUser!.fullName : 'Operatör Adı Girilmemiş',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Unvan: ${currentUser?.operatorTitle ?? "Belirtilmedi"}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Test Cihazı Bilgileri', 'Test sırasında kullanılan ikincil cihaz kayıtları.'),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _deviceModelController,
                decoration: const InputDecoration(
                  labelText: 'Test Cihaz Modeli',
                  hintText: 'Megger TTR300',
                ),
                onChanged: (String val) => service.updateField('device_model', val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _deviceSerialController,
                decoration: const InputDecoration(
                  labelText: 'Cihaz Seri No',
                  hintText: 'SN-4021-X',
                ),
                onChanged: (String val) => service.updateField('device_serial', val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 2: Etiket Bilgileri
  Widget _buildLabelStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final String type = report.transformerType.toLowerCase().trim();
    final bool isKuru = type == 'kuru_tip';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: _buildSectionHeader('Trafo Etiket Değerleri', 'Trafo plakasından okunan teknik etiket verileri.'),
            ),
            ElevatedButton.icon(
              onPressed: _simulateQrScan,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('QR Oku'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _brandController,
          decoration: const InputDecoration(
            labelText: 'Marka',
            hintText: 'Örn: BEST / ABB',
            prefixIcon: Icon(Icons.factory_outlined),
          ),
          onChanged: (String val) => service.updateField('brand', val),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _powerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Güç (kVA)',
                  suffixText: 'kVA',
                  hintText: 'Örn: 2000',
                ),
                onChanged: (String val) => service.updateField('power_kva', val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _voltageController,
                decoration: const InputDecoration(
                  labelText: 'Gerilim (V)',
                  hintText: '34500 / 400',
                ),
                onChanged: (String val) => service.updateField('voltage', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _serialNoController,
                decoration: const InputDecoration(
                  labelText: 'Seri No',
                  hintText: 'Örn: 1330',
                ),
                onChanged: (String val) => service.updateField('serial_no', val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'İmal Yılı',
                  hintText: 'Örn: 2013',
                ),
                onChanged: (String val) => service.updateField('manufacture_year', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _connectionGroupController,
                decoration: const InputDecoration(
                  labelText: 'Bağlantı Grubu',
                  hintText: 'Örn: Dyn11',
                ),
                onChanged: (String val) => service.updateField('connection_group', val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _shortCircuitImpController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Kısa Devre Empedansı (%)',
                  suffixText: '%',
                  hintText: 'Örn: 6.42',
                ),
                onChanged: (String val) => service.updateField('short_circuit_imp_pct', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('Kademe Değerleri (O11 / Q11 / S11)', 'Mevcut kademe pozisyonları.'),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _tapInfo1Controller,
                decoration: const InputDecoration(labelText: 'Kademe 1 (O11)', hintText: '6'),
                onChanged: (String val) => service.updateField('tap_info_1', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _tapInfo2Controller,
                decoration: const InputDecoration(labelText: 'Kademe 2 (Q11)', hintText: '4'),
                onChanged: (String val) => service.updateField('tap_info_2', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _tapInfo3Controller,
                decoration: const InputDecoration(labelText: 'Kademe 3 (S11)', hintText: '3'),
                onChanged: (String val) => service.updateField('tap_info_3', val),
              ),
            ),
          ],
        ),

        // Oil fields ONLY for hermetik & GT (HIDDEN for kuru_tip)
        if (!isKuru) ...<Widget>[
          const SizedBox(height: 24),
          _buildSectionHeader('İzolasyon Yağı Bilgileri', 'Hermetik ve GT trafolar için yağ markası ve ağırlığı.'),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _oilBrandController,
                  decoration: const InputDecoration(
                    labelText: 'Yağ Markası',
                    hintText: 'Örn: NYNAS',
                  ),
                  onChanged: (String val) => service.updateField('oil_brand', val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _oilWeightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Yağ Miktarı / Ağırlığı (kg)',
                    suffixText: 'kg',
                    hintText: 'Örn: 875',
                  ),
                  onChanged: (String val) => service.updateField('oil_weight', val),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Step 3: Physical Checklist
  Widget _buildChecklistStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final String type = report.transformerType.toLowerCase().trim();
    final String dcVoltage = (report.dataJson['dc_redresor_voltage']?.toString() ?? '24 VDC').toUpperCase().contains('110') ? '110 VDC' : '24 VDC';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader(
          'Fiziksel Gözlem ve Kontrol Listesi',
          'Seçtiğiniz Trafo Tipi (${type.toUpperCase()}) için tanımlı kontrol maddeleri aşağıda listelenmiştir.',
        ),
        const SizedBox(height: 20),
        _buildSwitchTile('Trafo Sıcaklık Kontrolü', 'checklist_1', report.dataJson),
        _buildSwitchTile('Yağ Seviyesi Kontrolü', 'checklist_2', report.dataJson),
        _buildSwitchTile('DC Redresör Kontrolü', 'checklist_3', report.dataJson),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
          child: Row(
            children: <Widget>[
              Text('DC Voltaj Seçimi: ', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('24 VDC'),
                selected: dcVoltage == '24 VDC',
                onSelected: (bool sel) {
                  if (sel) service.updateField('dc_redresor_voltage', '24 VDC');
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('110 VDC'),
                selected: dcVoltage == '110 VDC',
                onSelected: (bool sel) {
                  if (sel) service.updateField('dc_redresor_voltage', '110 VDC');
                },
              ),
            ],
          ),
        ),
        _buildSwitchTile('Basınç Açma', 'checklist_4', report.dataJson),
        _buildSwitchTile('Gaz Açma', 'checklist_5', report.dataJson),
        _buildSwitchTile('Termik Alarm', 'checklist_6', report.dataJson),
        _buildSwitchTile('Termik Açma', 'checklist_7', report.dataJson),
        _buildSwitchTile('İzolatör Kontrolü', 'checklist_8', report.dataJson),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        _buildSwitchTile('Trafo Temizliği', 'checklist_9', report.dataJson),
        _buildSwitchTile('Bina Temizliği', 'checklist_10', report.dataJson),
        _buildSwitchTile('Kablo Sıkılık Kontrolü', 'checklist_11', report.dataJson),
        _buildSwitchTile('Yağ Kaçağı Kontrolü', 'checklist_12', report.dataJson),
        _buildSwitchTile('Kademe Conta Kontrolü', 'checklist_13', report.dataJson),
        _buildSwitchTile('O.G Conta Kontrolü', 'checklist_14', report.dataJson),
        _buildSwitchTile('Kapak Conta Kontrolü', 'checklist_15', report.dataJson),
        _buildSwitchTile('A.G Conta Kontrolü', 'checklist_16', report.dataJson),
      ],
    );
  }

  // Step 4: Sargı Ölçümleri
  Widget _buildWindingStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final Map<String, dynamic> evaluation = _calculateWindingUnbalance();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('OG Sargı Direnç Ölçümleri (2A)', 'Primer OG sargılarının miliohm (mΩ) cinsinden faz-faz direnç değerlerini girin.'),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _ogRabController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'OG R-AB Direnci', suffixText: 'mΩ'),
                onChanged: (String val) {
                  service.updateField('og_rab', val);
                  service.updateField('winding_resistance.r_phase', val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ogRbcController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'OG R-BC Direnci', suffixText: 'mΩ'),
                onChanged: (String val) {
                  service.updateField('og_rbc', val);
                  service.updateField('winding_resistance.s_phase', val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ogRcaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'OG R-CA Direnci', suffixText: 'mΩ'),
                onChanged: (String val) {
                  service.updateField('og_rca', val);
                  service.updateField('winding_resistance.t_phase', val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildEvaluationCard(
          title: 'OG Faz Dengesizliği Değerlendirmesi',
          feedback: evaluation,
          limitText: 'Maksimum İzin Verilen Dengesizlik Sınırı: %5 (0.05)',
          valueText: evaluation['unbalance'] != null
              ? 'Maksimum Faz Dengesizliği: %${(evaluation['unbalance'] as double).toStringAsFixed(2)}'
              : 'Gözlemlenen: Değer Bekleniyor...',
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('AG Sargı Direnç Ölçümleri (Faz-Nötr ve Faz-Faz)', 'Sekonder AG sargılarının miliohm (mΩ) cinsinden dirençleri.'),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _agRanController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'AG R-AN (mΩ)'),
                onChanged: (String val) => service.updateField('ag_ran', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _agRbnController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'AG R-BN (mΩ)'),
                onChanged: (String val) => service.updateField('ag_rbn', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _agRcnController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'AG R-CN (mΩ)'),
                onChanged: (String val) => service.updateField('ag_rcn', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _agRabController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'AG R-AB (mΩ)'),
                onChanged: (String val) => service.updateField('ag_rab', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _agRbcController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'AG R-BC (mΩ)'),
                onChanged: (String val) => service.updateField('ag_rbc', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _agRcaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'AG R-CA (mΩ)'),
                onChanged: (String val) => service.updateField('ag_rca', val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 5: İzolasyon Testleri
  Widget _buildInsulationStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('İzolasyon Direnci Ölçümleri (Megohm)', 'Ortam sıcaklığı ve nem koşullarında sargı izolasyon dirençleri.'),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _isoTempController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Ortam Sıcaklığı (°C)', suffixText: '°C'),
                onChanged: (String val) {
                  service.updateField('iso_temp', val);
                  service.updateField('iso_temp_c', val);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _isoHumidityController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Nem Oranı (%)', suffixText: '%'),
                onChanged: (String val) => service.updateField('iso_humidity', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _isoOgGndController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
          decoration: const InputDecoration(labelText: 'OG - GND İzolasyon Direnci (MΩ)', suffixText: 'MΩ'),
          onChanged: (String val) => service.updateField('iso_og_gnd', val),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _isoAgGndController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
          decoration: const InputDecoration(labelText: 'AG - GND İzolasyon Direnci (MΩ)', suffixText: 'MΩ'),
          onChanged: (String val) => service.updateField('iso_ag_gnd', val),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _isoOgAgController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
          decoration: const InputDecoration(labelText: 'OG - AG İzolasyon Direnci (MΩ)', suffixText: 'MΩ'),
          onChanged: (String val) => service.updateField('iso_og_ag', val),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _isoCoreGndController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
          decoration: const InputDecoration(labelText: 'Nüve - GND İzolasyon Direnci (MΩ)', suffixText: 'MΩ'),
          onChanged: (String val) => service.updateField('iso_core_gnd', val),
        ),
      ],
    );
  }

  // Step 6: TTR & Toprak
  Widget _buildTtrStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final Map<String, dynamic> evaluation = _calculateTtrError();

    final double? groundVal = double.tryParse(_groundTrafoBodyController.text.replaceAll(',', '.'));
    final bool groundOk = groundVal != null && groundVal <= 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Çevirme Oranı (TTR) Ölçümleri', 'Nominal çevirme oranı ve faz ölçümleri.'),
        const SizedBox(height: 24),
        TextFormField(
          controller: _ttrNominalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
          decoration: const InputDecoration(labelText: 'Nominal Çevirme Oranı', hintText: 'Örn: 86.25'),
          onChanged: (String val) => service.updateField('ttr.nominal', val),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('Kademe 1 (Nominal) Çevirme Oranları', 'Faz bazlı TTR oranları.'),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _ttrTap1AController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Kademe 1 - A Fazı'),
                onChanged: (String val) {
                  service.updateField('ttr_tap1_a', val);
                  service.updateField('ttr.r_phase', val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ttrTap1BController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Kademe 1 - B Fazı'),
                onChanged: (String val) {
                  service.updateField('ttr_tap1_b', val);
                  service.updateField('ttr.s_phase', val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ttrTap1CController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Kademe 1 - C Fazı'),
                onChanged: (String val) {
                  service.updateField('ttr_tap1_c', val);
                  service.updateField('ttr.t_phase', val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildEvaluationCard(
          title: 'TTR Çevirme Oranı Hata Değerlendirmesi',
          feedback: evaluation,
          limitText: 'Maksimum İzin Verilen Hata Sınırı: ±%0.5 (0.005)',
          valueText: evaluation['error'] != null
              ? 'Maksimum Ölçülen Sapma: %${(evaluation['error'] as double).toStringAsFixed(2)}'
              : 'Gözlemlenen: Değer Bekleniyor...',
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('Topraklama Direnci Ölçümleri (Ohm)', 'Gövde, nötr ve şalt sahası topraklama dirençleri.'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _groundTrafoBodyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
          decoration: const InputDecoration(labelText: 'Trafo Gövde Topraklaması (Ω)', suffixText: 'Ω'),
          onChanged: (String val) {
            service.updateField('ground_r_trafo_body', val);
            service.updateField('ground_trafo_body', val);
            service.updateField('grounding.value', val);
          },
        ),
        if (groundVal != null)
          _buildInstantFeedbackRow(
            isOk: groundOk,
            label: 'Toprak Direnci Karşılaştırması',
            valueText: '$groundVal Ω (Limit: ≤ 2.0 Ω)',
          ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _groundNeutralController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Yıldız Noktası (Nötr) (Ω)'),
                onChanged: (String val) {
                  service.updateField('ground_r_neutral', val);
                  service.updateField('ground_neutral', val);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _groundTankController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Kazan / Tank Topraklaması (Ω)'),
                onChanged: (String val) {
                  service.updateField('ground_r_tank', val);
                  service.updateField('ground_tank', val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 7: Kesici
  Widget _buildBreakerStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);

    final double? contact = double.tryParse(_breakerContactController.text.replaceAll(',', '.'));
    final double? open = double.tryParse(_breakerOpenController.text.replaceAll(',', '.'));
    final double? close = double.tryParse(_breakerCloseController.text.replaceAll(',', '.'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Kesici Test Paketi', 'AG/OG Kesici kontak direnci ve açma/kapama süreleri.'),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _breakerBrandController,
                decoration: const InputDecoration(labelText: 'Kesici Markası', hintText: 'Örn: ABB / Siemens'),
                onChanged: (String val) => service.updateField('breaker_brand', val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _breakerModelController,
                decoration: const InputDecoration(labelText: 'Kesici Tipi / Modeli', hintText: 'Örn: VD4'),
                onChanged: (String val) => service.updateField('breaker_model', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _breakerSerialController,
                decoration: const InputDecoration(labelText: 'Seri Numarası', hintText: 'Örn: 2196'),
                onChanged: (String val) => service.updateField('breaker_serial_no', val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _breakerYearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'İmal Yılı', hintText: 'Örn: 2023'),
                onChanged: (String val) => service.updateField('breaker_year', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _breakerRatedCurrentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Anma Akımı (A)', suffixText: 'A', hintText: 'Örn: 630'),
                onChanged: (String val) => service.updateField('breaker_rated_current', val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _breakerVoltageController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Gerilim Seviyesi (V)', suffixText: 'V', hintText: 'Örn: 36000'),
                onChanged: (String val) => service.updateField('breaker_voltage', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _breakerMotorVoltageController,
                decoration: const InputDecoration(labelText: 'Motor Gerilimi', hintText: 'Örn: 220V DC / 110V DC'),
                onChanged: (String val) => service.updateField('breaker_motor_voltage', val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _breakerCoilVoltageController,
                decoration: const InputDecoration(labelText: 'Bobin Gerilimi', hintText: 'Örn: 220V DC'),
                onChanged: (String val) => service.updateField('breaker_coil_voltage', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Kesici Kontrolleri', '10 Adet Kesici Görsel, Temizlik ve Çalışma Kontrolü'),
        const SizedBox(height: 12),
        _buildSwitchTile('1. Kesici Görsel Kontrolü', 'breaker_control_visual', report.dataJson),
        _buildSwitchTile('2. Kesici Temizliği Kontrolü', 'breaker_control_cleanliness', report.dataJson),
        _buildSwitchTile('3. DC Redresör Kontrolü', 'breaker_control_dc_redresor', report.dataJson),
        _buildSwitchTile('4. Hücre Temizliği Kontrolü', 'breaker_control_cell_cleanliness', report.dataJson),
        _buildSwitchTile('5. İndikatör Kontrolü', 'breaker_control_indicator', report.dataJson),
        _buildSwitchTile('6. Bara Kontrolü', 'breaker_control_busbar', report.dataJson),
        _buildSwitchTile('7. Mekanik Kontrolü', 'breaker_control_mechanical', report.dataJson),
        _buildSwitchTile('8. Isıtıcı Kontrolü', 'breaker_control_heater', report.dataJson),
        _buildSwitchTile('9. Kablo Bağlantı Kontrolü', 'breaker_control_cable', report.dataJson),
        _buildSwitchTile('10. A.A Röle Kontrolü', 'breaker_control_relay', report.dataJson),
        const SizedBox(height: 24),
        _buildSectionHeader('Kesici Ölçümleri', 'İzolasyon direnci, kontak direnci ve açma/kapama süreleri'),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _breakerIsoGndController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'İzolasyon Direnci (GΩ)', suffixText: 'GΩ', hintText: 'Örn: 20000'),
                onChanged: (String val) => service.updateField('breaker_iso_r_gnd', val),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _breakerContactController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Kontak Direnci (µΩ)', suffixText: 'µΩ', hintText: 'Max 150 µΩ'),
                onChanged: (String val) {
                  service.updateField('breaker_contact_r', val);
                  service.updateField('breaker.contact_resistance', val);
                },
              ),
            ),
          ],
        ),
        if (contact != null)
          _buildInstantFeedbackRow(
            isOk: contact <= 150,
            label: 'Kontak Direnci Değerlendirmesi',
            valueText: '$contact µΩ (Limit: ≤ 150 µΩ)',
          ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _breakerOpenController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Açma Süresi (ms)', suffixText: 'ms', hintText: 'Max 80 ms'),
                onChanged: (String val) {
                  service.updateField('breaker_timing_open', val);
                  service.updateField('breaker.open_time', val);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _breakerCloseController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
                decoration: const InputDecoration(labelText: 'Kapama Süresi (ms)', suffixText: 'ms', hintText: 'Max 120 ms'),
                onChanged: (String val) {
                  service.updateField('breaker_timing_close', val);
                  service.updateField('breaker.close_time', val);
                },
              ),
            ),
          ],
        ),
        if (open != null || close != null) ...<Widget>[
          const SizedBox(height: 12),
          if (open != null)
            _buildInstantFeedbackRow(
              isOk: open < 80,
              label: 'Açma Süresi Değerlendirmesi',
              valueText: '$open ms (Limit: < 80 ms)',
            ),
          if (close != null)
            _buildInstantFeedbackRow(
              isOk: close < 120,
              label: 'Kapama Süresi Değerlendirmesi',
              valueText: '$close ms (Limit: < 120 ms)',
            ),
        ],
        const SizedBox(height: 20),
        Text('Kesici Sonuç Notu (ANA SAYFA KESİCİ)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _breakerNotesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Kesicinin test, kontrol ve temizliği yapıldı...',
          ),
          onChanged: (String val) {
            final ReportService service = Provider.of<ReportService>(context, listen: false);
            service.updateField('breaker_notes', val);
          },
        ),
      ],
    );
  }


  // Step 9: Yağ Testi (GT / Hermetik)
  Widget _buildOilTestStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final String type = report.transformerType.toLowerCase().trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('İzolasyon Yağ Test Raporu', 'İzolasyon yağının fiziksel ve kimyasal test sonuçları.'),
        const SizedBox(height: 24),
        if (type == 'gt') ...<Widget>[
          TextFormField(
            controller: _oilBreakdownVoltageController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
            decoration: const InputDecoration(labelText: 'Yağ Delinme Gerilimi (kV)', suffixText: 'kV', hintText: 'Örn: 65'),
            onChanged: (String val) => service.updateField('oil_test_breakdown_voltage', val),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _oilWaterContentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
            decoration: const InputDecoration(labelText: 'Yağ Su İhtivası (ppm)', suffixText: 'ppm', hintText: 'Örn: 15'),
            onChanged: (String val) => service.updateField('oil_test_water_content', val),
          ),
        ] else if (type == 'hermetik') ...<Widget>[
          _buildAlertText('Hermetik trafolarda yağ numunesi alınamadıysa dilekçe sayfasına yağ analiz kaydı işlenir.'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _oilBreakdownVoltageController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const <TextInputFormatter>[DecimalCommaInputFormatter()],
            decoration: const InputDecoration(labelText: 'Yağ Delinme Gerilimi (kV)', suffixText: 'kV'),
            onChanged: (String val) => service.updateField('oil_test_breakdown_voltage', val),
          ),
        ],
      ],
    );
  }

  // Step 10: Saha Fotoğrafları
  Widget _buildPhotosStep(Report report) {
    final bool isTestOnly = report.reportType == 'test';
    final ReportService service = Provider.of<ReportService>(context, listen: false);

    final dynamic labelPhoto = report.dataJson['photo_label'] ??
        (report.dataJson['photos'] is Map ? report.dataJson['photos']['photo_label'] : null);
    final dynamic beforePhoto = report.dataJson['photo_before'] ??
        (report.dataJson['photos'] is Map ? report.dataJson['photos']['photo_before'] : null);
    final dynamic afterPhoto = report.dataJson['photo_after'] ??
        (report.dataJson['photos'] is Map ? report.dataJson['photos']['photo_after'] : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Saha Fotoğrafları', 'Fotoğrafları doğrudan cihaz kamerasından çekebilir veya galeriden ekleyebilirsiniz.'),
        const SizedBox(height: 24),
        PhotoPickerWidget(
          label: 'Trafo Etiket / Plaka Fotoğrafı *',
          description: 'Marka, güç ve seri no okunabilen plaka resmi.',
          imagePath: labelPhoto?.toString(),
          isRequired: true,
          onPhotoSelected: (String? path) async {
            if (path != null && File(path).existsSync()) {
              await service.savePhotoLocally('photo_label', File(path));
            } else {
              await service.deletePhotoLocally('photo_label');
            }
          },
        ),
        if (!isTestOnly) ...<Widget>[
          PhotoPickerWidget(
            label: 'Bakım Öncesi Genel Görünüm *',
            description: 'Bakıma başlamadan önceki saha resmi.',
            imagePath: beforePhoto?.toString(),
            isRequired: true,
            onPhotoSelected: (String? path) async {
              if (path != null && File(path).existsSync()) {
                await service.savePhotoLocally('photo_before', File(path));
              } else {
                await service.deletePhotoLocally('photo_before');
              }
            },
          ),
          PhotoPickerWidget(
            label: 'Bakım Sonrası Genel Görünüm *',
            description: 'Temizlik ve sıkma bakımları bitmiş resmi.',
            imagePath: afterPhoto?.toString(),
            isRequired: true,
            onPhotoSelected: (String? path) async {
              if (path != null && File(path).existsSync()) {
                await service.savePhotoLocally('photo_after', File(path));
              } else {
                await service.deletePhotoLocally('photo_after');
              }
            },
          ),
        ],
      ],
    );
  }

  // Step 11: Özet & Raporu Bitir
  Widget _buildFinalizeStep(Report report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Rapor Özeti ve Son Değerlendirme', 'Kapak sayfasındaki A31 hücresine basılacak genel sonuç özeti.'),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('Sonuç Özeti Metni (KAPAK A31)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            TextButton.icon(
              onPressed: () => _generateSummaryProposal(report),
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: const Text('Otomatik Özet Öner'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _summaryTextController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Kontroller yapıldıktan sonra trafoya enerji verildi...',
          ),
          onChanged: (String val) {
            final ReportService service = Provider.of<ReportService>(context, listen: false);
            service.updateField('summary_text', val);
          },
        ),
        const SizedBox(height: 20),
        Text('Notlar (ANA SAYFA)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Trafonun, trafo odasının, hücre odasının, trafo koruma hücresinin, kesicinin test, kontrol ve temizliği yapıldı...',
          ),
          onChanged: (String val) {
            final ReportService service = Provider.of<ReportService>(context, listen: false);
            service.updateField('notes', val);
          },
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Rapor Künyesi', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const SizedBox(height: 16),
                _buildSummaryRow('Müşteri:', report.customerName.isEmpty ? '(Belirtilmedi)' : report.customerName),
                _buildSummaryRow('Trafo Tipi:', report.transformerType.toUpperCase()),
                _buildSummaryRow('Kapsam:', report.subType == 'kesici' ? 'Trafo + Kesici Bakımı' : 'Trafo Bakımı'),
                _buildSummaryRow('Rapor Tarihi:', report.dataJson['report_date']?.toString() ?? ''),
                _buildSummaryRow('Test Tarihi:', report.dataJson['test_date']?.toString() ?? ''),
                _buildSummaryRow('Test Cihazı:', '${report.dataJson['device_model'] ?? ''} (${report.dataJson['device_serial'] ?? ''})'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildAlertText('Raporu Kesinleştir butonuna bastığınızda orijinal Excel (.xlsx) şablonu doldurulacak ve yerel belgelerinize kaydedilecektir.'),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String key, Map<String, dynamic> data) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final bool val = data[key] == true;

    return SwitchListTile(
      title: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
      value: val,
      onChanged: (bool newVal) => service.updateField(key, newVal),
      activeColor: AppTheme.secondaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAlertText(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard({
    required String title,
    required Map<String, dynamic> feedback,
    required String limitText,
    required String valueText,
  }) {
    final String status = feedback['status'] as String;
    final bool hasData = feedback['unbalance'] != null || feedback['error'] != null;
    final Color color = hasData ? (feedback['color'] as Color) : Colors.grey;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(valueText, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(limitText, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstantFeedbackRow({
    required bool isOk,
    required String label,
    required String valueText,
  }) {
    final Color color = isOk ? AppTheme.successColor : AppTheme.errorColor;
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isOk ? 'UYGUN' : 'UYGUN DEĞİL',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textLight, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
