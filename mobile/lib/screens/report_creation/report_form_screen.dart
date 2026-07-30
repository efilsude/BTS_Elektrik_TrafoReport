import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _currentStepIndex = 0;
  bool _isAutoSaving = false;

  // Controllers for general inputs
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _operatorController = TextEditingController();
  final TextEditingController _deviceModelController = TextEditingController();
  final TextEditingController _deviceSerialController = TextEditingController();

  // Controllers for label specs
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _powerController = TextEditingController();
  final TextEditingController _voltageController = TextEditingController();
  final TextEditingController _serialNoController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _connectionGroupController = TextEditingController();

  // Controllers for Winding Resistance (YG / Primer)
  final TextEditingController _ygRController = TextEditingController();
  final TextEditingController _ygSController = TextEditingController();
  final TextEditingController _ygTController = TextEditingController();

  // Controllers for TTR (Turns Ratio)
  final TextEditingController _ttrNominalController = TextEditingController();
  final TextEditingController _ttrRController = TextEditingController();
  final TextEditingController _ttrSController = TextEditingController();
  final TextEditingController _ttrTController = TextEditingController();

  // Controllers for Grounding
  final TextEditingController _groundingController = TextEditingController();

  // Controllers for Breaker Module
  final TextEditingController _breakerContactController = TextEditingController();
  final TextEditingController _breakerOpenController = TextEditingController();
  final TextEditingController _breakerCloseController = TextEditingController();
  final TextEditingController _breakerDiffController = TextEditingController();

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
    _locationController.dispose();
    _operatorController.dispose();
    _deviceModelController.dispose();
    _deviceSerialController.dispose();
    _brandController.dispose();
    _powerController.dispose();
    _voltageController.dispose();
    _serialNoController.dispose();
    _yearController.dispose();
    _connectionGroupController.dispose();
    _ygRController.dispose();
    _ygSController.dispose();
    _ygTController.dispose();
    _ttrNominalController.dispose();
    _ttrRController.dispose();
    _ttrSController.dispose();
    _ttrTController.dispose();
    _groundingController.dispose();
    _breakerContactController.dispose();
    _breakerOpenController.dispose();
    _breakerCloseController.dispose();
    _breakerDiffController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final ReportService reportService = Provider.of<ReportService>(context, listen: false);
    final Report? report = reportService.activeReport;
    if (report == null) return;

    setState(() {
      _customerController.text = report.customerName;
      _locationController.text = report.dataJson['location']?.toString() ?? '';
      _operatorController.text = report.dataJson['operator_name']?.toString() ?? '';
      _deviceModelController.text = report.dataJson['device_model']?.toString() ?? '';
      _deviceSerialController.text = report.dataJson['device_serial']?.toString() ?? '';

      _brandController.text = report.dataJson['brand']?.toString() ?? '';
      _powerController.text = report.dataJson['power_kva']?.toString() ?? '';
      _voltageController.text = report.dataJson['voltage']?.toString() ?? '';
      _serialNoController.text = report.dataJson['serial_no']?.toString() ?? '';
      _yearController.text = report.dataJson['manufacture_year']?.toString() ?? '';
      _connectionGroupController.text = report.dataJson['connection_group']?.toString() ?? '';

      final Map<dynamic, dynamic> wr = report.dataJson['winding_resistance'] as Map? ?? <dynamic, dynamic>{};
      _ygRController.text = wr['r_phase']?.toString() ?? '';
      _ygSController.text = wr['s_phase']?.toString() ?? '';
      _ygTController.text = wr['t_phase']?.toString() ?? '';

      final Map<dynamic, dynamic> ttr = report.dataJson['ttr'] as Map? ?? <dynamic, dynamic>{};
      _ttrNominalController.text = ttr['nominal']?.toString() ?? '';
      _ttrRController.text = ttr['r_phase']?.toString() ?? '';
      _ttrSController.text = ttr['s_phase']?.toString() ?? '';
      _ttrTController.text = ttr['t_phase']?.toString() ?? '';

      final Map<dynamic, dynamic> grounding = report.dataJson['grounding'] as Map? ?? <dynamic, dynamic>{};
      _groundingController.text = grounding['value']?.toString() ?? '';

      final Map<dynamic, dynamic> br = report.dataJson['breaker'] as Map? ?? <dynamic, dynamic>{};
      _breakerContactController.text = br['contact_resistance']?.toString() ?? '';
      _breakerOpenController.text = br['open_time']?.toString() ?? '';
      _breakerCloseController.text = br['close_time']?.toString() ?? '';
      _breakerDiffController.text = br['phase_diff']?.toString() ?? '';

      _currentStepIndex = report.currentStep;
    });
  }

  // Handle Safe Exit Dialog (PRD §20)
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

  // QR scanner simulation dialog (PRD §21.2, Kabul #10)
  void _simulateQrScan() {
    showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: <Widget>[
            const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text('QR Kod Tara (Simülasyon)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Saha tabletinizdeki trafo etiket QR kodunu okutarak etiket bilgilerini hızlıca doldurabilirsiniz. Bir test şablonu seçin:'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              _populateLabelData(
                brand: 'ABB Transformers',
                power: '1600',
                voltage: '34500 / 400 V',
                serial: 'SN-ABB-99120',
                year: '2022',
                connection: 'Dyn11',
              );
              Navigator.pop(context);
            },
            child: const Text('ABB 1600kVA (2022)'),
          ),
          TextButton(
            onPressed: () {
              _populateLabelData(
                brand: 'Siemens Energy',
                power: '1250',
                voltage: '34500 / 400 V',
                serial: 'SN-SIE-12401',
                year: '2019',
                connection: 'Dyn11',
              );
              Navigator.pop(context);
            },
            child: const Text('Siemens 1250kVA (2019)'),
          ),
        ],
      ),
    );
  }

  void _populateLabelData({
    required String brand,
    required String power,
    required String voltage,
    required String serial,
    required String year,
    required String connection,
  }) {
    setState(() {
      _brandController.text = brand;
      _powerController.text = power;
      _voltageController.text = voltage;
      _serialNoController.text = serial;
      _yearController.text = year;
      _connectionGroupController.text = connection;
    });

    final ReportService service = Provider.of<ReportService>(context, listen: false);
    service.updateField('brand', brand);
    service.updateField('power_kva', power);
    service.updateField('voltage', voltage);
    service.updateField('serial_no', serial);
    service.updateField('manufacture_year', year);
    service.updateField('connection_group', connection);
  }

  // Immediate Save on Step Transition
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

  // Winding resistance calculations
  Map<String, dynamic> _calculateWindingUnbalance() {
    final double? r = double.tryParse(_ygRController.text);
    final double? s = double.tryParse(_ygSController.text);
    final double? t = double.tryParse(_ygTController.text);

    if (r == null || s == null || t == null) {
      return <String, dynamic>{'unbalance': null, 'status': 'Eksik'};
    }

    final double max = <double>[r, s, t].reduce((double a, double b) => a > b ? a : b);
    final double min = <double>[r, s, t].reduce((double a, double b) => a < b ? a : b);
    final double avg = (r + s + t) / 3.0;
    
    if (avg == 0) return <String, dynamic>{'unbalance': 0.0, 'status': 'UYGUN'};

    final double unbalance = ((max - min) / avg) * 100.0;
    final bool ok = unbalance <= 5.0; // PRD §2.5 limit: 5% unbalance

    return <String, dynamic>{
      'unbalance': unbalance,
      'status': ok ? 'UYGUN' : 'UYGUN DEĞİL',
      'color': ok ? AppTheme.successColor : AppTheme.errorColor,
    };
  }

  // TTR ratio check calculations
  Map<String, dynamic> _calculateTtrError() {
    final double? nom = double.tryParse(_ttrNominalController.text);
    final double? r = double.tryParse(_ttrRController.text);
    final double? s = double.tryParse(_ttrSController.text);
    final double? t = double.tryParse(_ttrTController.text);

    if (nom == null || r == null || s == null || t == null || nom == 0) {
      return <String, dynamic>{'error': null, 'status': 'Eksik'};
    }

    final double errR = ((r - nom).abs() / nom) * 100.0;
    final double errS = ((s - nom).abs() / nom) * 100.0;
    final double errT = ((t - nom).abs() / nom) * 100.0;

    final double maxErr = <double>[errR, errS, errT].reduce((double a, double b) => a > b ? a : b);
    final bool ok = maxErr <= 0.5; // PRD §2.5 TTR limit: ±0.5%

    return <String, dynamic>{
      'error': maxErr,
      'status': ok ? 'UYGUN' : 'UYGUN DEĞİL',
      'color': ok ? AppTheme.successColor : AppTheme.errorColor,
    };
  }

  // Finalize report and show Post-Production dialog (PRD §21.4)
  Future<void> _finalizeReport() async {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final Report? report = service.activeReport;

    if (report == null) return;

    // Check mandatory photos before finalization
    final bool isTestOnly = report.reportType == 'test';
    final dynamic hasLabelPhoto = report.dataJson['photo_label'];
    final dynamic hasBeforePhoto = report.dataJson['photo_before'];
    final dynamic hasAfterPhoto = report.dataJson['photo_after'];

    if (isTestOnly) {
      if (hasLabelPhoto == null) {
        _showPhotoWarningDialog('Etiket Fotoğrafı zorunludur.');
        return;
      }
    } else {
      if (hasLabelPhoto == null || hasBeforePhoto == null || hasAfterPhoto == null) {
        _showPhotoWarningDialog('Bakım raporu için Öncesi, Sonrası ve Etiket fotoğraflarının hepsi zorunludur.');
        return;
      }
    }

    final bool success = await service.finalizeReport(report.id);

    if (mounted && success) {
      _showPostProductionDialog(report.title);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapor kesinleştirilirken hata oluştu.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showPhotoWarningDialog(String message) {
    showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: <Widget>[
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            const SizedBox(width: 10),
            Text('Eksik Fotoğraflar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // Post-Production Screen (PRD §21.4): Open | Share | Print | Close
  void _showPostProductionDialog(String reportTitle) {
    showDialog<dynamic>(
      context: context,
      barrierDismissible: false, // Must select an action
      builder: (BuildContext context) => AlertDialog(
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
              'Excel raporu orijinal şablon biçimlendirmesiyle üretildi ve Rapor Havuzuna kaydedildi.',
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
                '$reportTitle.xlsx',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            
            // Native intents buttons
            ElevatedButton.icon(
              onPressed: () => _simulateIntent('Excel\'i Aç', 'Excel dosyası yerel ofis uygulaması ile açılıyor...'),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Excel\'i Aç'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _simulateIntent('Paylaş', 'Rapor paylaşma seçenekleri hazırlanıyor...'),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Paylaş'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _simulateIntent('Yazdır', 'Sistem yazdırma servisi aranıyor...'),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Yazdır'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Pop FormScreen to go back to Home
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

  void _simulateIntent(String label, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            const Icon(Icons.android_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.secondaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Camera capture simulation (PRD §10)
  void _simulatePhotoCapture(String photoKey, String label) {
    showModalBottomSheet<dynamic>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '$label Ekle',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _saveMockPhoto(photoKey, 'Kamera');
              },
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Kamerayı Aç'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _saveMockPhoto(photoKey, 'Galeri');
              },
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Galeriden Seç'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMockPhoto(String photoKey, String source) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    // Write mock placeholder
    service.updateField(photoKey, 'mock_photo_path_$photoKey');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$source kullanılarak fotoğraf başarıyla eklendi.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _deletePhoto(String photoKey) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    service.updateField(photoKey, null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fotoğraf kaldırıldı.'),
        backgroundColor: AppTheme.errorColor,
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

    final bool isKesici = report.subType == 'kesici';
    
    // Total steps calculation
    final List<String> stepsList = <String>[
      'Genel Bilgiler',
      'Etiket Bilgileri',
      'Kontroller',
      'Sargı Ölçümleri',
      'TTR & Toprak',
      if (isKesici) 'Kesici Testleri',
      'Fotoğraflar', // Added Step (Phase 3)
      'Raporu Bitir',
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
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
            // Auto-saving Indicator (PRD §8)
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
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: stepsList.length,
                itemBuilder: (BuildContext context, int index) {
                  final bool isCurrent = index == _currentStepIndex;
                  final bool isPassed = index < _currentStepIndex;
                  return Row(
                    children: <Widget>[
                      // Step dot
                      GestureDetector(
                        onTap: () {
                          // Allow navigation by clicking dots
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
                      // Step text label
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
                    child: _getStepWidget(report),
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
                  // Back button
                  OutlinedButton(
                    onPressed: _currentStepIndex > 0 ? () => _changeStep(-1) : () => _onWillPop().then((bool exit) {
                      if (exit && mounted) Navigator.pop(context);
                    }),
                    child: Text(_currentStepIndex > 0 ? 'Geri' : 'İptal Et'),
                  ),
                  
                  // Next / Finalize button
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

  // Render proper wizard step form
  Widget _getStepWidget(Report report) {
    final bool isKesici = report.subType == 'kesici';
    
    // We adjust the step index map dynamically
    final List<int> stepMapping = <int>[
      0, // Genel Bilgiler
      1, // Etiket Bilgileri
      2, // Kontroller
      3, // Sargı Ölçümleri
      4, // TTR & Toprak
      if (isKesici) 5, // Kesici Testleri
      isKesici ? 6 : 5, // Fotoğraflar
      isKesici ? 7 : 6, // Raporu Bitir
    ];

    final int activeStep = stepMapping[_currentStepIndex];

    switch (activeStep) {
      case 0:
        return _buildGeneralStep(report);
      case 1:
        return _buildLabelStep(report);
      case 2:
        return _buildChecklistStep(report);
      case 3:
        return _buildWindingStep(report);
      case 4:
        return _buildTtrStep(report);
      case 5:
        if (isKesici) {
          return _buildBreakerStep(report);
        }
        return _buildPhotosStep(report);
      case 6:
        if (isKesici) {
          return _buildPhotosStep(report);
        }
        return _buildFinalizeStep(report);
      case 7:
        return _buildFinalizeStep(report);
      default:
        return _buildGeneralStep(report);
    }
  }

  // Step 0: General Customer info
  Widget _buildGeneralStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Genel Rapor Bilgileri', 'Rapor kapak sayfasında gösterilecek müşteri ve lokasyon detayları.'),
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
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Lokasyon / Şehir',
            hintText: 'Örn: Bursa OSB 2. Cadde',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          onChanged: (String val) => service.updateField('location', val),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _operatorController,
          decoration: const InputDecoration(
            labelText: 'Testi Yapan Teknisyen',
            hintText: 'Örn: Ahmet Teknisyen',
            prefixIcon: Icon(Icons.person_outline),
          ),
          onChanged: (String val) => service.updateField('operator_name', val),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Test Cihazı Bilgileri', 'Kapak sayfasında belirtilmesi zorunlu olan kalibrasyonlu cihaz bilgileri.'),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _deviceModelController,
                decoration: const InputDecoration(
                  labelText: 'Cihaz Modeli',
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

  // Step 1: Transformer specs from label
  Widget _buildLabelStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: _buildSectionHeader('Trafo Etiket Değerleri', 'Trafo plakasından okunan teknik etiket değerleri.'),
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
                  hintText: '34500 / 400 V',
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
                ),
                onChanged: (String val) => service.updateField('manufacture_year', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _connectionGroupController,
          decoration: const InputDecoration(
            labelText: 'Bağlantı Grubu',
            hintText: 'Örn: Dyn11',
          ),
          onChanged: (String val) => service.updateField('connection_group', val),
        ),
      ],
    );
  }

  // Step 2: Dynamic Checks Checklist (PRD §2.4, §7.2)
  Widget _buildChecklistStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final String type = report.transformerType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Fiziksel Gözlem Kontrolleri', 'Seçtiğiniz Trafo Tipi ile uyumlu alanlar dinamik olarak gösterilmektedir.'),
        const SizedBox(height: 24),

        // Shared Check: Temizlik
        _buildSwitchTile('Genel Temizlik ve Pas Kontrolü', 'shared_clean', report.dataJson),
        _buildSwitchTile('Bağlantı Klemensleri Sıkılık Kontrolü', 'shared_clamp', report.dataJson),

        // GT specific checks (Oil level, silica-gel, Buchholz)
        if (type == 'gt') ...<Widget>[
          const SizedBox(height: 16),
          _buildAlertText('Yağlı / Genleşme Tanklı Trafo Modülü Aktif'),
          const SizedBox(height: 8),
          _buildSwitchTile('Yağ Seviye Kontrolü (Genleşme Deposu)', 'oil_level', report.dataJson),
          _buildSwitchTile('Yağ Sızıntısı Kontrolü', 'oil_leak', report.dataJson),
          _buildSwitchTile('Buchholz Rölesi Kablo & Sızıntı Kontrolü', 'buchholz', report.dataJson),
          _buildSwitchTile('Silika-Jel (Nem Alıcı) Durum Kontrolü', 'silica_gel', report.dataJson),
          _buildSwitchTile('Yağ Numunesi Alındı mı?', 'oil_sample', report.dataJson),
        ],

        // Hermetik specific checks (Pressure and Gas)
        if (type == 'hermetik') ...<Widget>[
          const SizedBox(height: 16),
          _buildAlertText('Hermetik Sızdırmaz Trafo Modülü Aktif'),
          const SizedBox(height: 8),
          _buildSwitchTile('Basınç Tahliye Valfi Testi', 'pressure_release', report.dataJson),
          _buildSwitchTile('Gaz Tahliye Ventili Sızdırmazlığı', 'gas_release', report.dataJson),
        ],

        // Kuru Tip specific checks (Fan, epoxy)
        if (type == 'kuru_tip') ...<Widget>[
          const SizedBox(height: 16),
          _buildAlertText('Kuru Tip Trafo Modülü Aktif (Yağ Kontrolleri Gizlendi)'),
          const SizedBox(height: 8),
          _buildSwitchTile('Fan ON/OFF Fonksiyon Testi', 'fan_on_off', report.dataJson),
          _buildSwitchTile('Epoksi Sargı Döküm Temizlik ve Çatlak Kontrolü', 'epoxy', report.dataJson),
          _buildSwitchTile('Termistör ve Sıcaklık Koruma Ünitesi', 'thermistor', report.dataJson),
        ],
      ],
    );
  }

  // Step 3: Winding Resistance Winding Test
  Widget _buildWindingStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final Map<String, dynamic> evaluation = _calculateWindingUnbalance();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('YG Sargı Direnç Testi', 'Primer YG sargılarının miliohm (mΩ) cinsinden direnç değerlerini girin.'),
        const SizedBox(height: 24),

        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _ygRController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'R Fazı Direnci',
                  suffixText: 'mΩ',
                ),
                onChanged: (String val) => service.updateField('winding_resistance.r_phase', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ygSController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'S Fazı Direnci',
                  suffixText: 'mΩ',
                ),
                onChanged: (String val) => service.updateField('winding_resistance.s_phase', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ygTController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'T Fazı Direnci',
                  suffixText: 'mΩ',
                ),
                onChanged: (String val) => service.updateField('winding_resistance.t_phase', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Passed/Failed visual feedback panel (PRD §2.4, §2.5)
        _buildEvaluationCard(
          title: 'YG Sargı Direnci Faz Dengesi Değerlendirmesi',
          feedback: evaluation,
          limitText: 'Maksimum Dengesi Sınırı: %5 (0.05)',
          valueText: evaluation['unbalance'] != null 
              ? 'Faz Dengesizliği (Unbalance): %${(evaluation['unbalance'] as double).toStringAsFixed(2)}' 
              : 'Gözlemlenen: Girdi Bekleniyor...',
        ),
      ],
    );
  }

  // Step 4: Turns Ratio (TTR) & Grounding tests
  Widget _buildTtrStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final Map<String, dynamic> evaluation = _calculateTtrError();

    final double? groundVal = double.tryParse(_groundingController.text);
    final bool groundOk = groundVal != null && groundVal <= 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Çevirme Oranı (TTR) Ölçümü', 'Belirlenen YG/AG kademesi için ölçülen çevirme oranlarını girin.'),
        const SizedBox(height: 24),

        TextFormField(
          controller: _ttrNominalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Nominal Çevirme Oranı',
            hintText: 'Örn: 86.25',
          ),
          onChanged: (String val) => service.updateField('ttr.nominal', val),
        ),
        const SizedBox(height: 16),

        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _ttrRController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'R Fazı Oranı'),
                onChanged: (String val) => service.updateField('ttr.r_phase', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ttrSController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'S Fazı Oranı'),
                onChanged: (String val) => service.updateField('ttr.s_phase', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ttrTController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'T Fazı Oranı'),
                onChanged: (String val) => service.updateField('ttr.t_phase', val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildEvaluationCard(
          title: 'TTR Çevirme Oranı Hata Değerlendirmesi',
          feedback: evaluation,
          limitText: 'Maksimum Hata Sınırı: ±%0.5 (0.005)',
          valueText: evaluation['error'] != null 
              ? 'Ölçülen Maksimum Hata: %${(evaluation['error'] as double).toStringAsFixed(2)}' 
              : 'Gözlemlenen: Girdi Bekleniyor...',
        ),
        const SizedBox(height: 32),

        _buildSectionHeader('Topraklama Direnci', 'Trafo gövdesi ve yıldız noktası topraklama direnci ölçümü.'),
        const SizedBox(height: 16),

        TextFormField(
          controller: _groundingController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Toprak Direnci (Ω)',
            suffixText: 'Ω',
            hintText: 'Örn: 1.2',
          ),
          onChanged: (String val) => service.updateField('grounding.value', val),
        ),
        const SizedBox(height: 16),

        if (groundVal != null)
          _buildInstantFeedbackRow(
            isOk: groundOk,
            label: 'Toprak Direnci Karşılaştırması',
            valueText: '$groundVal Ω (Sınır: ≤ 2.0 Ω)',
          ),
      ],
    );
  }

  // Step 5 (Optional): Breaker test checks
  Widget _buildBreakerStep(Report report) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);

    final double? contact = double.tryParse(_breakerContactController.text);
    final double? open = double.tryParse(_breakerOpenController.text);
    final double? close = double.tryParse(_breakerCloseController.text);
    final double? diff = double.tryParse(_breakerDiffController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('AG/OG Kesici Test Paketi', 'Kesicili trafo bakımı kapsamında kontak direnci ve açma/kapama süreleri ölçümü.'),
        const SizedBox(height: 24),

        TextFormField(
          controller: _breakerContactController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Kontak Direnci (µΩ) *',
            suffixText: 'µΩ',
            hintText: 'Max 150 µΩ',
          ),
          onChanged: (String val) => service.updateField('breaker.contact_resistance', val),
        ),
        if (contact != null)
          _buildInstantFeedbackRow(
            isOk: contact <= 150,
            label: 'Kontak Direnci Değerlendirmesi',
            valueText: '$contact µΩ (Sınır: ≤ 150 µΩ)',
          ),
        const SizedBox(height: 16),

        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _breakerOpenController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Açma Süresi (ms)',
                  suffixText: 'ms',
                  hintText: 'Max 80 ms',
                ),
                onChanged: (String val) => service.updateField('breaker.open_time', val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _breakerCloseController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Kapama Süresi (ms)',
                  suffixText: 'ms',
                  hintText: 'Max 120 ms',
                ),
                onChanged: (String val) => service.updateField('breaker.close_time', val),
              ),
            ),
          ],
        ),
        if (open != null || close != null) ...<Widget>[
          const SizedBox(height: 12),
          if (open != null)
            _buildInstantFeedbackRow(
              isOk: open < 80,
              label: 'Açma Süresi',
              valueText: '$open ms (Sınır: < 80 ms)',
            ),
          if (close != null)
            _buildInstantFeedbackRow(
              isOk: close < 120,
              label: 'Kapama Süresi',
              valueText: '$close ms (Sınır: < 120 ms)',
            ),
        ],
        const SizedBox(height: 16),

        TextFormField(
          controller: _breakerDiffController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Faz Uyuşmazlığı (ms)',
            suffixText: 'ms',
            hintText: 'Max 5 ms',
          ),
          onChanged: (String val) => service.updateField('breaker.phase_diff', val),
        ),
        if (diff != null)
          _buildInstantFeedbackRow(
            isOk: diff < 5,
            label: 'Faz Uyuşmazlığı Değerlendirmesi',
            valueText: '$diff ms (Sınır: < 5 ms)',
          ),
      ],
    );
  }

  // Phase 3: Photos Management Step (PRD §10)
  Widget _buildPhotosStep(Report report) {
    final bool isTestOnly = report.reportType == 'test';
    
    final dynamic labelPhoto = report.dataJson['photo_label'];
    final dynamic beforePhoto = report.dataJson['photo_before'];
    final dynamic hasAfterPhoto = report.dataJson['photo_after'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Saha Fotoğrafları', 'Rapor tiplerine göre zorunlu fotoğrafların tablette çekilmesi veya galeriden eklenmesi gerekir.'),
        const SizedBox(height: 24),

        // 1. Etiket Fotoğrafı (Zorunlu - Hepsi için)
        _buildPhotoCard(
          title: 'Trafo Etiket / Plaka Fotoğrafı *',
          desc: 'Trafonun marka, model ve seri numarasını gösteren plakanın net resmi.',
          photoKey: 'photo_label',
          photoPath: labelPhoto?.toString(),
        ),
        const SizedBox(height: 16),

        // 2. Öncesi ve Sonrası Fotoğrafları (Bakım ise Zorunlu)
        if (!isTestOnly) ...<Widget>[
          _buildPhotoCard(
            title: 'Bakım Öncesi Genel Görünüm *',
            desc: 'Çalışmaya başlamadan önce trafonun ve şalt sahasının durum resmi.',
            photoKey: 'photo_before',
            photoPath: beforePhoto?.toString(),
          ),
          const SizedBox(height: 16),
          _buildPhotoCard(
            title: 'Bakım Sonrası Genel Görünüm *',
            desc: 'Temizlik, sıkma ve klemens bakımları tamamlanmış trafonun bitiş resmi.',
            photoKey: 'photo_after',
            photoPath: hasAfterPhoto?.toString(),
          ),
        ] else
          _buildAlertText('Yalnızca Test raporlarında Bakım Öncesi/Sonrası fotoğrafları zorunlu değildir.'),
      ],
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String desc,
    required String photoKey,
    required String? photoPath,
  }) {
    final bool isAttached = photoPath != null;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: <Widget>[
            // Image Preview or Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isAttached ? AppTheme.successColor.withOpacity(0.06) : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isAttached ? AppTheme.successColor : AppTheme.borderLight),
              ),
              child: isAttached
                  ? const Icon(Icons.image_outlined, color: AppTheme.successColor, size: 36)
                  : const Icon(Icons.add_a_photo_outlined, color: AppTheme.textLight, size: 32),
            ),
            const SizedBox(width: 16),
            
            // Description & Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isAttached ? AppTheme.successColor : AppTheme.textDark,
                        ),
                      ),
                      if (isAttached) ...<Widget>[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight)),
                  const SizedBox(height: 10),
                  isAttached
                      ? OutlinedButton.icon(
                          onPressed: () => _deletePhoto(photoKey),
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorColor),
                          label: const Text('Kaldır'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(color: AppTheme.errorColor),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _simulatePhotoCapture(photoKey, title),
                          icon: const Icon(Icons.add_a_photo, size: 14),
                          label: const Text('Fotoğraf Ekle'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
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

  // Step 6 / Finalize: Overview and submit
  Widget _buildFinalizeStep(Report report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Raporu Tamamla', 'Veri girişleri tamamlandı. Rapor özetini gözden geçirip kesinleştirin.'),
        const SizedBox(height: 24),

        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Rapor Özeti',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
                _buildSummaryRow('Müşteri:', report.customerName.isEmpty ? '(Belirtilmedi)' : report.customerName),
                _buildSummaryRow('Trafo Tipi:', report.transformerType.toUpperCase()),
                _buildSummaryRow('Kapsam:', report.subType == 'kesici' ? 'Trafo + Kesici Bakımı' : 'Trafo Bakımı'),
                _buildSummaryRow('Ölçüm Tarihi:', report.dataJson['test_date']?.toString() ?? ''),
                _buildSummaryRow('Cihaz:', '${report.dataJson['device_model'] ?? ''} (${report.dataJson['device_serial'] ?? ''})'),
                const Divider(height: 24),
                
                // Final file name notification
                Row(
                  children: <Widget>[
                    const Icon(Icons.description_outlined, color: AppTheme.textLight),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Üretilecek Dosya Adı: \n"${report.title}.xlsx"',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildAlertText('Kesinleştirilen raporlar şirket arşivine eklenir ve teknisyenler tarafından değiştirilemez (sadece indirilebilir).'),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? AppTheme.textLight : AppTheme.textDark,
          fontSize: isHeader ? 13 : 14,
        ),
        textAlign: align,
      ),
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
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
            ),
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
