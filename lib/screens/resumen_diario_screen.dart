import 'dart:math' as math;

import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/services/cycle_service.dart';
import '../theme/bellota_colors.dart';

class ResumenDiarioScreen extends StatelessWidget {
  final DateTime nextPeriodDate;
  final List<String> predictedSymptoms;
  final List<String> todaySymptoms;
  final String? todayMood;
  final List<String> medicalConditions;
  final CycleInfo? cycleInfo;
  final int currentPhaseIndex;

  const ResumenDiarioScreen({
    super.key,
    required this.nextPeriodDate,
    required this.predictedSymptoms,
    required this.todaySymptoms,
    required this.medicalConditions,
    required this.currentPhaseIndex,
    this.todayMood,
    this.cycleInfo,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final daysUntil = nextPeriodDate.difference(DateTime.now()).inDays;
        
        final List<String> monthNames = [
          'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
          'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // 1. Fondo Degradado (Rosa / Chilero)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 280,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFF5E8A), // Rosa intenso
                        Color(0xFFFF99B6), // Rosa suave
                        Colors.white,
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. Contenido principal
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top Bar
                    _buildTopBar(context),
                    
                    // Selector de fechas simulado
                    _buildDateSelector(),
                    
                    const SizedBox(height: 16),

                    // Tarjeta blanca redondeada que cubre el resto
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título principal
                              Text(
                                daysUntil <= 0 
                                    ? "Tu período puede iniciar hoy" 
                                    : "Tu período inicia en $daysUntil días",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF333333),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Basado en la fecha prevista de tu período (${nextPeriodDate.day} ${monthNames[nextPeriodDate.month - 1]})",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF757575),
                                  height: 1.4,
                                ),
                              ),
                              
                              const SizedBox(height: 48),
                              
                              // Gráfico circular (Simulado Visualmente)
                              Center(
                                child: SizedBox(
                                  width: 260,
                                  height: 260,
                                  child: CustomPaint(
                                    painter: _CycleRingPainter(),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 48),

                              // Predicción de síntomas
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F7F9), // Gris muy claro
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF5E8A),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Predicción de síntomas",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF222222),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Según tus registros pasados, podrías experimentar los siguientes síntomas en esta fase de tu ciclo.",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: const Color(0xFF666666),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    if (predictedSymptoms.isEmpty)
                                      Text(
                                        "No hay predicciones disponibles aún.",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: const Color(0xFF999999),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    else
                                      ...predictedSymptoms.map((s) => _buildSymptomItem(s)),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              "Resumen diario",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48), // Espaciador para centrar
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _dateItem("jue", "17 sept", false),
          _dateItem("Hoy", "18 sept", true),
          _dateItem("sáb", "19 sept", false),
        ],
      ),
    );
  }

  Widget _dateItem(String day, String date, bool isToday) {
    return Column(
      children: [
        Text(
          day,
          style: GoogleFonts.poppins(
            fontSize: isToday ? 18 : 14,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            color: Colors.white.withValues(alpha: isToday ? 1.0 : 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isToday ? 12 : 0, vertical: isToday ? 4 : 0),
          decoration: isToday ? BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ) : null,
          child: Text(
            date,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w500 : FontWeight.w400,
              color: Colors.white.withValues(alpha: isToday ? 1.0 : 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomItem(String symptomKey) {
    // Translate the symptom
    String translated = symptomKey;
    final lang = languageNotifier.currentLang;
    for (final cat in ['registration_form', 'symptoms_and_actions', 'symptoms']) {
      final val = AppTranslations.get(cat, symptomKey, lang);
      if (val != symptomKey) {
        translated = val;
        break;
      }
    }
    translated = translated.replaceAll('_', ' ');
    
    // Capitalize
    if (translated.isNotEmpty) {
      translated = translated[0].toUpperCase() + translated.substring(1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Avatar simulado del síntoma
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBF1), // Fondo rosita
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.face_retouching_natural_rounded, // Icono genérico
                color: const Color(0xFFFF5E8A),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              translated,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Custom Painter para el gráfico circular del ciclo
// ────────────────────────────────────────────────────────────────
class _CycleRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final strokeWidth = 28.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 1. Fase menstrual (Rosa) - Arriba a la derecha
    paint.color = const Color(0xFFFCE1E8); // Rosa pálido
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,        // Inicio: -90 grados (arriba)
      math.pi / 2.5,       // Sweep
      false,
      paint,
    );

    // 2. Fase folicular (Celeste) - Derecha abajo
    paint.color = const Color(0xFFEAF5FA); // Celeste pálido
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + (math.pi / 2.2),
      math.pi / 2,
      false,
      paint,
    );

    // 3. Ventana fértil / Ovulación (Morado claro) - Abajo izquierda
    paint.color = const Color(0xFFF0E5F7); // Morado pálido
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi / 1.5,
      math.pi / 3.5,
      false,
      paint,
    );

    // 4. Fase lútea (Naranja) - Izquierda a arriba
    paint.color = const Color(0xFFFCAF3B); // Naranja vibrante
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi / 1.6,
      false,
      paint,
    );

    // --- Decoraciones interiores ---
    
    // Círculos concéntricos punteados/suaves (simulados con líneas finas)
    final circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFEEEEEE);
    
    canvas.drawCircle(center, radius - 40, circlePaint);
    canvas.drawCircle(center, radius - 60, circlePaint);
    
    // Anillo central (naranja)
    final centerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = const Color(0xFFFCAF3B);
    canvas.drawCircle(center, 8, centerRingPaint);

    // Textos de las fases (simulados dibujando en el canvas con rotación)
    _drawRotatedText(canvas, center, "Período", radius + 25, -math.pi / 3.5, const Color(0xFFBDBDBD));
    _drawRotatedText(canvas, center, "Fase folicular", radius + 25, math.pi / 4, const Color(0xFFBDBDBD));
    _drawRotatedText(canvas, center, "Día de ovulación", radius + 25, math.pi / 1.25, const Color(0xFFBDBDBD));
    _drawRotatedText(canvas, center, "Fase lútea", radius + 25, -math.pi + 0.5, const Color(0xFFFCAF3B));
  }

  void _drawRotatedText(Canvas canvas, Offset center, String text, double radius, double angle, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    canvas.save();
    // Movemos al centro
    canvas.translate(center.dx, center.dy);
    // Rotamos
    canvas.rotate(angle);
    // Movemos hacia afuera
    canvas.translate(radius, 0);
    // Rotamos el texto para que sea legible según su posición
    if (angle > math.pi / 2 || angle < -math.pi / 2) {
      canvas.rotate(math.pi); // Dar la vuelta si está del lado izquierdo
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    } else {
      canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    }
    
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
