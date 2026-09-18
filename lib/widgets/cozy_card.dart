import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

/// Tarjeta reutilizable estilo diario/cuaderno orgánico.
/// Añade sombra cálida, borde sutil y un efecto de esquina doblada
/// en la esquina superior derecha — sin imágenes externas.
class CozyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool showFoldedCorner;
  final Color? shadowColor;

  const CozyCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.showFoldedCorner = true,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;
    final bg = backgroundColor ?? colors.blanco;
    final shadow = shadowColor ?? colors.melon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.nancite.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadow.withValues(alpha: 0.09),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: child,
        ),
        if (showFoldedCorner)
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(24, 24),
              painter: _FoldedCornerPainter(
                color: colors.nancite,
                shadowColor: shadow.withValues(alpha: 0.15),
              ),
            ),
          ),
      ],
    );
  }
}

class _FoldedCornerPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  _FoldedCornerPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, shadowPaint);

    final foldPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, foldPaint);
  }

  @override
  bool shouldRepaint(_FoldedCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
