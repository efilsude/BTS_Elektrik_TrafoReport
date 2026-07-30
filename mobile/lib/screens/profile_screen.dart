import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/signature_pad.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  
  String? _signatureBase64;
  bool _loadingSignature = true;

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
    // Standard key in API_CONTRACT is signature image
    final String? sig = await _storageService.getAccessToken(); // We can store signature in custom storage
    // Let's store signature under a specific key in StorageService
    final String? signature = await FlutterSecureStorage().read(key: 'user_signature_base64');
    setState(() {
      _signatureBase64 = signature;
      _loadingSignature = false;
    });
  }

  void _handleChangePassword() {
    if (!_passwordFormKey.currentState!.validate()) return;
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni şifreler eşleşmiyor!'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Call service update password (mock for now)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Şifreniz başarıyla güncellendi! (Mock)'),
        backgroundColor: AppTheme.successColor,
      ),
    );
    
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  void _handleUpdateSignature() {
    showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'Dijital İmza Çizimi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 500,
          height: 300,
          child: SignaturePad(
            onSave: (String base64Png) async {
              // Save to secure storage
              await FlutterSecureStorage().write(key: 'user_signature_base64', value: base64Png);

              Navigator.pop(context);
              _loadSignature();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dijital imzanız başarıyla kaydedildi!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final User? user = authService.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('Yükleniyor...')));

    return Scaffold(
      appBar: AppBar(
        title: Text('Kullanıcı Profili', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // User Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        user.fullName.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 28,
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
                            user.fullName,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.isAdmin ? 'Yönetici / Şirket Sahibi' : 'Saha Bakım Teknisyeni',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (user.sicilNo != null)
                            Text(
                              'Sicil No: ${user.sicilNo}',
                              style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13),
                            ),
                          Text(
                            'Telefon: ${user.phone}',
                            style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13),
                          ),
                          if (user.email != null)
                            Text(
                              'E-posta: ${user.email}',
                              style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Signature Setup Card
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
                      'Raporlarınızın altındaki imza alanına otomatik olarak yerleştirilecek el yazısı imzanızı buraya kaydedin.',
                      style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    // Imza durumu veya resmi
                    _loadingSignature
                        ? const Center(child: CircularProgressIndicator())
                        : _signatureBase64 != null
                            ? Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.borderLight),
                                ),
                                padding: const EdgeInsets.all(8),
                                alignment: Alignment.center,
                                child: Image.memory(
                                  base64Decode(_signatureBase64!),
                                  fit: BoxFit.contain,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.borderLight),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Kayıtlı İmza Bulunmamaktadır',
                                  style: GoogleFonts.inter(
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _handleUpdateSignature,
                      icon: const Icon(Icons.gesture_rounded),
                      label: Text(_signatureBase64 != null ? 'İmzayı Yenile' : 'İmza Çiz & Kaydet'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Change Password Card
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
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscureOld = !_obscureOld),
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Mevcut şifrenizi girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Yeni şifrenizi girin';
                          }
                          if (value.length < 8) {
                            return 'Şifre en az 8 karakter olmalıdır';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Yeni Şifre Tekrar',
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre onayını girin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _handleChangePassword,
                        child: const Text('Şifreyi Güncelle'),
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
              child: ElevatedButton(
                onPressed: () async {
                  await authService.logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<dynamic>(builder: (BuildContext context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Oturumu Kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
