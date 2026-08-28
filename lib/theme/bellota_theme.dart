import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bellota_colors.dart';

class BellotaTheme {
  BellotaTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BellotaColors.chilero,
        primary: BellotaColors.chilero,
        secondary: BellotaColors.melon,
        surface: BellotaColors.basilica,
        onPrimary: BellotaColors.blanco,
        onSecondary: BellotaColors.blanco,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Estrella',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: BellotaColors.blanco,
          letterSpacing: 1.2,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: BellotaColors.textoDark,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: BellotaColors.textoDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BellotaColors.textoDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BellotaColors.textoDark,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: BellotaColors.textoMedio,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: BellotaColors.textoDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: BellotaColors.textoMedio,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: BellotaColors.textoMedio,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: BellotaColors.blanco,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: BellotaColors.blanco,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BellotaColors.chilero,
          foregroundColor: BellotaColors.blanco,
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.15),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: BellotaColors.blanco.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: BellotaColors.blanco.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: BellotaColors.blanco, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          color: BellotaColors.blanco.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: BellotaColors.blanco.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        prefixIconColor: BellotaColors.blanco.withValues(alpha: 0.8),
        suffixIconColor: BellotaColors.blanco.withValues(alpha: 0.8),
      ),
      scaffoldBackgroundColor: BellotaColors.nancite,
      appBarTheme: AppBarTheme(
        backgroundColor: BellotaColors.chilero,
        foregroundColor: BellotaColors.blanco,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BellotaColors.blanco,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    Color darkBg = Color(0xFF1A0F0D);
    Color darkCard = Color(0xFF2C1A17);
    Color darkTextPrimary = Color(0xFFF2E4D4);
    Color darkTextSecondary = Color(0xFFBB9A90);
    Color darkChilero = Color(0xFFC25048);
    Color darkMelon = Color(0xFFD9754A);
    Color darkBorder = Color(0xFF3D2420);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: darkChilero,
        secondary: darkMelon,
        surface: darkCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
      ),
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      dividerColor: darkBorder,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Estrella',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          letterSpacing: 1.2,
        ),
        displayMedium: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w600, color: darkTextPrimary),
        headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: darkTextPrimary),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: darkTextSecondary),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: darkTextPrimary),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: darkTextSecondary),
        bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w300, color: darkTextSecondary),
        labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5),
        labelMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkChilero,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: darkChilero, width: 2)),
        hintStyle: GoogleFonts.poppins(color: darkTextSecondary, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: darkTextSecondary, fontSize: 14),
        prefixIconColor: darkTextSecondary,
        suffixIconColor: darkTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
      ),
    );
  }
}