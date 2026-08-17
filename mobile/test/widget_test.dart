import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trafo_report_mobile/screens/splash_screen.dart';
import 'package:trafo_report_mobile/services/auth_service.dart';
import 'package:trafo_report_mobile/services/report_service.dart';
import 'package:trafo_report_mobile/theme/app_theme.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final AuthService authService = AuthService();
    final ReportService reportService = ReportService();

    await tester.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<dynamic>>[
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<ReportService>.value(value: reportService),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  });
}


