import 'package:flutter/material.dart';
import 'theme_notifier.dart';

class BellotaColors {
  BellotaColors._();

  static Color get chilero => themeNotifier.isDarkMode ? Color(0xFFA5453D) : Color(0xFFD35D53);
  static Color get melon => themeNotifier.isDarkMode ? Color(0xFFB5613D) : Color(0xFFEE8658);
  static Color get nancite => themeNotifier.isDarkMode ? Color(0xFF2C2821) : Color(0xFFF7EACC);
  static Color get basilica => themeNotifier.isDarkMode ? Color(0xFF1F1B17) : Color(0xFFFFF3E0);
  static Color get chiltoma => themeNotifier.isDarkMode ? Color(0xFF7E8F6F) : Color(0xFFB5C9A1);
  static Color get asuncion => themeNotifier.isDarkMode ? Color(0xFF7D8F9F) : Color(0xFFB0C4D8);
  
  static Color get blanco => themeNotifier.isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFFFFFFF);
  static Color get textoDark => themeNotifier.isDarkMode ? Color(0xFFE8DFD8) : Color(0xFF3D2B27);
  static Color get textoMedio => themeNotifier.isDarkMode ? Color(0xFFA88D87) : Color(0xFF7A4F47);
  static Color get gradienteClaro => themeNotifier.isDarkMode ? Color(0xFF9E5044) : Color(0xFFE07A6A);
  static Color get gradienteOscuro => themeNotifier.isDarkMode ? Color(0xFF8B3128) : Color(0xFFC44B41);

  static LinearGradient get splashGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      themeNotifier.isDarkMode ? Color(0xFF8B3128) : Color(0xFFE8897A),
      themeNotifier.isDarkMode ? Color(0xFF5A1C16) : Color(0xFFD35D53),
    ],
  );

  static LinearGradient get buttonGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      melon,
      chilero,
    ],
  );
}
