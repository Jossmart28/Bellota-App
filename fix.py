import re

with open('lib/screens/resumen_diario_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

replacement = '''class _CycleRingPainter extends CustomPainter {
  final CycleInfo? cycleInfo;
  
  _CycleRingPainter(this.cycleInfo);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final strokeWidth = 28.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (cycleInfo == null) {
      paint.color = const Color(0xFFEEEEEE);
      canvas.drawCircle(center, radius, paint);
      return;
    }

    double totalDays = (cycleInfo!.averageCycleLength ?? 28).toDouble();
    double periodDays = 5; 

    double menstrualSweep = (periodDays / totalDays) * 2 * 3.141592653589793;
    double follicularSweep = ((totalDays - periodDays - 14) / totalDays) * 2 * 3.141592653589793;
    if (follicularSweep < 0) follicularSweep = 0;
    double fertileSweep = (5 / totalDays) * 2 * 3.141592653589793;
    double lutealSweep = ((totalDays - periodDays - (totalDays - periodDays - 14) - 5) / totalDays) * 2 * 3.141592653589793;
    if (lutealSweep < 0) lutealSweep = 0.1;

    double currentAngle = -3.141592653589793 / 2;

    paint.color = const Color(0xFFFCE1E8);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, menstrualSweep, false, paint);
    currentAngle += menstrualSweep;

    paint.color = const Color(0xFFEAF5FA);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, follicularSweep, false, paint);
    currentAngle += follicularSweep;

    paint.color = const Color(0xFFF0E5F7);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, fertileSweep, false, paint);
    currentAngle += fertileSweep;

    paint.color = const Color(0xFFFCAF3B);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, lutealSweep, false, paint);

    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFEEEEEE);
    
    canvas.drawCircle(center, radius - 40, circlePaint);
    canvas.drawCircle(center, radius - 70, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}'''

new_content = re.sub(r'class _CycleRingPainter extends CustomPainter \{.*?shouldRepaint.*?\}', replacement, content, flags=re.DOTALL)

with open('lib/screens/resumen_diario_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)
