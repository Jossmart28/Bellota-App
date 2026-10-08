import 'package:flutter/material.dart';

/// Widget reutilizable que dibuja el fondo decorativo de las pantallas de onboarding
/// y autenticación de Bellota (login, registro, idioma, año de nacimiento, etc.).
///
/// Antes estaba copiado y pegado en 4 pantallas distintas como `_BackgroundPainter`.
/// Al centralizar aquí, cualquier cambio visual solo necesita hacerse en un lugar.
///
/// Ejemplo de uso:
/// ```dart
/// Stack(
///   children: [
///     BellotaBackgroundPainterWidget(overlayColor: colors.naranja),
///     // ... contenido de la pantalla
///   ],
/// )
/// ```
class BellotaBackgroundPainterWidget extends StatelessWidget {
  /// Color que se usará para las formas decorativas (normalmente un color de la paleta).
  final Color overlayColor;

  const BellotaBackgroundPainterWidget({
    super.key,
    required this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BellotaBackgroundPainter(overlayColor),
      size: Size.infinite,
    );
  }
}

class _BellotaBackgroundPainter extends CustomPainter {
  final Color overlayColor;

  const _BellotaBackgroundPainter(this.overlayColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Curva superior derecha
    paint.color = overlayColor.withValues(alpha: 0.05);
    final path1 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(
          size.width * 1.2, size.height * 0.2, size.width, size.height * 0.45)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path1, paint);

    // Curva inferior izquierda
    paint.color = overlayColor.withValues(alpha: 0.04);
    final path2 = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
          size.width * 0.3, size.height * 0.9, 0, size.height)
      ..close();
    canvas.drawPath(path2, paint);

    // Círculo decorativo superior derecho
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.12),
      size.width * 0.18,
      paint..color = overlayColor.withValues(alpha: 0.04),
    );

    // Círculo decorativo inferior izquierdo
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      size.width * 0.12,
      paint..color = overlayColor.withValues(alpha: 0.03),
    );
  }

  @override
  bool shouldRepaint(covariant _BellotaBackgroundPainter old) =>
      old.overlayColor != overlayColor;
}
