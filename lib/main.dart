import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';

import 'theme/bellota_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();



  // Orientación vertical fija
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BellotaApp());
}

/// Aplicación principal Bellota - Calendario Menstrual
class BellotaApp extends StatelessWidget {
  const BellotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bellota · Calendario Menstrual',
      debugShowCheckedModeBanner: false,
      theme: BellotaTheme.lightTheme,
      // Arranca en el Splash, que luego navega al Login
      home: const SplashScreen(),
    );
  }
}
