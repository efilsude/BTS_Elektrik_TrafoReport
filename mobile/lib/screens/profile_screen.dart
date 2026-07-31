import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/config.dart';
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
  bool _loadingSignature = true;
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
    setState(() {
      _signatureBase64 = signature;
      _loadingSignature = false;
    });
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
      // Mock branch: DEV only — skipped entirely in release
      if (!kReleaseMode && authService.isMockMode) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Şifreniz başarıyla güncellendi (Mock).', style: GoogleFonts.inter()),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        // Real API call: PUT /users/me/password
        final http.Response response = await authService.authenticatedRequest(
          (String token) => http.put(
            Uri.parse('${AppConfig.apiBaseUrl}/users/me/password'),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(<String, String>{
              'current_password': _oldPasswordController.text,
              'new_password': _newPasswordController.text,
            }),
          ),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Şifreniz başarıyla güncellendi.', style: GoogleFonts.inter()),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } else {
          String errMsg = 'Şifre güncellenemedi.';
          try {
            final Map<String, dynamic> errJson = jsonDecode(response.body) as Map<String, dynamic>;
            errMsg = errJson['error']?['message'] ?? errJson['detail'] ?? errMsg;
          } catch (_) {}
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errMsg, style: GoogleFonts.inter()),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      }

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e', style: GoogleFonts.inter()),
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
              
              // 1. Local secure storage cache
              await _secureStorage.write(key: 'user_signature_base64', value: base64Png);
              await _loadSignature();

              final AuthService authService = Provider.of<AuthService>(context, listen: false);
              
              // 2. Real API upload if online: PUT /users/me/signature
              //    In release mode, always attempt upload (mock mode is disabled in release)
              if (kReleaseMode || !authService.isMockMode) {
                try {
                  final List<int> imageBytes = base64Decode(base64Png);
                  final http.MultipartRequest request = http.MultipartRequest(
                    'PUT',
                    Uri.parse('${AppConfig.apiBaseUrl}/users/me/signature'),
                  );
                  
                  final String? token = await _secureStorage.read(key: 'access_token');
                  if (token != null) {
                    request.headers['Authorization'] = 'Bearer $token';
                  }

                  request.files.add(
                    http.MultipartFile.fromBytes(
                      'file',
                      imageBytes,
                      filename: 'signature.png',
                    ),
                  );

                  await request.send();
                } catch (_) {}
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dijital imzanız başarıyla kaydedildi!', style: GoogleFonts.inter()),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
            // User Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName.substring(0, 1).toUpperCase() : 'U',
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
                          if (user.sicilNo != null && user.sicilNo!.isNotEmpty)
                            Text(
                              'Sicil No: ${user.sicilNo}',
                              style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13),
                            ),
                          Text(
                            'Telefon: ${user.phone}',
                            style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13),
                          ),
                          if (user.email != null && user.email!.isNotEmpty)
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

            // Debug / Developer Mode Card — DEV only, hidden in release
            if (!kReleaseMode)
            Card(
              color: Colors.blueGrey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blueGrey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SwitchListTile(
                  title: Text(
                    'Çevrimdışı / Simülasyon (Mock) Modu',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    authService.isMockMode
                        ? 'Aktif: Sunucusuz yerel bellek kullanılıyor.'
                        : 'Devre Dışı: Gerçek API bağlantısı (${AppConfig.apiBaseUrl}).',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight),
                  ),
                  value: authService.isMockMode,
                  onChanged: (bool val) => authService.setMockMode(val),
                  activeColor: AppTheme.primaryColor,
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
                      'Raporlarınızın altındaki imza alanına otomatik olarak yerleştirilecek el yazısı imzanızı buraya kaydedin.',
                      style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
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
                        onPressed: _isSubmittingPassword ? null : _handleChangePassword,
                        child: _isSubmittingPassword
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Şifreyi Güncelle'),
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
