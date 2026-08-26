import 'package:flutter/material.dart';

class BellotaIcon extends StatelessWidget {
  final Color color;
  final double size;

  const BellotaIcon({
    super.key,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BellotaPainter(color: color),
    );
  }
}

class _BellotaPainter extends CustomPainter {
  final Color color;
  _BellotaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF5D4037);
    final stemRect = Rect.fromLTWH(w * 0.45, 0, w * 0.1, h * 0.15);
    canvas.drawRect(stemRect, paint);

    paint.color = const Color(0xFF795548);
    final capPath = Path()
      ..moveTo(0, h * 0.4)
      ..quadraticBezierTo(w * 0.5, -0.1 * h, w, h * 0.4)
      ..close();
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.35, w, h * 0.12), Radius.circular(w * 0.05)), paint);
    canvas.drawPath(capPath, paint);

    paint.color = color;
    final bodyPath = Path()
      ..moveTo(w * 0.1, h * 0.47)
      ..lineTo(w * 0.9, h * 0.47)
      ..quadraticBezierTo(w * 0.9, h * 0.85, w * 0.5, h)
      ..quadraticBezierTo(w * 0.1, h * 0.85, w * 0.1, h * 0.47)
      ..close();
    canvas.drawPath(bodyPath, paint);

    paint.color = Colors.white.withValues(alpha: 0.3);
    final highlightPath = Path()
      ..moveTo(w * 0.2, h * 0.55)
      ..quadraticBezierTo(w * 0.15, h * 0.7, w * 0.3, h * 0.8)
      ..quadraticBezierTo(w * 0.22, h * 0.65, w * 0.25, h * 0.55)
      ..close();
    canvas.drawPath(highlightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}