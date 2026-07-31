import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _InviteCodeItem {
  final String code;
  final String role; // 'employee' | 'admin'
  final String status; // 'active' | 'used' | 'expired'
  _InviteCodeItem({required this.code, required this.role, required this.status});
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final List<_InviteCodeItem> _generatedCodes = <_InviteCodeItem>[
    _InviteCodeItem(code: 'XYZ789', role: 'employee', status: 'active'),
    _InviteCodeItem(code: 'ABC123', role: 'admin', status: 'expired'),
    _InviteCodeItem(code: 'KPT456', role: 'employee', status: 'used'),
  ];
  final List<String> _templates = <String>[
    'Hermetik Bakım Şablonu (v1.2)', 
    'Kuru Tip Bakım Şablonu (v1.0)', 
    'Genleşme Tanklı (GT) Bakım Şablonu (v2.1)'
  ];
  String _selectedRole = 'employee'; // used in the invite code creation dialog

  Future<void> _generateInviteCode() async {
    _selectedRole = 'employee'; // reset each time
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Davet Kodu Üret', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Yeni kullanıcının rolunu seçin:',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  // Role Picker Tiles
                  InkWell(
                    onTap: () => setDialogState(() => _selectedRole = 'employee'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedRole == 'employee' ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedRole == 'employee' ? AppTheme.primaryColor : Colors.grey.shade300,
                          width: _selectedRole == 'employee' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.engineering_outlined,
                            color: _selectedRole == 'employee' ? AppTheme.primaryColor : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Çalışan (Employee)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Teknisyen / Rapor İşleme Yetkisi', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const Spacer(),
                          if (_selectedRole == 'employee')
                            Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => setDialogState(() => _selectedRole = 'admin'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedRole == 'admin' ? Colors.orange.withOpacity(0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedRole == 'admin' ? Colors.orange.shade700 : Colors.grey.shade300,
                          width: _selectedRole == 'admin' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            color: _selectedRole == 'admin' ? Colors.orange.shade700 : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Yönetici (Admin)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Tam Yönetim + Kullanıcı Yönetimi Yetkisi', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const Spacer(),
                          if (_selectedRole == 'admin')
                            Icon(Icons.check_circle_rounded, color: Colors.orange.shade700, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('İptal', style: GoogleFonts.inter(color: AppTheme.textLight)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('Kod Üret', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      // Mock: generate code locally (real API call would be POST /admin/codes with {role: _selectedRole})
      final String newCode = 'BTS${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      setState(() {
        _generatedCodes.insert(0, _InviteCodeItem(code: newCode, role: _selectedRole, status: 'active'));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Davet kodu oluşturuldu: $newCode (${_selectedRole == 'admin' ? 'Yönetici' : 'Çalışan'})'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
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
                            color: Colors.white70,
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
                final _InviteCodeItem item = _generatedCodes[index];
                final bool isInactive = item.status == 'used' || item.status == 'expired';
                final bool isAdmin = item.role == 'admin';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isInactive ? Colors.grey.shade200 : Colors.green.shade50,
                    child: Icon(
                      isInactive ? Icons.key_off_outlined : Icons.vpn_key_outlined,
                      color: isInactive ? Colors.grey : Colors.green,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.code,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isInactive ? AppTheme.textLight : AppTheme.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.orange.shade100 : AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAdmin ? Colors.orange.shade400 : AppTheme.primaryColor.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          isAdmin ? 'Yönetici' : 'Çalışan',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isAdmin ? Colors.orange.shade800 : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    item.status == 'used'
                      ? 'Kullanıldı'
                      : item.status == 'expired'
                        ? 'Süresi Doldu'
                        : 'Aktif (15 dk TTL)',
                    style: TextStyle(
                      fontSize: 11,
                      color: isInactive ? Colors.red : Colors.green,
                    ),
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
