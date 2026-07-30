import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final List<String> _generatedCodes = <String>['XYZ789 (Kullanılmadı)', 'ABC123 (Süresi Doldu)', 'KPT456 (Kullanıldı)'];
  final List<String> _templates = <String>[
    'Hermetik Bakım Şablonu (v1.2)', 
    'Kuru Tip Bakım Şablonu (v1.0)', 
    'Genleşme Tanklı (GT) Bakım Şablonu (v2.1)'
  ];

  void _generateInviteCode() {
    // Mock code generator
    final String newCode = 'BTS${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    setState(() {
      _generatedCodes.insert(0, '$newCode (Kullanılmadı - 15 dk geçerli)');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Davet kodu oluşturuldu: $newCode'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _uploadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel Şablonu Yükleme özelliği Faz 4\'te aktif olacaktır.'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Yönetici Paneli', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Admin Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.admin_panel_settings_rounded, size: 48, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Hoş Geldiniz, Yönetici',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Sistem şablonlarını, kayıt kodlarını ve şirket kullanıcılarını buradan yönetebilirsiniz.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white80,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Responsive Quick Stats Grid
            GridView.count(
              crossAxisCount: isTablet ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isTablet ? 2.5 : 3.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: <Widget>[
                _buildStatCard('Toplam Rapor', '24', Icons.article_outlined, AppTheme.primaryColor),
                _buildStatCard('Aktif Kullanıcı', '8', Icons.people_alt_outlined, AppTheme.secondaryColor),
                _buildStatCard('Aktif Şablon', '3', Icons.table_chart_outlined, AppTheme.accentColor),
              ],
            ),
            const SizedBox(height: 24),

            // Two-column details for tablet, single column for mobile
            if (isTablet)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _buildInviteCodeSection()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildTemplateSection()),
                ],
              )
            else ...<Widget>[
              _buildInviteCodeSection(),
              const SizedBox(height: 24),
              _buildTemplateSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Kayıt Davet Kodları',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _generateInviteCode,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Kod Üret'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _generatedCodes.length,
              itemBuilder: (BuildContext context, int index) {
                final String codeStr = _generatedCodes[index];
                final bool isUsed = codeStr.contains('Kullanıldı') || codeStr.contains('Süresi Doldu');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isUsed ? Colors.grey.shade200 : Colors.emerald.shade50,
                    child: Icon(
                      isUsed ? Icons.key_off_outlined : Icons.vpn_key_outlined,
                      color: isUsed ? Colors.grey : Colors.emerald,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    codeStr,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isUsed ? AppTheme.textLight : AppTheme.textDark,
                    ),
                  ),
                  subtitle: Text(
                    isUsed ? 'Geçersiz' : 'Aktif (15 dk TTL)',
                    style: TextStyle(fontSize: 11, color: isUsed ? Colors.red : Colors.green),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Rapor Şablonları (.xlsx)',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  onPressed: _uploadTemplate,
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('Yükle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _templates.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.table_view_rounded, color: Colors.blue, size: 20),
                  ),
                  title: Text(
                    _templates[index],
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Aktif Kullanımda', style: TextStyle(fontSize: 11, color: Colors.blue)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Şablon silinemez - Aktif raporlarla ilişkili.')),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
