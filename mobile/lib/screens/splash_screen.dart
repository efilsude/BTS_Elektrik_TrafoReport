import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth/bootstrap_screen.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Hata durumu — bootstrap-status network/timeout hatasında kullanıcıya gösteriliyor
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Auth durumu + bootstrap-status kontrolü.
  /// Network/timeout hatasında sonsuz spinner yerine hata ekranı gösterilir.
  Future<void> _checkAuthentication() async {
    if (_hasError) {
      // "Tekrar Dene" butonu tıklandıysa hata state'ini sıfırla
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    }

    final AuthService authService = Provider.of<AuthService>(context, listen: false);

    // initAuth + minimum splash süresi eş zamanlı bekle
    await Future.wait<void>(<Future<void>>[
      authService.initAuth(),
      Future<void>.delayed(const Duration(milliseconds: 2200)),
    ]);

    if (!mounted) return;

    if (authService.isAuthenticated) {
      _navigateTo(const HomeScreen());
      return;
    }

    // Kimlik doğrulanmadıysa bootstrap-status'u sorgula
    bool needsBootstrap = false;
    try {
      needsBootstrap = await authService.checkBootstrapStatus();
    } catch (e) {
      // Ağ/timeout/sunucu hatası → hata ekranı göster, sonsuz splash olmasın
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Sunucuya bağlanılamadı.\nİnternet bağlantınızı kontrol edin ve tekrar deneyin.';
        });
      }
      return;
    }

    if (!mounted) return;

    final Widget target = needsBootstrap
        ? const FirstAdminBootstrapScreen()
        : const LoginScreen();
    _navigateTo(target);
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<dynamic>(
        pageBuilder: (BuildContext ctx, Animation<double> a, Animation<double> b) => screen,
        transitionsBuilder: (BuildContext ctx, Animation<double> a, Animation<double> b, Widget child) {
          return FadeTransition(opacity: a, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: _hasError ? _buildErrorState() : _buildLoadingState(),
      ),
    );
  }

  /// Normal splash — logo + spinner
  Widget _buildLoadingState() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Logo Icon Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 80,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'TrafoReport',
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'B.T.S. Elektrik Trafo Bakım & Test',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 80),
                const SpinKitThreeBounce(
                  color: Colors.white70,
                  size: 25,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Ağ/timeout hatası splash — Türkçe hata mesajı + eylem butonları
  Widget _buildErrorState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Bağlantı Hatası',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // Tekrar Dene
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'Tekrar Dene',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _checkAuthentication,
                ),
              ),
              const SizedBox(height: 14),

              // Giriş Ekranına Git (sunucu çevrimdışı olsa bile giriş yapılabilir durumda ise)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.login_rounded, color: Colors.white70),
                  label: Text(
                    'Giriş Ekranına Git',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _navigateTo(const LoginScreen()),
                ),
              ),

              // DEV ONLY — sunucu adresi bilgisi (release'de gizli)
              if (!kReleaseMode) ...<Widget>[
                const SizedBox(height: 24),
                Text(
                  'Sunucu: ${_getApiBaseUrl()}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getApiBaseUrl() {
    // AppConfig'e erişim — dev-only gösterim
    try {
      final AuthService authService = Provider.of<AuthService>(context, listen: false);
      // isMockMode getter üzerinden mevcut modu da gösterebiliriz
      return authService.isMockMode ? 'Mock Mod' : '(config\'e bakın)';
    } catch (_) {
      return '—';
    }
  }
}
