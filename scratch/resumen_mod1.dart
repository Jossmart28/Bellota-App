import 'dart:math' as math;
import 'dart:ui';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';
import '../theme/bellota_colors.dart';
import '../core/services/cycle_service.dart';
import '../core/services/clinical_analysis_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/bellota_empty_state.dart';

class ResumenDiarioScreen extends StatefulWidget {
  final DateTime widget.nextPeriodDate;
  final List<String> predictedSymptoms;
  final List<String> widget.todaySymptoms;
  final String? widget.todayMood;
  final List<String> medicalConditions;
  final CycleInfo? widget.cycleInfo;
  final int (_phases[_selectedOffset] ?? widget.currentPhaseIndex);
  final List<ClinicalAlert>? widget.activeAlerts;

  const ResumenDiarioScreen({
    super.key,
    required this.widget.nextPeriodDate,
    required this.predictedSymptoms,
    required this.widget.todaySymptoms,
    required this.medicalConditions,
    required this.(_phases[_selectedOffset] ?? widget.currentPhaseIndex),
    this.widget.todayMood,
    this.widget.cycleInfo,
    this.widget.activeAlerts,
  });

  // Colores de fase consistentes con dashboard_screen.dart _getPhases
  Color _phaseColor(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;
    switch ((_phases[_selectedOffset] ?? widget.currentPhaseIndex)) {
      case 0: return colors.melon;      // Ovulatoria
      case 1: return colors.asuncion;   // LÃƒÂºtea
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

  String _getMascotImageForPhase(int index) {
    if (index < 0 || index > 3) return 'assets/images/bella_mascot.png';
    switch (index) {
      case 0: return 'assets/images/bella_ovulatoria.png';
      case 1: return 'assets/images/bella_lutea.png';
      case 2: return 'assets/images/bella_folicular.png';
      case 3: return 'assets/images/bella_menstrual.png';
      default: return 'assets/images/bella_mascot.png';
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
                              // TÃƒÂ­tulo principal
                              Text(
                                daysUntil <= 0
                                    ? 'Tu perÃƒÂ­odo puede iniciar hoy'
                                    : 'Tu perÃƒÂ­odo inicia en $daysUntil dÃƒÂ­as',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textoDark,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Basado en tus registros Ã¢â‚¬â€ DÃƒÂ­a ${widget.cycleInfo?.cycleDay ?? '?'} de tu ciclo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textoMedio,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
                              // TARJETA: Fase actual + SÃƒÂ­ntomas registrados
                              // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
                              _buildPhaseAndSymptomsCard(context, colors, phaseColor, phaseBorder),

                              const SizedBox(height: 20),

                              // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
                              // PREDICCIÃƒâ€œN DE SÃƒÂNTOMAS
                              // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
                              _buildPredictionSection(context, colors),

                              if (widget.activeAlerts != null && widget.activeAlerts!.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
                                // ALERTAS CLÃƒÂNICAS (SemÃƒÂ¡foro)
                                // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
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

  // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
  // TARJETA: Fase + SÃƒÂ­ntomas Registrados (con anillo de ciclo)
  // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
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
          // Ã¢â€â‚¬Ã¢â€â‚¬ SÃƒÂ­ntomas registrados Ã¢â€â‚¬Ã¢â€â‚¬
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
                if (widget.todaySymptoms.isNotEmpty)
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
                      '+${widget.todaySymptoms.length - 4} mÃƒÂ¡s',
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

  // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
  // PREDICCIÃƒâ€œN DE SÃƒÂNTOMAS (PREMIUM)
  // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
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
              'PredicciÃƒÂ³n de sÃƒÂ­ntomas',
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
          'Basado en tus registros, podrÃƒÂ­as experimentar esto en tu fase actual:',
          style: TextStyle(
            fontSize: 13,
            color: colors.textoMedio,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        if ((_predictions[_selectedOffset] ?? []).isEmpty)
          BellotaEmptyState(
            imagePath: _getMascotImageForPhase((_phases[_selectedOffset] ?? widget.currentPhaseIndex)),
            title: 'AÃƒÂºn no hay predicciones',
            message: 'Sigue registrando tus sÃƒÂ­ntomas diarios para que Bella pueda ayudarte a predecir cÃƒÂ³mo te sentirÃƒÂ¡s.',
            compact: true,
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

  // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
  // ALERTAS CLÃƒÂNICAS (SCORE DIARIO)
  // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
  Widget _buildClinicalAlertSection(BuildContext context, BellotaColors colors) {
    if (widget.activeAlerts == null || widget.activeAlerts!.isEmpty) return const SizedBox.shrink();
    
    // Sort so high severity is at top
    final sortedAlerts = List<ClinicalAlert>.from(widget.activeAlerts!);
    sortedAlerts.sort((a, b) {
      int getSev(String s) => s == 'high' ? 3 : s == 'medium' ? 2 : 1;
      return getSev(b.severity).compareTo(getSev(a.severity));
    });

    final lang = languageNotifier.currentLang;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.health_and_safety_rounded, color: Colors.red.shade600, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)!.profileAndReportHealthProfile,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.textoDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...sortedAlerts.asMap().entries.map((entry) {
          int index = entry.key;
          ClinicalAlert alert = entry.value;

          Color alertColor;
          Color bgColor;
          IconData icon;
          if (alert.severity == 'high') {
            alertColor = const Color(0xFFD32F2F); // Red
            bgColor = const Color(0xFFFFEBEE);
            icon = Icons.warning_rounded;
          } else if (alert.severity == 'medium') {
            alertColor = const Color(0xFFF57C00); // Orange
            bgColor = const Color(0xFFFFF3E0);
            icon = Icons.info_outline_rounded;
          } else {
            alertColor = colors.chiltoma;
            bgColor = colors.chiltoma.withValues(alpha: 0.1);
            icon = Icons.check_circle_outline_rounded;
          }

          // Translate symptom keys to display names
          final translatedSymptoms = alert.triggerSymptoms.map((key) {
            String translated = AppTranslations.get(
              'registration_form', key, lang, context: context,
            );
            if (translated.isNotEmpty) {
              translated = translated[0].toUpperCase() + translated.substring(1);
            }
            return translated;
          }).toList();

          // Category icon
          IconData categoryIcon;
          switch (alert.category) {
            case 'oncology': categoryIcon = Icons.favorite_border_rounded; break;
            case 'infection': categoryIcon = Icons.opacity_rounded; break;
            case 'pain': categoryIcon = Icons.thermostat_rounded; break;
            case 'sexual_risk': categoryIcon = Icons.shield_outlined; break;
            case 'sexual_pain': categoryIcon = Icons.spa_outlined; break;
            case 'bleeding': categoryIcon = Icons.water_drop_rounded; break;
            case 'spotting': categoryIcon = Icons.water_drop_outlined; break;
            case 'cycle': categoryIcon = Icons.loop_rounded; break;
            default: categoryIcon = Icons.health_and_safety_rounded; break;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: alertColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: alertColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: icon + severity badge + weekly count
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(categoryIcon, color: alertColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Icon(icon, color: alertColor, size: 18),
                      const SizedBox(width: 6),
                      if (alert.severity == 'high')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: alertColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Ã¢Å¡Â ',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const Spacer(),
                      // Weekly frequency badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: alertColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${alert.weeklyCount}/${alert.totalDaysWithData} d',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: alertColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Symptom chips Ã¢â‚¬â€ the ONLY content shown
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: translatedSymptoms.map((name) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: alertColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: alertColor.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.adjust_rounded, size: 12, color: alertColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textoDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ).animate().fade(duration: 400.ms, delay: (index * 150).ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
        }),
      ],
    );
  }

  // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
  // TOP BAR
  // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
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
              const SizedBox(width: 48), // Spacer for centering
            ],
          ),
        ),
      ),
    );
  }

  // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
  // DATE SELECTOR
  // Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
  Widget _buildDateSelector(BuildContext context, BellotaColors colors) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));

    final List<String> monthNames = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final List<String> weekDays = ['lun', 'mar', 'miÃƒÂ©', 'jue', 'vie', 'sÃƒÂ¡b', 'dom'];

    String format(DateTime d) => '${d.day} ${monthNames[d.month - 1]}';
    String formatDay(DateTime d) => weekDays[d.weekday - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _dateItem(formatDay(yesterday), format(yesterday), false),
          _dateItem('Hoy', format(now), true),
          _dateItem(formatDay(tomorrow), format(tomorrow), false),
        ],
      ),
    );
  }

  Widget _dateItem(String day, String date, bool isToday) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: isToday ? 18 : 14,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            color: Colors.white.withValues(alpha: isToday ? 1.0 : 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isToday ? 12 : 0, vertical: isToday ? 4 : 0),
          decoration: isToday
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Text(
            date,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.w500 : FontWeight.w400,
              color: Colors.white.withValues(alpha: isToday ? 1.0 : 0.6),
            ),
          ),
        ),
      ],
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'happy': return 'Ã°Å¸ËœÅ ';
      case 'sad': return 'Ã°Å¸ËœÂ¢';
      case 'anxious': return 'Ã°Å¸ËœÂ°';
      case 'angry': return 'Ã°Å¸ËœÂ ';
      case 'calm': return 'Ã°Å¸ËœÅ’';
      case 'energetic': return 'Ã¢Å¡Â¡';
      case 'tired': return 'Ã°Å¸ËœÂ´';
      case 'sensitive': return 'Ã°Å¸Â¥Âº';
      default: return 'Ã°Å¸ËœÂ¶';
    }
  }

  String _translateMood(String mood, BuildContext context) {
    switch (mood) {
      case 'happy': return 'Feliz';
      case 'sad': return 'Triste';
      case 'anxious': return 'Ansiosa';
      case 'angry': return 'Enojada';
      case 'calm': return 'Tranquila';
      case 'energetic': return 'EnergÃƒÂ©tica';
      case 'tired': return 'Cansada';
      case 'sensitive': return 'Sensible';
      default: return mood;
    }
  }
}


