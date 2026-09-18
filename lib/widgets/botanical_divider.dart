import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/bellota_colors.dart';

/// Divisor decorativo estilo cottagecore/botánico.
/// Dibuja pequeñas hojitas alternas a lo largo de una línea central.
/// 100% CustomPainter — sin imágenes ni dependencias externas.
class BotanicalDivider extends StatelessWidget {
  final double height;
  final double opacity;

  const BotanicalDivider({
    super.key,
    this.height = 20,
    this.opacity = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BotanicalLinePainter(
          lineColor: colors.chiltoma.withValues(alpha: opacity * 0.6),
          leafColor: colors.chiltoma.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _BotanicalLinePainter extends CustomPainter {
  final Color lineColor;
  final Color leafColor;
  _BotanicalLinePainter({required this.lineColor, required this.leafColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height / 2;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

    final leafPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.fill;

    double x = 20;
    int i = 0;
    while (x < size.width - 20) {
      final bool above = i % 2 == 0;
      final double leafY = above ? y - 5 : y + 5;
      final double angle = above ? -math.pi / 4 : math.pi / 4;
      _drawLeaf(canvas, leafPaint, Offset(x, leafY), angle);
      x += 28;
      i++;
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint, Offset center, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, -5)
      ..cubicTo(3, -3, 3, 3, 0, 5)
      ..cubicTo(-3, 3, -3, -3, 0, -5)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BotanicalLinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor || oldDelegate.leafColor != leafColor;
}
