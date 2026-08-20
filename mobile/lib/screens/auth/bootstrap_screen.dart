import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../home_screen.dart';

class FirstAdminBootstrapScreen extends StatefulWidget {
  const FirstAdminBootstrapScreen({super.key});

  @override
  State<FirstAdminBootstrapScreen> createState() => _FirstAdminBootstrapScreenState();
}

class _FirstAdminBootstrapScreenState extends State<FirstAdminBootstrapScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _operatorTitleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _operatorTitleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleBootstrap() async {
    if (!_formKey.currentState!.validate()) return;

    final AuthService authService = Provider.of<AuthService>(context, listen: false);

    final bool success = await authService.bootstrapAdmin(
      fullName: _fullNameController.text.trim(),
      operatorTitle: _operatorTitleController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'İlk yönetici hesabı başarıyla oluşturuldu!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<dynamic>(builder: (_) => const HomeScreen()),
      );
    } else if (mounted && authService.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authService.errorMessage!,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final Size size = MediaQuery.of(context).size;
    final bool isWide = size.width >= 700;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: isWide ? _buildWideLayout(authService) : _buildNarrowLayout(authService),
      ),
    );
  }

  Widget _buildWideLayout(AuthService authService) {
    return Row(
      children: <Widget>[
        // Sol Bilgi Paneli
        Expanded(
          flex: 5,
          child: Container(
            color: AppTheme.primaryDark,
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  constraints: const BoxConstraints(maxWidth: 240, maxHeight: 100),
                  child: Image.asset(
                    'assets/images/btsLogo_1.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sistem Kurulumu',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'İlk Yönetici (Admin) Hesabı',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cihazınızda kayıtlı kullanıcı bulunmuyor. Sistem ana yöneticisini tanımlayarak cihazınızı kullanıma açın.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sağ Form Paneli
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildForm(authService),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(AuthService authService) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          // Üst Kompakt Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            color: AppTheme.primaryDark,
            child: Row(
              children: <Widget>[
                Container(
                  constraints: const BoxConstraints(maxWidth: 120, maxHeight: 50),
                  child: Image.asset(
                    'assets/images/btsLogo_1.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Sistem Kurulumu',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'İlk Yönetici Kaydı',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Alt Form Alanı
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _buildForm(authService),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AuthService authService) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Yönetici Hesabı Oluştur',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lütfen yöneticinin iletişim ve giriş bilgilerini eksiksiz girin.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 24),

          // Ad Soyad
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Ad Soyad *',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            validator: Validators.validateFullName,
          ),
          const SizedBox(height: 16),

          // Unvan
          TextFormField(
            controller: _operatorTitleController,
            decoration: const InputDecoration(
              labelText: 'Unvan (Elektrik Mühendisi vb.) *',
              prefixIcon: Icon(Icons.work_rounded),
            ),
            validator: Validators.validateTitle,
          ),
          const SizedBox(height: 16),

          // Telefon
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefon Numarası *',
              prefixIcon: Icon(Icons.phone_rounded),
              hintText: '05XXXXXXXXX',
            ),
            validator: Validators.validatePhone,
          ),
          const SizedBox(height: 16),

          // E-posta (Opsiyonel)
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-posta Adresi (Opsiyonel)',
              prefixIcon: Icon(Icons.email_rounded),
            ),
            validator: Validators.validateEmailOptional,
          ),
          const SizedBox(height: 16),

          // Şifre
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Şifre *',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (String? val) => Validators.validatePassword(val, minLength: 4),
          ),
          const SizedBox(height: 16),

          // Şifre Tekrar
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Şifre Tekrar *',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                tooltip: _obscureConfirmPassword ? 'Şifreyi göster' : 'Şifreyi gizle',
                onPressed: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            validator: (String? val) => Validators.validateConfirmPassword(val, _passwordController.text),
          ),
          const SizedBox(height: 24),

          // Gönder Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authService.isLoading ? null : _handleBootstrap,
              child: authService.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Yönetici Kaydını Tamamla',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
