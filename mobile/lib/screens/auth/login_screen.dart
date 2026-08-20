import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';

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
      body: SafeArea(
        child: Row(
          children: <Widget>[
            // Side panel for tablet decoration
            if (isTablet)
              Expanded(
                flex: 5,
                child: Container(
                  color: AppTheme.primaryDark,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 140),
                            child: Image.asset(
                              'assets/images/btsLogo_1.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'TrafoReport',
                            style: GoogleFonts.outfit(
                              fontSize: 44,
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
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // Small Mobile Header
                            if (!isTablet) ...<Widget>[
                              Center(
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 220, maxHeight: 90),
                                  child: Image.asset(
                                    'assets/images/btsLogo_1.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'TrafoReport',
                                  style: GoogleFonts.outfit(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Text(
                                  'B.T.S. Elektrik Raporlama Sistemi',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
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
                                            fontWeight: FontWeight.bold,
                                            color: !_isAdminMode ? AppTheme.primaryDark : AppTheme.textLight,
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
                                            fontWeight: FontWeight.bold,
                                            color: _isAdminMode ? AppTheme.primaryDark : AppTheme.textLight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Telefon / E-posta Field
                            TextFormField(
                              controller: _identifierController,
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: 'Telefon veya E-posta',
                                hintText: '05XXXXXXXXX veya e-posta',
                                prefixIcon: Icon(Icons.person_outline),
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
                                  tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
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

                            // Information note
                            Text(
                              'Hesap için yöneticinize başvurun.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textLight,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
      ),
    );
  }
}
