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
        displayLarge: const TextStyle(
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
          minimumSize: const Size(double.infinity, 56),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          borderSide: const BorderSide(color: BellotaColors.blanco, width: 2),
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
}