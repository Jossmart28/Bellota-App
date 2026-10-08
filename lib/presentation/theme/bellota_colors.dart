import 'package:flutter/material.dart';

@immutable
class BellotaColors extends ThemeExtension<BellotaColors> {
  final Color chilero;
  final Color melon;
  final Color nancite;
  final Color basilica;
  final Color chiltoma;
  final Color asuncion;
  final Color blanco;
  final Color textoDark;
  final Color textoMedio;
  final Color gradienteClaro;
  final Color gradienteOscuro;

  const BellotaColors({
    required this.chilero,
    required this.melon,
    required this.nancite,
    required this.basilica,
    required this.chiltoma,
    required this.asuncion,
    required this.blanco,
    required this.textoDark,
    required this.textoMedio,
    required this.gradienteClaro,
    required this.gradienteOscuro,
  });

  // Light Theme Colors
  static const light = BellotaColors(
    chilero: Color(0xFFD35D53),
    melon: Color(0xFFEE8658),
    nancite: Color(0xFFF7EACC),
    basilica: Color(0xFFFFF3E0),
    chiltoma: Color(0xFFB5C9A1),
    asuncion: Color(0xFFB0C4D8),
    blanco: Color(0xFFFFFFFF),
    textoDark: Color(0xFF3D2B27),
    textoMedio: Color(0xFF7A4F47),
    gradienteClaro: Color(0xFFE07A6A),
    gradienteOscuro: Color(0xFFC44B41),
  );

  // Dark Theme Colors
  static const dark = BellotaColors(
    chilero: Color(0xFFA5453D),
    melon: Color(0xFFB5613D),
    nancite: Color(0xFF2C2821),
    basilica: Color(0xFF1F1B17),
    chiltoma: Color(0xFF7E8F6F),
    asuncion: Color(0xFF7D8F9F),
    blanco: Color(0xFF1E1E1E),
    textoDark: Color(0xFFE8DFD8),
    textoMedio: Color(0xFFA88D87),
    gradienteClaro: Color(0xFF9E5044),
    gradienteOscuro: Color(0xFF8B3128),
  );

  LinearGradient get splashGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gradienteClaro,
      chilero,
    ],
  );

  LinearGradient get buttonGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      melon,
      chilero,
    ],
  );

  @override
  BellotaColors copyWith({
    Color? chilero,
    Color? melon,
    Color? nancite,
    Color? basilica,
    Color? chiltoma,
    Color? asuncion,
    Color? blanco,
    Color? textoDark,
    Color? textoMedio,
    Color? gradienteClaro,
    Color? gradienteOscuro,
  }) {
    return BellotaColors(
      chilero: chilero ?? this.chilero,
      melon: melon ?? this.melon,
      nancite: nancite ?? this.nancite,
      basilica: basilica ?? this.basilica,
      chiltoma: chiltoma ?? this.chiltoma,
      asuncion: asuncion ?? this.asuncion,
      blanco: blanco ?? this.blanco,
      textoDark: textoDark ?? this.textoDark,
      textoMedio: textoMedio ?? this.textoMedio,
      gradienteClaro: gradienteClaro ?? this.gradienteClaro,
      gradienteOscuro: gradienteOscuro ?? this.gradienteOscuro,
    );
  }

  @override
  BellotaColors lerp(ThemeExtension<BellotaColors>? other, double t) {
    if (other is! BellotaColors) {
      return this;
    }
    return BellotaColors(
      chilero: Color.lerp(chilero, other.chilero, t)!,
      melon: Color.lerp(melon, other.melon, t)!,
      nancite: Color.lerp(nancite, other.nancite, t)!,
      basilica: Color.lerp(basilica, other.basilica, t)!,
      chiltoma: Color.lerp(chiltoma, other.chiltoma, t)!,
      asuncion: Color.lerp(asuncion, other.asuncion, t)!,
      blanco: Color.lerp(blanco, other.blanco, t)!,
      textoDark: Color.lerp(textoDark, other.textoDark, t)!,
      textoMedio: Color.lerp(textoMedio, other.textoMedio, t)!,
      gradienteClaro: Color.lerp(gradienteClaro, other.gradienteClaro, t)!,
      gradienteOscuro: Color.lerp(gradienteOscuro, other.gradienteOscuro, t)!,
    );
  }
}

// Extension to make it easier to use: Theme.of(context).bellotaColors
extension BellotaColorsExtension on ThemeData {
  BellotaColors get bellotaColors => extension<BellotaColors>() ?? BellotaColors.light;
}
