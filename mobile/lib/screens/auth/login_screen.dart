import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isAdminMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final AuthService authService = Provider.of<AuthService>(context, listen: false);
    
    final bool success = await authService.login(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text,
      isAdminMode: _isAdminMode,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<dynamic>(builder: (BuildContext context) => const HomeScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authService.errorMessage ?? 'Giriş başarısız oldu.',
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
      body: Row(
        children: <Widget>[
          // Side panel for tablet decoration
          if (isTablet)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            size: 60,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'TrafoReport',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Saha bakım ve test ölçümlerinizi dijitalleştirin. İmzaya hazır Excel raporlarınızı anında üretin.',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.white70,
                            height: 1.5,
                          ),

                        ),
                        const SizedBox(height: 40),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Main Form Panel
          Expanded(
            flex: 6,
            child: Container(
              color: AppTheme.backgroundColor,
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Small Mobile Header
                          if (!isTablet) ...<Widget>[
                            const Center(
                              child: Icon(
                                Icons.bolt_rounded,
                                size: 50,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'TrafoReport',
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'B.T.S. Elektrik Raporlama Sistemi',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Title and Subtitle
                          Text(
                            _isAdminMode ? 'Yönetici Girişi' : 'Çalışan Girişi',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isAdminMode 
                              ? 'Admin paneline erişim için kimlik bilgilerinizi girin' 
                              : 'Saha raporları oluşturmak ve yönetmek için giriş yapın',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Login Mode Toggle Tabs
                          Container(
                            height: 52,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderLight, width: 1.5),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isAdminMode = false),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: !_isAdminMode ? AppTheme.primaryColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Çalışan',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: !_isAdminMode ? Colors.white : AppTheme.textLight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isAdminMode = true),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _isAdminMode ? AppTheme.primaryColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Yönetici',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: _isAdminMode ? Colors.white : AppTheme.textLight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // E-posta / Sicil No Field
                          TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'E-posta veya Sicil No',
                              hintText: 'ornek@btselektrik.com veya 12345',
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (String? value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Bu alan zorunludur';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Şifre Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Şifre',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppTheme.textLight,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Şifre zorunludur';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          ElevatedButton(
                            onPressed: authService.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: authService.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _isAdminMode ? 'Yönetici Girişi Yap' : 'Giriş Yap',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                          ),
                          const SizedBox(height: 20),

                          // Register Link (Only for Employee)
                          if (!_isAdminMode) ...<Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(
                                  'Hesabınız yok mu? ',
                                  style: GoogleFonts.inter(color: AppTheme.textLight),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<dynamic>(builder: (BuildContext context) => const RegisterScreen()),
                                    );
                                  },
                                  child: Text(
                                    'Kayıt Ol',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],


                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
