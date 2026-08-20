import 'package:flutter/material.dart';

/// Paleta de colores oficial de Bellota - Calendario Menstrual
class BellotaColors {
  BellotaColors._();

  // === COLORES PRINCIPALES ===
  /// Chilero - Rojo terracota principal #D35D53
  static const Color chilero = Color(0xFFD35D53);

  /// Melón - Naranja cálido #EE8658
  static const Color melon = Color(0xFFEE8658);

  /// Nancite - Crema dorado #F7EACC (aproximado)
  static const Color nancite = Color(0xFFF7EACC);

  /// Basílica - Crema suave #FFECC (blanco cálido)
  static const Color basilica = Color(0xFFFFF3E0);

  /// Chiltoma - Verde oliva suave
  static const Color chiltoma = Color(0xFFB5C9A1);

  /// Asunción - Azul lavanda suave
  static const Color asuncion = Color(0xFFB0C4D8);

  // === COLORES DE APOYO ===
  /// Blanco puro para textos sobre fondos oscuros
  static const Color blanco = Color(0xFFFFFFFF);

  /// Texto oscuro principal
  static const Color textoDark = Color(0xFF3D2B27);

  /// Texto medio (subtítulos)
  static const Color textoMedio = Color(0xFF7A4F47);

  /// Fondo de gradiente claro del Splash
  static const Color gradienteClaro = Color(0xFFE07A6A);

  /// Fondo de gradiente oscuro del Splash
  static const Color gradienteOscuro = Color(0xFFC44B41);

  // === GRADIENTES ===
  /// Gradiente principal del Splash (izquierda a derecha, similar a imagen)
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE8897A), // chilero claro
      Color(0xFFD35D53), // chilero
    ],
  );

  /// Gradiente del botón primario
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFEE8658), // melón
      Color(0xFFD35D53), // chilero
    ],
  );
}
