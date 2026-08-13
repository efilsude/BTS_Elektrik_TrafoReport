import 'dart:async';
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
  final GlobalKey<FormState> _formKeyStep1 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyStep2 = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _operatorTitleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _sicilNoController = TextEditingController();
  final TextEditingController _ekipnetNoController = TextEditingController();
  final TextEditingController _diplomaNoController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  int _currentStep = 1; // Step 1: Info & Request Code, Step 2: Enter Verification Code
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _activeDebugCode; // Received when EMAIL_ENABLED=false on backend


  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _fullNameController.dispose();
    _operatorTitleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _sicilNoController.dispose();
    _ekipnetNoController.dispose();
    _diplomaNoController.dispose();
    _inviteCodeController.dispose();
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

  // Step 1: Validate form & request email verification code from backend
  Future<void> _handleRequestVerification() async {
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

    final VerificationResult result = await authService.requestVerificationCode(
      email: _emailController.text.trim(),
      inviteCode: _inviteCodeController.text.trim(),
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

  // Resend verification code with 60-second cooldown check
  Future<void> _handleResendVerification() async {
    if (_resendCountdown > 0) return;

    final AuthService authService = Provider.of<AuthService>(context, listen: false);

    final VerificationResult result = await authService.requestVerificationCode(
      email: _emailController.text.trim(),
      inviteCode: _inviteCodeController.text.trim(),
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

  // Step 2: Validate verification code & finalize user registration
  Future<void> _handleFinalRegister() async {
    if (!_formKeyStep2.currentState!.validate()) return;

    final AuthService authService = Provider.of<AuthService>(context, listen: false);

    final bool success = await authService.register(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      operatorTitle: _operatorTitleController.text.trim(),
      sicilNo: _sicilNoController.text.trim().isEmpty ? null : _sicilNoController.text.trim(),
      ekipnetNo: _ekipnetNoController.text.trim().isEmpty ? null : _ekipnetNoController.text.trim(),
      diplomaNo: _diplomaNoController.text.trim().isEmpty ? null : _diplomaNoController.text.trim(),
      inviteCode: _inviteCodeController.text.trim(),
      verificationCode: _verificationCodeController.text.trim(),
      password: _passwordController.text,
      isAdminMode: false, // Role is determined by invite code on the backend
    );

    if (success && mounted) {
      _resendTimer?.cancel();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Step Indicator Bar
                    _buildStepIndicator(),
                    const SizedBox(height: 24),

                    // Header info
                    Text(
                      'Yeni Hesap Oluştur',
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
                        ? 'Davet kodunuz yönetici veya çalışan yetkisi tanımlar; kodu yöneticinizden alın.'
                        : 'E-postanıza gelen 6 haneli doğrulama kodunu girerek kaydı tamamlayın.',
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
                  '1. Bilgiler',
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
                  '2. E-posta Doğrulama',
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
          // Info banner — role determined by invite code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Davet kodunuz yönetici veya çalışan yetkisi tanımlar; kodu yöneticinizden alın.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppTheme.primaryColor,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
              hintText: 'ahmet@btselektrik.com',
              helperText: 'Doğrulama kodu bu e-postaya gönderilecektir.',
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

          // Unvan (Mandatory)
          TextFormField(
            controller: _operatorTitleController,
            decoration: const InputDecoration(
              labelText: 'Unvan (Elektrik Mühendisi vb.) *',
              prefixIcon: Icon(Icons.work_outline_rounded),
              hintText: 'Elektrik Mühendisi',
            ),
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Unvan bilgisi zorunludur';
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

          // EKİPNET No (Optional)
          TextFormField(
            controller: _ekipnetNoController,
            decoration: const InputDecoration(
              labelText: 'EKİPNET Kayıt No (İsteğe Bağlı)',
              prefixIcon: Icon(Icons.verified_outlined),
              hintText: 'EKP-98765',
            ),
          ),
          const SizedBox(height: 16),

          // Diploma No (Optional)
          TextFormField(
            controller: _diplomaNoController,
            decoration: const InputDecoration(
              labelText: 'Diploma / Oda Sicil No (İsteğe Bağlı)',
              prefixIcon: Icon(Icons.school_outlined),
              hintText: 'DIP-54321',
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
            onPressed: authService.isLoading ? null : _handleRequestVerification,
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
          // DEV MODE BANNER (When debug_code is present in response when EMAIL_ENABLED=false)
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
                      const TextSpan(text: '6 haneli e-posta doğrulama kodu '),
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
                  : _handleResendVerification,
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

          // Final Register Button
          ElevatedButton(
            onPressed: authService.isLoading ? null : _handleFinalRegister,
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
