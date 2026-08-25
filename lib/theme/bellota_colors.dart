import 'package:flutter/material.dart';

class BellotaColors {
  BellotaColors._();

  static const Color chilero = Color(0xFFD35D53);
  static const Color melon = Color(0xFFEE8658);
  static const Color nancite = Color(0xFFF7EACC);
  static const Color basilica = Color(0xFFFFF3E0);
  static const Color chiltoma = Color(0xFFB5C9A1);
  static const Color asuncion = Color(0xFFB0C4D8);
  
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color textoDark = Color(0xFF3D2B27);
  static const Color textoMedio = Color(0xFF7A4F47);
  static const Color gradienteClaro = Color(0xFFE07A6A);
  static const Color gradienteOscuro = Color(0xFFC44B41);

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8897A),
      Color(0xFFD35D53),
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFEE8658),
      Color(0xFFD35D53),
    ],
  );
}
