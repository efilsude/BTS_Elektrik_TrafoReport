import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/signature_pad.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final BackupService _backupService = BackupService();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _signatureBase64;
  bool _isSubmittingPassword = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadSignature();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSignature() async {
    final String? signature = await _secureStorage.read(key: 'user_signature_base64');
    if (mounted) {
      setState(() {
        _signatureBase64 = signature;
      });
    }
  }

  Future<void> _handleCreateBackup() async {
    setState(() => _isBackingUp = true);
    try {
      final File? zipFile = await _backupService.createBackupAndShare();
      if (zipFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedek dosyası (${zipFile.path.split(Platform.pathSeparator).last}) oluşturuldu ve paylaşıma açıldı.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedek oluşturma hatası: $e', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _handleRestoreBackup() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['zip'],
      );

      if (result == null || result.files.single.path == null) return;

      final String zipPath = result.files.single.path!;
      final File zipFile = File(zipPath);

      if (!mounted) return;

      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: <Widget>[
              const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
              const SizedBox(width: 10),
              Text('Yedekten Geri Yükle', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Seçilen yedek dosyası (${zipFile.path.split(Platform.pathSeparator).last}) cihazdaki veritabanını, fotoğrafları ve imzaları tamamen değiştirecektir.\n\nMevcut verilerin üzerine yazılacaktır. Devam etmek istiyor musunuz?',
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
              child: const Text('Geri Yükle ve Yeniden Başlat'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() => _isRestoring = true);

      final bool success = await _backupService.restoreBackup(zipFile);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedek başarıyla geri yüklendi! Lütfen yeniden giriş yapın.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
          ),
        );

        final AuthService authService = Provider.of<AuthService>(context, listen: false);
        await authService.logout();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<dynamic>(builder: (_) => const LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geri yükleme hatası: $e', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yeni şifreler eşleşmiyor!', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final AuthService authService = Provider.of<AuthService>(context, listen: false);

    setState(() => _isSubmittingPassword = true);

    try {
      final bool success = await authService.changePasswordLocally(
        currentPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şifreniz başarıyla güncellendi.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else if (mounted && authService.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.errorMessage!, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şifre değiştirme hatası: $e', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingPassword = false);
    }
  }

  void _handleUpdateSignature() {
    showDialog<dynamic>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(
          'Dijital İmza Çizimi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 500,
          height: 300,
          child: SignaturePad(
            onSave: (String base64Png) async {
              Navigator.pop(ctx);

              // 1. Cache base64 signature locally
              await _secureStorage.write(key: 'user_signature_base64', value: base64Png);
              await _loadSignature();

              // 2. Save signature status in AuthService
              final AuthService authService = Provider.of<AuthService>(context, listen: false);
              await authService.saveUserSignatureLocally('base64_cached');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('İmzanız yerel cihazınıza kaydedildi.', style: GoogleFonts.inter()),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final User? user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil & Ayarlar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // User Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            user?.fullName ?? 'Kullanıcı',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rol: ${user?.isAdmin == true ? "Yönetici (Admin)" : "Çalışan (Teknisyen)"}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: user?.isAdmin == true ? Colors.orange.shade800 : AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tel: ${user?.phone ?? "-"} ${user?.email != null ? "• ${user!.email}" : ""}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (user != null) ...<Widget>[
              _ProfileOperatorEditCard(user: user),
              const SizedBox(height: 24),
            ],

            // Backup and Restore Card (Task B)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.backup_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          'Veri Yedeği ve Geri Yükleme',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cihazınızdaki veritabanını, rapor fotoğraflarını ve dijital imzaları kapsayan .zip formatında tam veri yedeği oluşturabilir veya yedekten geri yükleyebilirsiniz.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textLight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (BuildContext ctx, BoxConstraints constraints) {
                        final bool isWideButtons = constraints.maxWidth > 500;
                        if (isWideButtons) {
                          return Row(
                            children: <Widget>[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isBackingUp ? null : _handleCreateBackup,
                                  icon: _isBackingUp
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.file_upload_outlined),
                                  label: const Text('Veri Yedeği Al (.zip)'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isRestoring ? null : _handleRestoreBackup,
                                  icon: _isRestoring
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.file_download_outlined),
                                  label: const Text('Yedekten Geri Yükle'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.primaryColor),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              ElevatedButton.icon(
                                onPressed: _isBackingUp ? null : _handleCreateBackup,
                                icon: _isBackingUp
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.file_upload_outlined),
                                label: const Text('Veri Yedeği Al (.zip)'),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _isRestoring ? null : _handleRestoreBackup,
                                icon: _isRestoring
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.file_download_outlined),
                                label: const Text('Yedekten Geri Yükle'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppTheme.primaryColor),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Digital Signature Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Dijital İmza',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Raporlarda yer alacak imzanız cihazınızda yerel olarak saklanır.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: _signatureBase64 != null
                          ? Image.memory(
                              base64Decode(_signatureBase64!),
                              fit: BoxFit.contain,
                            )
                          : Center(
                              child: Text(
                                'Henüz dijital imza eklenmemiş',
                                style: GoogleFonts.inter(color: AppTheme.textLight),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _handleUpdateSignature,
                        icon: const Icon(Icons.draw_rounded, size: 18),
                        label: Text(_signatureBase64 == null ? 'İmza Ekle' : 'İmzayı Yenile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Password Change Card (bcrypt)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Şifre Değiştir',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _oldPasswordController,
                        obscureText: _obscureOld,
                        decoration: InputDecoration(
                          labelText: 'Mevcut Şifre',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureOld = !_obscureOld),
                          ),
                        ),
                        validator: (String? val) =>
                            val == null || val.isEmpty ? 'Mevcut şifrenizi girin' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        validator: (String? val) {
                          if (val == null || val.isEmpty) return 'Yeni şifre girin';
                          if (val.length < 4) return 'En az 4 karakter olmalı';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre (Tekrar)',
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (String? val) {
                          if (val == null || val.isEmpty) return 'Şifre tekrarı girin';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _isSubmittingPassword ? null : _handleChangePassword,
                          child: _isSubmittingPassword
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('Şifreyi Güncelle', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await authService.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<dynamic>(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
                label: Text(
                  'Oturumu Kapat',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOperatorEditCard extends StatefulWidget {
  final User user;
  const _ProfileOperatorEditCard({required this.user});

  @override
  State<_ProfileOperatorEditCard> createState() => _ProfileOperatorEditCardState();
}

class _ProfileOperatorEditCardState extends State<_ProfileOperatorEditCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _operatorTitleController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _operatorTitleController = TextEditingController(text: widget.user.operatorTitle ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _operatorTitleController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    final bool success = await authService.updateUserProfile(
      fullName: _fullNameController.text.trim(),
      operatorTitle: _operatorTitleController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Operatör profil bilgileriniz başarıyla güncellendi.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.errorMessage ?? 'Profil güncellenirken hata oluştu.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.user.isAdmin;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.badge_outlined, color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  Text(
                    'Operatör Profil Bilgileri',
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rapor kapak ve onay sayfalarında yer alan imza sahibi operatör bilgileri.',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight),
              ),
              const SizedBox(height: 12),

              if (!isAdmin) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.lock_outline_rounded, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bu bilgiler yalnızca sistem yöneticisi (admin) tarafından güncellenebilir.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _fullNameController,
                enabled: isAdmin,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad (Operatör Adı) *',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: !isAdmin,
                  fillColor: !isAdmin ? Colors.grey.shade100 : null,
                ),
                validator: (String? val) => val == null || val.trim().isEmpty ? 'Ad Soyad zorunludur' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _operatorTitleController,
                enabled: isAdmin,
                decoration: InputDecoration(
                  labelText: 'Unvan (Elektrik Mühendisi vb.) *',
                  prefixIcon: const Icon(Icons.work_outline_rounded),
                  filled: !isAdmin,
                  fillColor: !isAdmin ? Colors.grey.shade100 : null,
                ),
                validator: (String? val) => val == null || val.trim().isEmpty ? 'Unvan zorunludur' : null,
              ),
              if (isAdmin) ...<Widget>[
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Profili Kaydet'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
