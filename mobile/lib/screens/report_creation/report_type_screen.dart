import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';
import 'report_form_screen.dart';

class ReportTypeScreen extends StatefulWidget {
  const ReportTypeScreen({super.key});

  @override
  State<ReportTypeScreen> createState() => _ReportTypeScreenState();
}

class _ReportTypeScreenState extends State<ReportTypeScreen> {
  String _reportType = 'bakim'; // 'bakim' or 'test'
  String _subType = 'normal'; // 'normal' or 'kesici'
  String _transformerType = 'hermetik'; // 'hermetik', 'kuru_tip', 'gt'

  void _handleStart() {
    final ReportService reportService = Provider.of<ReportService>(context, listen: false);
    
    // Start report creation in service
    reportService.startNewReport(
      reportType: _reportType,
      subType: _subType,
      transformerType: _transformerType,
    );

    // Navigate to Form screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const ReportFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Rapor Tipi Seçin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Rapor Yapılandırması',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Yapacağınız saha çalışmasının tipini seçin. Bu seçim form alanlarını ve üretilecek Excel şablonunu kilitleyecektir.',
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 1. Bakım vs Test Seçimi
                _buildSectionTitle('1. Çalışma Kategorisi'),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildSelectableCard(
                        title: 'Trafo Bakım Raporu',
                        desc: 'Periyodik trafo bakım, gözlem ve test ölçümleri.',
                        icon: Icons.construction_rounded,
                        isSelected: _reportType == 'bakim',
                        onTap: () => setState(() {
                          _reportType = 'bakim';
                          _subType = 'normal'; // Reset
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSelectableCard(
                        title: 'Yalnızca Test Raporu',
                        desc: 'Bakım yapılmaksızın sadece elektriksel test ölçümleri.',
                        icon: Icons.speed_rounded,
                        isSelected: _reportType == 'test',
                        onTap: () => setState(() {
                          _reportType = 'test';
                          _subType = 'normal';
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Subtype (Bakım ise: Normal vs Kesici)
                if (_reportType == 'bakim') ...<Widget>[
                  _buildSectionTitle('2. Bakım Kapsamı'),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildSelectableCard(
                          title: 'Standart Bakım',
                          desc: 'Sadece trafo gövdesi, sargı ve izolasyon bakımları.',
                          icon: Icons.electric_bolt_rounded,
                          isSelected: _subType == 'normal',
                          onTap: () => setState(() => _subType = 'normal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSelectableCard(
                          title: 'Kesicili Bakım',
                          desc: 'Trafo bakımı + AG/OG Kesici testleri modülü.',
                          icon: Icons.electric_meter_rounded,
                          isSelected: _subType == 'kesici',
                          onTap: () => setState(() => _subType = 'kesici'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // 3. Yapım Tipi Seçimi
                _buildSectionTitle('3. Trafo Yapım Tipi'),
                const SizedBox(height: 12),
                isTablet
                    ? Row(
                        children: _buildTransformerTypeOptions(),
                      )
                    : Column(
                        children: _buildTransformerTypeOptions(isVertical: true),
                      ),
                const SizedBox(height: 40),

                // Start Button
                ElevatedButton(
                  onPressed: _handleStart,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Text(
                    'Formu Başlat ve QR Okut',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
    );
  }

  List<Widget> _buildTransformerTypeOptions({bool isVertical = false}) {
    final List<Map<String, dynamic>> options = <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'hermetik',
        'title': 'Hermetik Yağlı',
        'desc': 'Sızdırmaz trafolar (Yağ numunesi alınmaz).',
        'icon': Icons.opacity_rounded,
      },
      <String, dynamic>{
        'type': 'gt',
        'title': 'Genleşme Tanklı',
        'desc': 'Konvansiyonel yağlı (Yağ numunesi & analizi aktif).',
        'icon': Icons.waves_rounded,
      },
      <String, dynamic>{
        'type': 'kuru_tip',
        'title': 'Kuru Tip',
        'desc': 'Reçineli trafolar (Fan ve epoksi kontrolleri aktif).',
        'icon': Icons.wind_power_rounded,
      },
    ];

    return options.map((Map<String, dynamic> opt) {
      final Widget card = _buildSelectableCard(
        title: opt['title'] as String,
        desc: opt['desc'] as String,
        icon: opt['icon'] as IconData,
        isSelected: _transformerType == opt['type'],
        onTap: () => setState(() => _transformerType = opt['type'] as String),
      );

      if (isVertical) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: card,
        );
      } else {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: card,
          ),
        );
      }
    }).toList();
  }

  Widget _buildSelectableCard({
    required String title,
    required String desc,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.04) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : AppTheme.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
                size: 28,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
