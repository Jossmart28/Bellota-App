import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bellota_colors.dart';

class BellotaTheme {
  BellotaTheme._();

  static final ThemeData lightTheme = ThemeData(
    extensions: const [BellotaColors.light],
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BellotaColors.light.chilero,
      primary: BellotaColors.light.chilero,
      secondary: BellotaColors.light.melon,
      surface: BellotaColors.light.basilica,
      onPrimary: BellotaColors.light.blanco,
      onSecondary: BellotaColors.light.blanco,
    ),
    textTheme: TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Estrella',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: BellotaColors.light.blanco,
          letterSpacing: 1.2,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: BellotaColors.light.textoDark,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: BellotaColors.light.textoDark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BellotaColors.light.textoDark,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: BellotaColors.light.textoDark,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: BellotaColors.light.textoMedio,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: BellotaColors.light.textoDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: BellotaColors.light.textoMedio,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: BellotaColors.light.textoMedio,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: BellotaColors.light.blanco,
          letterSpacing: 0.5,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: BellotaColors.light.blanco,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BellotaColors.light.chilero,
          foregroundColor: BellotaColors.light.blanco,
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
          borderSide: BorderSide(color: BellotaColors.light.blanco.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: BellotaColors.light.blanco.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: BellotaColors.light.blanco, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(
          color: BellotaColors.light.blanco.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: BellotaColors.light.blanco.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        prefixIconColor: BellotaColors.light.blanco.withValues(alpha: 0.8),
        suffixIconColor: BellotaColors.light.blanco.withValues(alpha: 0.8),
      ),
      scaffoldBackgroundColor: BellotaColors.light.nancite,
      appBarTheme: AppBarTheme(
        backgroundColor: BellotaColors.light.chilero,
        foregroundColor: BellotaColors.light.blanco,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: BellotaColors.light.blanco,
        ),
      ),
    );

  static final ThemeData darkTheme = ThemeData(
    extensions: const [BellotaColors.dark],
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: BellotaColors.dark.chilero,
      secondary: BellotaColors.dark.melon,
      surface: BellotaColors.dark.basilica,
      onPrimary: BellotaColors.dark.blanco,
      onSecondary: BellotaColors.dark.blanco,
      onSurface: BellotaColors.dark.textoDark,
    ),
    scaffoldBackgroundColor: BellotaColors.dark.nancite,
    cardColor: BellotaColors.dark.basilica,
    dividerColor: BellotaColors.dark.blanco.withValues(alpha: 0.1),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Estrella',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: BellotaColors.dark.textoDark,
        letterSpacing: 1.2,
      ),
      displayMedium: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w600, color: BellotaColors.dark.textoDark),
      headlineLarge: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: BellotaColors.dark.textoDark),
      headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: BellotaColors.dark.textoDark),
      titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: BellotaColors.dark.textoDark),
      titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: BellotaColors.dark.textoMedio),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400, color: BellotaColors.dark.textoDark),
      bodyMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: BellotaColors.dark.textoMedio),
      bodySmall: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w300, color: BellotaColors.dark.textoMedio),
      labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: BellotaColors.dark.blanco, letterSpacing: 0.5),
      labelMedium: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: BellotaColors.dark.blanco),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BellotaColors.dark.chilero,
        foregroundColor: BellotaColors.dark.blanco,
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
      fillColor: BellotaColors.dark.blanco.withValues(alpha: 0.10),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: BellotaColors.dark.blanco.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: BellotaColors.dark.blanco.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: BellotaColors.dark.chilero, width: 2),
      ),
      hintStyle: GoogleFonts.poppins(
        color: BellotaColors.dark.textoMedio.withValues(alpha: 0.8),
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.poppins(
        color: BellotaColors.dark.textoMedio.withValues(alpha: 0.8),
        fontSize: 14,
      ),
      prefixIconColor: BellotaColors.dark.textoMedio.withValues(alpha: 0.8),
      suffixIconColor: BellotaColors.dark.textoMedio.withValues(alpha: 0.8),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: BellotaColors.dark.basilica,
      foregroundColor: BellotaColors.dark.blanco,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: BellotaColors.dark.textoDark,
      ),
      iconTheme: IconThemeData(color: BellotaColors.dark.textoDark),
    ),
  );
}
