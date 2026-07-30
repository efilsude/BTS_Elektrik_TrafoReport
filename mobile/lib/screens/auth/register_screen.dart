import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _sicilNoController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isAdminRegister = false;

  @override

  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sicilNoController.dispose();
    _inviteCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Şifreler eşleşmiyor.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final AuthService authService = Provider.of<AuthService>(context, listen: false);

    final bool success = await authService.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      sicilNo: _sicilNoController.text.trim().isEmpty ? null : _sicilNoController.text.trim(),
      inviteCode: _inviteCodeController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kayıt başarıyla tamamlandı! Oturum açıldı.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<dynamic>(builder: (BuildContext context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authService.errorMessage ?? 'Kayıt sırasında hata oluştu.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final Size size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yeni Hesap Oluştur',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40 : 20, 
                  vertical: 30,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Header info
                      Text(
                        _isAdminRegister ? 'Yönetici (Admin) Kayıt Formu' : 'Çalışan Kayıt Formu',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isAdminRegister ? Colors.orange.shade800 : AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kayıt olmak için yöneticinizden aldığınız 15 dakika geçerli davet kodunu kullanmalısınız.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textLight,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Admin registration selection
                      Container(
                        decoration: BoxDecoration(
                          color: _isAdminRegister ? Colors.orange.shade50 : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isAdminRegister ? Colors.orange.shade300 : Colors.grey.shade300,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: _isAdminRegister,
                          onChanged: (bool? val) {
                            setState(() => _isAdminRegister = val ?? false);
                          },
                          title: Text(
                            'Yönetici (Admin) olarak kayıt ol',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isAdminRegister ? Colors.orange.shade900 : AppTheme.textDark,
                            ),
                          ),
                          subtitle: Text(
                            'Sistem yöneticisi yetkileri talep eder.',
                            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight),
                          ),
                          activeColor: Colors.orange.shade800,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      if (_isAdminRegister) ...<Widget>[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade600),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Geçerli bir admin davet kodu gereklidir. Yöneticinizden temin ediniz.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),


                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad *',
                          prefixIcon: Icon(Icons.badge_outlined),
                          hintText: 'Ahmet Yılmaz',
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ad Soyad zorunludur';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email (Optional)
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-posta (İsteğe Bağlı)',
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'ahmet@btselektrik.com',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon Numarası *',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: '05551234567',
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Telefon numarası zorunludur';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sicil No (Optional)
                      TextFormField(
                        controller: _sicilNoController,
                        decoration: const InputDecoration(
                          labelText: 'Sicil No (İsteğe Bağlı)',
                          prefixIcon: Icon(Icons.assignment_ind_outlined),
                          hintText: '12345',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Invite Code
                      TextFormField(
                        controller: _inviteCodeController,
                        decoration: InputDecoration(
                          labelText: 'Davet Kodu *',
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                          hintText: 'Örn: XYZ123',
                          helperText: 'Yöneticinizden temin ettiğiniz kod',
                          helperStyle: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Davet kodu zorunludur';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Şifre *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppTheme.textLight,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          helperText: 'En az 8 karakter, harf ve rakam içermelidir',
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre belirlemelisiniz';
                          }
                          if (value.length < 8) {
                            return 'Şifre en az 8 karakter olmalıdır';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Şifreyi Onayla *',
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppTheme.textLight,
                            ),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifreyi onaylayın';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Register Button
                      ElevatedButton(
                        onPressed: authService.isLoading ? null : _handleRegister,
                        child: authService.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Hesabı Oluştur ve Giriş Yap',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
