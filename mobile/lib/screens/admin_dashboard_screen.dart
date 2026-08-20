import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

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
    final TextEditingController titleCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();
    final TextEditingController emailCtrl = TextEditingController();
    final TextEditingController passCtrl = TextEditingController();
    String selectedRole = 'employee';
    bool obscurePassword = true;

    final bool? created = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          decoration: const InputDecoration(labelText: 'Ad Soyad (Operatör Adı) *'),
                          validator: Validators.validateFullName,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(labelText: 'Unvan (Elektrik Mühendisi vb.) *'),
                          validator: Validators.validateTitle,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Telefon Numarası *', hintText: '05XXXXXXXXX'),
                          validator: Validators.validatePhone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'E-posta (Opsiyonel)'),
                          validator: Validators.validateEmailOptional,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passCtrl,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Şifre *',
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.textLight,
                              ),
                              tooltip: obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                              onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                          validator: (String? v) => Validators.validatePassword(v, minLength: 4),
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
                        operatorTitle: titleCtrl.text.trim(),
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
          const SnackBar(content: Text('Kullanıcı başarıyla eklendi!'), backgroundColor: AppTheme.successColor),
        );
      }
    }
  }

  Future<void> _showEditUserDialog(User targetUser) async {
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();
    final TextEditingController nameCtrl = TextEditingController(text: targetUser.fullName);
    final TextEditingController titleCtrl = TextEditingController(text: targetUser.operatorTitle ?? '');
    final TextEditingController phoneCtrl = TextEditingController(text: targetUser.phone);
    final TextEditingController emailCtrl = TextEditingController(text: targetUser.email ?? '');
    final TextEditingController passCtrl = TextEditingController();
    String selectedRole = targetUser.role;
    bool obscurePassword = true;

    final bool? updated = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Kullanıcıyı Düzenle', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                          decoration: const InputDecoration(labelText: 'Ad Soyad (Operatör Adı) *'),
                          validator: Validators.validateFullName,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(labelText: 'Unvan (Elektrik Mühendisi vb.) *'),
                          validator: Validators.validateTitle,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Telefon Numarası *', hintText: '05XXXXXXXXX'),
                          validator: Validators.validatePhone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'E-posta (Opsiyonel)'),
                          validator: Validators.validateEmailOptional,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passCtrl,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Yeni Şifre (Opsiyonel)',
                            hintText: 'Değiştirmek istemiyorsanız boş bırakın',
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppTheme.textLight,
                              ),
                              tooltip: obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                              onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                          validator: (String? v) => Validators.validatePasswordOptional(v, minLength: 4),
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
                      final bool ok = await authService.updateLocalUser(
                        id: targetUser.id,
                        fullName: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                        operatorTitle: titleCtrl.text.trim(),
                        role: selectedRole,
                        newPassword: passCtrl.text.isEmpty ? null : passCtrl.text,
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
                  child: const Text('Güncelle'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true) {
      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı bilgileri güncellendi!'), backgroundColor: AppTheme.successColor),
        );
      }
    }
  }

  Future<void> _handleDeleteUser(User targetUser) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: <Widget>[
            const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            const SizedBox(width: 10),
            Text('Kullanıcıyı Sil', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '"${targetUser.fullName}" kullanıcısını cihazdan silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz ancak geçmişte oluşturduğu raporlar silinmez.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.4),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    final bool success = await authService.deleteUser(targetUser.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${targetUser.fullName} kullanıcısı silindi.', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.successColor,
        ),
      );
      await _loadUsers();
    } else if (mounted && authService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage!, style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yönetici Paneli', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Streamlined Admin Header Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded, size: 32, color: AppTheme.primaryDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Kullanıcı ve Sistem Yönetimi',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Yerel cihaz hesaplarını ekleyin veya düzenleyin.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryDark.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Stats Grid / Row
              LayoutBuilder(
                builder: (BuildContext ctx, BoxConstraints constraints) {
                  final bool isWide = constraints.maxWidth > 650;
                  if (isWide) {
                    return Row(
                      children: <Widget>[
                        Expanded(child: _buildStatCard('Kayıtlı Kullanıcı', _users.length.toString(), Icons.people_alt_outlined, AppTheme.secondaryColor)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Yönetici Sayısı', _users.where((User u) => u.isAdmin).length.toString(), Icons.admin_panel_settings_outlined, Colors.orange)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatCard('Çalışan Sayısı', _users.where((User u) => u.isEmployee).length.toString(), Icons.engineering_outlined, AppTheme.primaryColor)),
                      ],
                    );
                  } else {
                    return Column(
                      children: <Widget>[
                        _buildStatCard('Kayıtlı Kullanıcı', _users.length.toString(), Icons.people_alt_outlined, AppTheme.secondaryColor),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(child: _buildStatCard('Yönetici Sayısı', _users.where((User u) => u.isAdmin).length.toString(), Icons.admin_panel_settings_outlined, Colors.orange)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildStatCard('Çalışan Sayısı', _users.where((User u) => u.isEmployee).length.toString(), Icons.engineering_outlined, AppTheme.primaryColor)),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 20),

              // User Management Section Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // User List Header Row
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: <Widget>[
                          Text(
                            'Cihaz Kullanıcıları',
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddUserDialog,
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                            label: const Text('Kullanıcı Ekle'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_isLoadingUsers)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_users.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: Text('Kayıtlı kullanıcı bulunamadı.')),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int index) {
                            final User u = _users[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: u.isAdmin ? Colors.orange.shade100 : AppTheme.primaryColor.withOpacity(0.1),
                                    child: Icon(
                                      u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                                      color: u.isAdmin ? Colors.orange.shade800 : AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          u.fullName,
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tel: ${u.phone} ${u.email != null ? "• ${u.email}" : ""}',
                                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 4,
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: u.isAdmin ? Colors.orange.shade100 : AppTheme.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          u.isAdmin ? 'Yönetici' : 'Çalışan',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: u.isAdmin ? Colors.orange.shade800 : AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                                        tooltip: 'Kullanıcıyı Düzenle',
                                        onPressed: () => _showEditUserDialog(u),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 20),
                                        tooltip: 'Kullanıcıyı Sil',
                                        onPressed: () => _handleDeleteUser(u),
                                      ),
                                    ],
                                  ),
                                ],
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
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
