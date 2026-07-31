import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';

class FirstAdminBootstrapScreen extends StatefulWidget {
  const FirstAdminBootstrapScreen({super.key});

  @override
  State<FirstAdminBootstrapScreen> createState() => _FirstAdminBootstrapScreenState();
}

class _FirstAdminBootstrapScreenState extends State<FirstAdminBootstrapScreen> {
  final GlobalKey<FormState> _formKeyStep1 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyStep2 = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _sicilNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  int _currentStep = 1;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _activeDebugCode;

  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sicilNoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_resendCountdown <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _resendCountdown = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      }
    });
  }

  Future<void> _handleRequestBootstrapCode() async {
    if (!_formKeyStep1.currentState!.validate()) return;

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

    final VerificationResult result = await authService.requestVerificationBootstrap(
      email: _emailController.text.trim(),
    );

    if (result.success && mounted) {
      _startResendTimer();
      _activeDebugCode = result.debugCode;
      if (_activeDebugCode != null && _activeDebugCode!.isNotEmpty) {
        _verificationCodeController.text = _activeDebugCode!;
      }
      setState(() {
        _currentStep = 2;
      });

      if (_activeDebugCode != null && _activeDebugCode!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Geliştirme modu: Kod $_activeDebugCode tanımlandı (Sunucu e-posta göndermiyor).',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.amber.shade900,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Doğrulama kodu e-posta adresinize gönderildi.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? authService.errorMessage ?? 'Doğrulama kodu gönderilemedi.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleResendBootstrapCode() async {
    if (_resendCountdown > 0) return;

    final AuthService authService = Provider.of<AuthService>(context, listen: false);

    final VerificationResult result = await authService.requestVerificationBootstrap(
      email: _emailController.text.trim(),
    );

    if (result.success && mounted) {
      _startResendTimer();
      _activeDebugCode = result.debugCode;
      if (_activeDebugCode != null && _activeDebugCode!.isNotEmpty) {
        _verificationCodeController.text = _activeDebugCode!;
      }

      if (_activeDebugCode != null && _activeDebugCode!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Geliştirme modu: Yeni kod $_activeDebugCode tanımlandı.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.amber.shade900,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Yeni doğrulama kodu e-posta adresinize gönderildi.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? authService.errorMessage ?? 'Kod tekrar gönderilemedi.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleFinalBootstrap() async {
    if (!_formKeyStep2.currentState!.validate()) return;

    final AuthService authService = Provider.of<AuthService>(context, listen: false);

    final bool success = await authService.bootstrapAdmin(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      sicilNo: _sicilNoController.text.trim().isEmpty ? null : _sicilNoController.text.trim(),
      password: _passwordController.text,
      verificationCode: _verificationCodeController.text.trim(),
    );

    if (success && mounted) {
      _resendTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'İlk yönetici kaydı başarıyla tamamlandı! Hoş geldiniz.',
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
            authService.errorMessage ?? 'İlk yönetici kaydı sırasında hata oluştu.',
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
          'İlk Yönetici Kaydı (Bootstrap)',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // System Setup Info Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.admin_panel_settings_rounded, color: Colors.blue.shade900, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Sistem Kurulumu',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sistemde henüz kullanıcı yok. İlk yönetici (Admin) hesabını oluşturuyorsunuz.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.blue.shade800,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Step Indicator Bar
                    _buildStepIndicator(),
                    const SizedBox(height: 24),

                    // Header info
                    Text(
                      _currentStep == 1
                        ? 'Yönetici Bilgilerini Giriniz'
                        : 'E-posta Doğrulama Kodu',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentStep == 1
                        ? 'Davet koduna ihtiyaç duymadan ilk yönetici hesabınızı tanımlayın.'
                        : 'E-postanıza gönderilen 6 haneli doğrulama kodunu giriniz.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textLight,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // STEP 1 FORM
                    if (_currentStep == 1) _buildStep1Form(authService),

                    // STEP 2 FORM
                    if (_currentStep == 2) _buildStep2Form(authService),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.person_outline, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '1. Admin Bilgileri',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _currentStep == 2 ? AppTheme.primaryColor : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.mark_email_read_outlined,
                  color: _currentStep == 2 ? Colors.white : AppTheme.textLight,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '2. Doğrulama',
                  style: GoogleFonts.inter(
                    color: _currentStep == 2 ? Colors.white : AppTheme.textLight,
                    fontWeight: _currentStep == 2 ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1Form(AuthService authService) {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
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

          // Email (Mandatory)
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-posta Adresi *',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'admin@btselektrik.com',
              helperText: 'Doğrulama kodu bu e-posta adresine gönderilecektir.',
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'E-posta adresi zorunludur';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Geçerli bir e-posta adresi giriniz';
              }
              return null;
            },
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
              hintText: 'ADM001',
            ),
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
              helperText: 'En az 8 karakter olmalıdır',
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
          const SizedBox(height: 28),

          // Request Code Button
          ElevatedButton(
            onPressed: authService.isLoading ? null : _handleRequestBootstrapCode,
            child: authService.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Doğrulama Kodu Gönder',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Form(AuthService authService) {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // DEV MODE BANNER
          if (_activeDebugCode != null && _activeDebugCode!.isNotEmpty) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.developer_mode_rounded, color: Colors.amber.shade900, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.amber.shade900, height: 1.4),
                        children: <TextSpan>[
                          const TextSpan(
                            text: 'Geliştirme / Test Modu: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: 'Kod '),
                          TextSpan(
                            text: _activeDebugCode,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const TextSpan(
                            text: ' (Sunucu e-posta göndermiyor, otomatik tanımlandı).',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Verification Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              children: <Widget>[
                const Icon(Icons.mark_email_read_rounded, color: AppTheme.primaryColor, size: 36),
                const SizedBox(height: 8),
                Text(
                  'Doğrulama Kodu Gönderildi',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                    children: <TextSpan>[
                      const TextSpan(text: '6 haneli doğrulama kodu '),
                      TextSpan(
                        text: _emailController.text.trim(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                      const TextSpan(text: ' adresine gönderilmiştir. Kod 10 dakika süreyle geçerlidir.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Verification Code Input Field
          TextFormField(
            controller: _verificationCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              labelText: '6 Haneli Doğrulama Kodu *',
              hintText: '123456',
              counterText: '',
              prefixIcon: const Icon(Icons.pin_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Doğrulama kodu zorunludur';
              }
              if (value.trim().length < 6) {
                return 'Doğrulama kodu 6 haneli olmalıdır';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Resend Code & Cooldown Timer Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Kodu almadınız mı?',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: (_resendCountdown > 0 || authService.isLoading)
                  ? null
                  : _handleResendBootstrapCode,
                child: Text(
                  _resendCountdown > 0
                    ? 'Kodu Tekrar Gönder (${_resendCountdown}s)'
                    : 'Kodu Tekrar Gönder',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: _resendCountdown > 0 ? Colors.grey : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Final Bootstrap Button
          ElevatedButton(
            onPressed: authService.isLoading ? null : _handleFinalBootstrap,
            child: authService.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'İlk Yönetici Hesabını Oluştur',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
          ),
          const SizedBox(height: 12),

          // Back to Step 1 Button
          OutlinedButton.icon(
            onPressed: authService.isLoading ? null : () {
              setState(() {
                _currentStep = 1;
              });
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: Text(
              'Bilgileri Düzenle / E-postayı Değiştir',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
