import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/bellota_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BellotaApp());
}

class BellotaApp extends StatelessWidget {
  const BellotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bellota · Calendario Menstrual',
      debugShowCheckedModeBanner: false,
      theme: BellotaTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
