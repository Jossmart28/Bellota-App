import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

/// Encabezado de sección con patrón de costura decorativo estilo cottagecore.
/// Reemplaza el divisor plano anterior con un efecto de "hilo de punto de cruz".
class CozySectionHeader extends StatelessWidget {
  final String title;

  const CozySectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 16,
            child: CustomPaint(
              painter: _StitchDividerPainter(
                color: colors.textoMedio.withValues(alpha: 0.30),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dibuja un patrón de costura (punto – guión – punto – guión) que
/// se desvanece hacia la derecha. Sin imágenes, sin dependencias extra.
class _StitchDividerPainter extends CustomPainter {
  final Color color;
  _StitchDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dotRadius = 2.0;
    const double dashWidth = 8.0;
    const double gap = 5.0;
    final double y = size.height / 2;

    double x = 0;
    int step = 0;
    final totalWidth = size.width;

    while (x < totalWidth) {
      final double progress = 1.0 - (x / totalWidth).clamp(0.0, 1.0);
      final Paint paint = Paint()
        ..color = color.withValues(alpha: color.a * progress)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      if (step % 2 == 0) {
        canvas.drawCircle(Offset(x + dotRadius, y), dotRadius, paint);
        x += dotRadius * 2 + gap;
      } else {
        canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), paint);
        x += dashWidth + gap;
      }
      step++;
    }
  }

  @override
  bool shouldRepaint(_StitchDividerPainter oldDelegate) =>
      oldDelegate.color != color;
}
