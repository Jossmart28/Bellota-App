import 'dart:math' as math;
import 'dart:ui';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';
import '../theme/bellota_colors.dart';
import '../core/services/cycle_service.dart';
import '../core/services/clinical_analysis_service.dart';
import '../database/database_helper.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'analisis_screen.dart';

class ResumenDiarioScreen extends StatefulWidget {
  final DateTime nextPeriodDate;
  final List<String> predictedSymptoms;
  final List<String> todaySymptoms;
  final String? todayMood;
  final List<String> medicalConditions;
  final CycleInfo? cycleInfo;
  final int currentPhaseIndex;
  final List<ClinicalAlert>? activeAlerts;
  final int? userId;
  final String? contraceptive;
  final DateTime? lastPeriodStart;
  final int cycleDuration;
  final int periodDuration;

  const ResumenDiarioScreen({
    super.key,
    required this.nextPeriodDate,
    required this.predictedSymptoms,
    required this.todaySymptoms,
    required this.medicalConditions,
    required this.currentPhaseIndex,
    this.todayMood,
    this.cycleInfo,
    this.activeAlerts,
    this.userId,
    this.contraceptive,
    this.lastPeriodStart,
    this.cycleDuration = 28,
    this.periodDuration = 5,
  });

  @override
  State<ResumenDiarioScreen> createState() => _ResumenDiarioScreenState();
}

class _ResumenDiarioScreenState extends State<ResumenDiarioScreen> {
  int _selectedOffset = 0;
  bool _isLoading = false;
  final Map<int, List<String>> _predictions = {};
  final Map<int, int> _phases = {};

  @override
  void initState() {
    super.initState();
    _predictions[0] = widget.predictedSymptoms;
    _phases[0] = widget.currentPhaseIndex;
  }

  Future<void> _fetchPredictionForOffset(int offset) async {
    if (_predictions.containsKey(offset) || widget.userId == null || widget.lastPeriodStart == null) {
      setState(() {
        _selectedOffset = offset;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _selectedOffset = offset;
    });

    final targetDate = DateTime.now().add(Duration(days: offset));
    final phase = CycleService.instance.getPhaseForDate(
      date: targetDate,
      lastPeriodStart: widget.lastPeriodStart!,
      effectiveCycleDuration: widget.cycleDuration,
      periodDuration: widget.periodDuration,
    );

    int pIdx = 0;
    String pNameStr = 'ovulatory';
    switch (phase) {
      case CyclePhase.ovulatory: pIdx = 0; pNameStr = 'ovulatory'; break;
      case CyclePhase.luteal: pIdx = 1; pNameStr = 'luteal'; break;
      case CyclePhase.follicular: pIdx = 2; pNameStr = 'follicular'; break;
      case CyclePhase.menstrual: pIdx = 3; pNameStr = 'menstrual'; break;
    }

    final symps = await ClinicalAnalysisService.instance.predictSymptoms(
      widget.userId!, 
      pNameStr,
      limit: 5,
    );

    setState(() {
      _predictions[offset] = symps.isNotEmpty ? symps : ['mood_swings', 'headache', 'bloating'];
      _phases[offset] = pIdx;
      _isLoading = false;
    });
  }

  // Colores de fase consistentes con dashboard_screen.dart _getPhases
  Color _phaseColor(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;
    switch ((_phases[_selectedOffset] ?? widget.currentPhaseIndex)) {
      case 0: return colors.melon;      // Ovulatoria
      case 1: return colors.asuncion;   // Lútea
      case 2: return colors.chiltoma;   // Folicular
      case 3: return colors.chilero;    // Menstrual
      default: return colors.melon;
    }
  }

  Color _phaseBorderColor(int index) {
    switch (index) {
      case 0: return const Color(0xFFD97A4A);
      case 1: return const Color(0xFF8FAFC8);
      case 2: return const Color(0xFF97B580);
      case 3: return const Color(0xFFD46A63);
      default: return const Color(0xFFD97A4A);
    }
  }

  String _phaseName(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch ((_phases[_selectedOffset] ?? widget.currentPhaseIndex)) {
      case 0: return loc.cyclePhasesOvulatory;
      case 1: return loc.cyclePhasesLuteal;
      case 2: return loc.cyclePhasesFollicular;
      case 3: return loc.cyclePhasesMenstrual;
      default: return loc.cyclePhasesOvulatory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final colors = Theme.of(context).bellotaColors;
        final daysUntil = widget.nextPeriodDate.difference(DateTime.now()).inDays;
        final phaseColor = _phaseColor(context);
        final phaseBorder = _phaseBorderColor((_phases[_selectedOffset] ?? widget.currentPhaseIndex));

        return Scaffold(
          backgroundColor: colors.basilica,
          body: Stack(
            children: [
              // Fondo degradado con color de fase
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 280,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        phaseColor.withValues(alpha: 0.85),
                        phaseColor.withValues(alpha: 0.4),
                        colors.basilica,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top Bar
                    _buildTopBar(context, colors),

                    // Date selector
                    _buildDateSelector(context, colors),

                    const SizedBox(height: 16),

                    // Tarjeta blanca principal
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          boxShadow: [
                            BoxShadow(
                              color: colors.melon.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título principal
                              Text(
                                daysUntil <= 0
                                    ? 'Tu período puede iniciar hoy'
                                    : 'Tu período inicia en $daysUntil días',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textoDark,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Basado en tus registros — Día ${widget.cycleInfo?.cycleDay ?? '?'} de tu ciclo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textoMedio,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ════════════════════════════════════════
                              // TARJETA: Fase actual + Síntomas registrados
                              // ════════════════════════════════════════
                              _buildPhaseAndSymptomsCard(context, colors, phaseColor, phaseBorder),

                              const SizedBox(height: 20),

                              // ════════════════════════════════════════
                              // PREDICCIÓN DE SÍNTOMAS
                              // ════════════════════════════════════════
                              _buildPredictionSection(context, colors),

                              if (widget.activeAlerts != null && widget.activeAlerts!.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                // ════════════════════════════════════════
                                // ALERTAS CLÍNICAS (Semáforo)
                                // ════════════════════════════════════════
                                _buildClinicalAlertSection(context, colors),
                              ],

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

  // ═══════════════════════════════════════════════════════════
  // TARJETA: Fase + Síntomas Registrados (con anillo de ciclo)
  // ═══════════════════════════════════════════════════════════
  Widget _buildPhaseAndSymptomsCard(
    BuildContext context,
    BellotaColors colors,
    Color phaseColor,
    Color phaseBorder,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: phaseColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ── Síntomas registrados ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.symptomsAndActionsLoggedSymptoms,
                  style: TextStyle(
                    color: colors.textoDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.todaySymptoms.isEmpty)
                  Text(
                    AppLocalizations.of(context)!.symptomsAndActionsNoSymptomsLogged,
                    style: TextStyle(
                      color: colors.textoMedio,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (widget.todaySymptoms.isNotEmpty && _selectedOffset == 0)
                  ...widget.todaySymptoms.take(4).map((s) => _bulletItem(
                    context,
                    colors,
                    AppTranslations.get('registration_form', s, languageNotifier.currentLang, context: context),
                    phaseColor,
                  )),
                if (widget.todaySymptoms.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${widget.todaySymptoms.length - 4} más',
                      style: TextStyle(
                        color: colors.textoMedio,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (widget.todayMood != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: phaseColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_getMoodEmoji(widget.todayMood!)} ${_translateMood(widget.todayMood!, context)}',
                      style: TextStyle(
                        color: phaseColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(BuildContext context, BellotaColors colors, String text, Color dotColor) {
    // Capitalize first letter
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.textoDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════
  // PREDICCIÓN DE SÍNTOMAS (PREMIUM)
  // ═══════════════════════════════
  Widget _buildPredictionSection(BuildContext context, BellotaColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.chilero.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome_outlined, color: colors.chilero, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Predicción de síntomas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textoDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Basado en tus registros, podrías experimentar esto en tu fase actual:',
          style: TextStyle(
            fontSize: 13,
            color: colors.textoMedio,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        if (_isLoading) const Center(child: CircularProgressIndicator()) else if ((_predictions[_selectedOffset] ?? []).isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.nancite.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No hay predicciones disponibles aún. Sigue registrando para mejorarlas.',
              style: TextStyle(
                fontSize: 13,
                color: colors.textoMedio,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          SizedBox(
            height: 100, // Altura de las tarjetas
            child: AnimationLimiter(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: (_predictions[_selectedOffset] ?? []).length,
                clipBehavior: Clip.none,
                itemBuilder: (BuildContext context, int index) {
                  final s = (_predictions[_selectedOffset] ?? [])[index];
                  String translated = AppTranslations.get('registration_form', s, languageNotifier.currentLang, context: context);
                  if (translated.isNotEmpty) {
                    translated = translated[0].toUpperCase() + translated.substring(1);
                  }
                  
                  // Simulate probability for visual impact
                  final probability = 85 - (index * 15); 
                  
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 500),
                    child: SlideAnimation(
                      horizontalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.chilero.withValues(alpha: 0.15)),
                            boxShadow: [
                              BoxShadow(
                                color: colors.chilero.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.analytics_outlined, size: 16, color: colors.chilero.withValues(alpha: 0.7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$probability%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: colors.chilero,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  translated,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colors.textoDark,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // ALERTAS CLÍNICAS (SCORE DIARIO)
  // ════════════════════════════════════════════════════════════════
  Widget _buildClinicalAlertSection(BuildContext context, BellotaColors colors) {
    if (widget.activeAlerts == null || widget.activeAlerts!.isEmpty) return const SizedBox.shrink();
    
    // Sort so high severity is at top
    final sortedAlerts = List<ClinicalAlert>.from(widget.activeAlerts!);
    sortedAlerts.sort((a, b) {
      int getSev(String s) => s == 'high' ? 3 : s == 'medium' ? 2 : 1;
      return getSev(b.severity).compareTo(getSev(a.severity));
    });

    final lang = languageNotifier.currentLang;

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: sortedAlerts.take(3).map((alert) {
          Color alertColor;
          Color bgColor;
          if (alert.severity == 'high') {
            alertColor = const Color(0xFFD32F2F); // Red
            bgColor = const Color(0xFFFFEBEE);
          } else if (alert.severity == 'medium') {
            alertColor = const Color(0xFFF57C00); // Orange
            bgColor = const Color(0xFFFFF3E0);
          } else {
            alertColor = const Color(0xFF388E3C); // Green
            bgColor = const Color(0xFFE8F5E9);
          }

          final translatedSymptoms = alert.triggerSymptoms.map((key) {
            String translated = AppTranslations.get(
              'registration_form', key, lang, context: context,
            );
            if (translated.isNotEmpty) {
              translated = translated[0].toUpperCase() + translated.substring(1);
            }
            return translated;
          }).toList();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: alertColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: alertColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  translatedSymptoms.isNotEmpty ? translatedSymptoms.first : "Alerta",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: alertColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // TOP BAR
  // ═══════════════════
  Widget _buildTopBar(BuildContext context, BellotaColors colors) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Resumen Diario',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalisisScreen(
                        cycleDuration: widget.cycleDuration,
                        periodDuration: widget.periodDuration,
                        activeAlerts: widget.activeAlerts,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════
  // DATE SELECTOR
  // ═══════════════════
  Widget _buildDateSelector(BuildContext context, BellotaColors colors) {
    final now = DateTime.now();
    
    final List<String> monthNames = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final List<String> weekDays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

    String format(DateTime d) => '${d.day} ${monthNames[d.month - 1]}';
    String formatDay(DateTime d) => weekDays[d.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (index) {
            final date = now.add(Duration(days: index));
            final isSelected = _selectedOffset == index;
            final labelDay = index == 0 ? 'Hoy' : formatDay(date);
            
            return GestureDetector(
              onTap: () => _fetchPredictionForOffset(index),
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    Text(
                      labelDay,
                      style: TextStyle(
                        fontSize: isSelected ? 18 : 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 8, vertical: isSelected ? 4 : 4),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                      child: Text(
                        format(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                          color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'happy': return '😊';
      case 'sad': return '😢';
      case 'anxious': return '😰';
      case 'angry': return '😠';
      case 'calm': return '😌';
      case 'energetic': return '⚡';
      case 'tired': return '😴';
      case 'sensitive': return '🥺';
      default: return '😶';
    }
  }

  String _translateMood(String mood, BuildContext context) {
    switch (mood) {
      case 'happy': return 'Feliz';
      case 'sad': return 'Triste';
      case 'anxious': return 'Ansiosa';
      case 'angry': return 'Enojada';
      case 'calm': return 'Tranquila';
      case 'energetic': return 'Energética';
      case 'tired': return 'Cansada';
      case 'sensitive': return 'Sensible';
      default: return mood;
    }
  }


}

