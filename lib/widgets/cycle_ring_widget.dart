import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/services/cycle_service.dart';

// ════════════════════════════════════════════════════════════════
// Widget de Anillo de Ciclo con Flecha Indicadora
// ════════════════════════════════════════════════════════════════
class CycleRingWidget extends StatelessWidget {
  final CycleInfo? cycleInfo;
  final Color phaseColor;
  final Color phaseBorder;
  final String phaseName;
  final String? todayMood;
  final double size;

  const CycleRingWidget({
    super.key,
    required this.cycleInfo,
    required this.phaseColor,
    required this.phaseBorder,
    required this.phaseName,
    this.todayMood,
    this.size = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Anillo de ciclo con flecha
        CustomPaint(
          size: Size(size, size),
          painter: _CycleRingWithArrowPainter(
            cycleInfo: cycleInfo,
            phaseColor: phaseColor,
          ),
        ),
        // Centro: nombre de fase
        Container(
          width: size * 0.65,
          height: size * 0.65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: phaseColor.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Día',
                  style: TextStyle(
                    fontSize: size * 0.09,
                    color: phaseBorder,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${cycleInfo?.cycleDay ?? '?'}',
                  style: TextStyle(
                    fontSize: size * 0.20,
                    color: phaseBorder,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  phaseName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size * 0.075,
                    color: phaseBorder,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Custom Painter: Anillo de ciclo con arcos de fase + flecha
// ════════════════════════════════════════════════════════════════
class _CycleRingWithArrowPainter extends CustomPainter {
  final CycleInfo? cycleInfo;
  final Color phaseColor;

  _CycleRingWithArrowPainter({
    required this.cycleInfo,
    required this.phaseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double totalDays = (cycleInfo?.averageCycleLength ?? 28).toDouble();
    const double periodDays = 5;
    final double follicularDays = totalDays - periodDays - 14;
    const double fertileDays = 5;
    final double lutealDays = totalDays - periodDays - (follicularDays > 0 ? follicularDays : 0) - fertileDays;

    final double menstrualSweep = (periodDays / totalDays) * 2 * math.pi;
    double follicularSweep = ((follicularDays > 0 ? follicularDays : 0) / totalDays) * 2 * math.pi;
    final double fertileSweep = (fertileDays / totalDays) * 2 * math.pi;
    double lutealSweep = ((lutealDays > 0 ? lutealDays : 1) / totalDays) * 2 * math.pi;

    double currentAngle = -math.pi / 2; // Start from top

    // Menstrual (chilero / red)
    paint.color = const Color(0xFFE8636C);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, menstrualSweep, false, paint);
    currentAngle += menstrualSweep;

    // Folicular (chiltoma / green)
    paint.color = const Color(0xFF97B580);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, follicularSweep, false, paint);
    currentAngle += follicularSweep;

    // Ovulatoria (melon / orange)
    paint.color = const Color(0xFFD97A4A);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, fertileSweep, false, paint);
    currentAngle += fertileSweep;

    // Lútea (asuncion / blue)
    paint.color = const Color(0xFF8FAFC8);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, lutealSweep, false, paint);

    // ── Flecha indicadora de posición actual ──
    if (cycleInfo != null) {
      final int cycleDay = cycleInfo!.cycleDay;
      final double progress = cycleDay / totalDays;
      final double arrowAngle = -math.pi / 2 + (progress * 2 * math.pi);

      // Triángulo (flecha) apuntando hacia el centro
      final double arrowX = center.dx + radius * math.cos(arrowAngle);
      final double arrowY = center.dy + radius * math.sin(arrowAngle);

      // Outer circle (indicator dot)
      final indicatorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(arrowX, arrowY), 8, indicatorPaint);

      final dotPaint = Paint()
        ..color = phaseColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(arrowX, arrowY), 5.5, dotPaint);

      // Small border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(Offset(arrowX, arrowY), 8, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
