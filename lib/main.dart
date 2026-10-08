import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/core/errors/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';
import 'package:bellotadevelopment/l10n/miskito_fallback_delegate.dart';

import 'package:bellotadevelopment/presentation/theme/bellota_theme.dart';
import 'package:bellotadevelopment/presentation/theme/theme_notifier.dart';
import 'package:bellotadevelopment/presentation/screens/auth/splash_screen.dart';
import 'package:bellotadevelopment/presentation/screens/auth/auth_screen.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:bellotadevelopment/core/services/notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Ejecutar inicializaciones en paralelo para optimizar startup
    await initDependencies();
    
    await Future.wait([
      themeNotifier.load(),
      languageNotifier.load(),
      NotificationService.instance.initialize(),
    ]);

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: const Color(0xFFF7EACC), // nancite
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/bella_mascot.png', height: 120),
              const SizedBox(height: 24),
              const Text('�Ups! Bella se tropez� con un cable.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3D2B27))),
              const SizedBox(height: 12),
              const Text('Algo sali� mal, pero ya lo estamos limpiando. Intenta abrir esta pantalla de nuevo.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF7A4F47))),
            ],
          ),
        ),
      );
    };
    runApp(const BellotaApp());
  } catch (e) {
    AppLogger.d('Fatal error during startup: $e');
  }
}

class BellotaApp extends StatelessWidget {
  const BellotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, mode, _) {
            return MaterialApp(
              title: 'Bellota - Calendario Menstrual',
              color: const Color(0xFFFFFFFF),
              debugShowCheckedModeBanner: false,
              theme: BellotaTheme.lightTheme,
              darkTheme: BellotaTheme.darkTheme,
              themeMode: mode,
                            localizationsDelegates: const [
                AppLocalizations.delegate,
                MiskitoMaterialLocalizationsDelegate(),
                MiskitoCupertinoLocalizationsDelegate(),
                MiskitoWidgetsLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale(lang),
              home: const SplashScreen(),
            );
          },
        );
      }
    );
  }
}



