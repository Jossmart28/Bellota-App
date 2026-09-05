import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_keys.dart';

/// Notificador global de tema (claro / oscuro).
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  bool get isDarkMode => value == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(AppKeys.darkMode) ?? false;
    value = dark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppKeys.darkMode, isDarkMode);
  }

  Future<void> setDark(bool dark) async {
    value = dark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppKeys.darkMode, isDarkMode);
  }
}

/// Instancia global accesible desde cualquier pantalla.
final themeNotifier = ThemeNotifier();
