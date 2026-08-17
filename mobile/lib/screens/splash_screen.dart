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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAuthentication();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check local session and local SQLite user count for initial setup vs login
  Future<void> _checkAuthentication() async {
    final AuthService authService = Provider.of<AuthService>(context, listen: false);

    await Future.wait<void>(<Future<void>>[
      authService.initAuth(),
      Future<void>.delayed(const Duration(milliseconds: 1800)),
    ]);

    if (!mounted) return;

    if (authService.isAuthenticated) {
      _navigateTo(const HomeScreen());
      return;
    }

    final bool needsBootstrap = await authService.checkBootstrapStatus();

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
        child: AnimatedBuilder(
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
        ),
      ),
    );
  }
}
