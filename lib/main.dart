import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/bellota_theme.dart';
import 'theme/theme_notifier.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cargar preferencia de tema guardada antes de mostrar la app
  await themeNotifier.load();

  runApp(BellotaApp());
}

class BellotaApp extends StatelessWidget {
  const BellotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Bellota · Calendario Menstrual',
          debugShowCheckedModeBanner: false,
          theme: BellotaTheme.lightTheme,
          darkTheme: BellotaTheme.darkTheme,
          themeMode: mode,
          home: SplashScreen(),
        );
      },
    );
  }
}
