import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/report_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<AuthService>(create: (BuildContext context) => AuthService()),
        ChangeNotifierProvider<ReportService>(create: (BuildContext context) => ReportService()),
      ],
      child: const TrafoReportApp(),
    ),
  );
}

class TrafoReportApp extends StatelessWidget {
  const TrafoReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrafoReport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Turkish language configuration
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('tr', 'TR'), // Turkish
      ],
      locale: const Locale('tr', 'TR'),

      home: const SplashScreen(),
    );
  }
}
