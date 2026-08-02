import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<User> _users = <User>[];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    final List<User> list = await _dbHelper.getAllUsers();
    if (mounted) {
      setState(() {
        _users = list;
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _showAddUserDialog() async {
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();
    final TextEditingController sicilCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();
    String selectedRole = 'employee';

    final bool? created = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Yeni Kullanıcı Ekle', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: dialogFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Ad Soyad *'),
                          validator: (String? v) => v == null || v.trim().isEmpty ? 'Zorunlu' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Telefon Numarası *'),
                          validator: (String? v) => v == null || v.trim().isEmpty ? 'Zorunlu' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'E-posta (Opsiyonel)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: sicilCtrl,
                          decoration: const InputDecoration(labelText: 'Sicil No (Opsiyonel)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Şifre *'),
                          validator: (String? v) => v == null || v.length < 4 ? 'En az 4 karakter' : null,
                        ),
                        const SizedBox(height: 16),
                        Text('Kullanıcı Rolü:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            ChoiceChip(
                              label: const Text('Çalışan'),
                              selected: selectedRole == 'employee',
                              onSelected: (bool sel) {
                                if (sel) setDialogState(() => selectedRole = 'employee');
                              },
                            ),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('Yönetici'),
                              selected: selectedRole == 'admin',
                              selectedColor: Colors.orange.shade200,
                              onSelected: (bool sel) {
                                if (sel) setDialogState(() => selectedRole = 'admin');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dialogFormKey.currentState!.validate()) {
                      final AuthService authService = Provider.of<AuthService>(context, listen: false);
                      final bool ok = await authService.createLocalUser(
                        fullName: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                        sicilNo: sicilCtrl.text.trim().isEmpty ? null : sicilCtrl.text.trim(),
                        password: passCtrl.text,
                        role: selectedRole,
                      );
                      if (ok && ctx.mounted) {
                        Navigator.of(ctx).pop(true);
                      } else if (ctx.mounted && authService.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authService.errorMessage!), backgroundColor: AppTheme.errorColor),
                        );
                      }
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true) {
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı eklendi!'), backgroundColor: AppTheme.successColor),
        );
      }
    }
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
            // Admin Banner
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
                          'Yönetici Paneli (Yerel Cihaz)',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Cihazdaki kullanıcıları ve sistem ayarlarını doğrudan yönetin.',
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

            // Quick Stats
            GridView.count(
              crossAxisCount: isTablet ? 3 : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isTablet ? 2.5 : 3.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: <Widget>[
                _buildStatCard('Kayıtlı Kullanıcı', _users.length.toString(), Icons.people_alt_outlined, AppTheme.secondaryColor),
                _buildStatCard('Yönetici Sayısı', _users.where((User u) => u.isAdmin).length.toString(), Icons.admin_panel_settings_outlined, Colors.orange),
                _buildStatCard('Çalışan Sayısı', _users.where((User u) => u.isEmployee).length.toString(), Icons.engineering_outlined, AppTheme.primaryColor),
              ],
            ),
            const SizedBox(height: 24),

            // User Management Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Cihaz Kullanıcıları',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddUserDialog,
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                          label: const Text('Kullanıcı Ekle'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingUsers)
                      const Center(child: CircularProgressIndicator())
                    else if (_users.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Kayıtlı kullanıcı yok.'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _users.length,
                        itemBuilder: (BuildContext context, int index) {
                          final User u = _users[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: u.isAdmin ? Colors.orange.shade100 : AppTheme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                                color: u.isAdmin ? Colors.orange.shade800 : AppTheme.primaryColor,
                              ),
                            ),
                            title: Text(
                              u.fullName,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Text('Tel: ${u.phone} ${u.email != null ? "• ${u.email}" : ""}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: u.isAdmin ? Colors.orange.shade100 : AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                u.isAdmin ? 'Yönetici' : 'Çalışan',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: u.isAdmin ? Colors.orange.shade800 : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
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
}
