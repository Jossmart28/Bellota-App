import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/bellota_theme.dart';
import 'theme/theme_notifier.dart';
import 'screens/splash_screen.dart';
import 'l10n/language_notifier.dart';
import 'core/services/notification_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Ejecutar inicializaciones en paralelo para optimizar startup
    await Future.wait([
      themeNotifier.load(),
      languageNotifier.load(),
      NotificationService.instance.initialize(),
    ]);

    runApp(const BellotaApp());
  } catch (e) {
    debugPrint('Fatal error during startup: $e');
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
              title: 'Bellota · Calendario Menstrual',
              debugShowCheckedModeBanner: false,
              theme: BellotaTheme.lightTheme,
              darkTheme: BellotaTheme.darkTheme,
              themeMode: mode,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('es'),
                Locale('en'),
              ],
              home: const SplashScreen(),
            );
          },
        );
      }
    );
  }
}
