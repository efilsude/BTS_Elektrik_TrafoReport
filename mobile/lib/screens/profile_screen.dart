import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
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
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _signatureBase64;
  bool _isSubmittingPassword = false;

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
                      'Kesinleştirilen raporlarda yer alacak imzanız cihazınızda yerel olarak saklanır.',
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

            // Password Change Card
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
