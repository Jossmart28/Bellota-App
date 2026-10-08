import 'dart:math' as math;
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/core/services/cycle_service.dart';
import 'package:bellotadevelopment/core/services/clinical_analysis_service.dart';
import 'package:bellotadevelopment/core/services/phase_symptom_classifier.dart';
import 'package:bellotadevelopment/presentation/screens/health_log/symptom_log_screen.dart';
import 'package:bellotadevelopment/presentation/common/bellota_icon.dart';
import 'package:bellotadevelopment/presentation/screens/health_log/analisis_screen.dart';

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

class _ResumenDiarioScreenState extends State<ResumenDiarioScreen>
    with TickerProviderStateMixin {
  int _selectedOffset = 0;
  bool _isLoading = false;

  // Cache: offset → predictions
  final Map<int, List<SymptomPrediction>> _predictions = {};
  final Map<int, int> _phases = {};

  // ── Animation controllers ──
  late AnimationController _ringAnimCtrl;
  late AnimationController _handAnimCtrl; // for clock-hand smooth movement
  late Animation<double> _ringAnim;
  late Animation<double> _handAnim;
  late AnimationController _contentFadeCtrl;
  late Animation<double> _contentFade;

  double _handAngle = -math.pi / 2; // current clock-hand angle
  double _targetHandAngle = -math.pi / 2;

  @override
  void initState() {
    super.initState();
    _phases[0] = widget.currentPhaseIndex;
    // Seed offset-0 with the classic predicted symptoms (already loaded by dashboard)
    _predictions[0] = widget.predictedSymptoms
        .map((k) => SymptomPrediction(
              symptomKey: k,
              score: 7.0,
              confidence: 'medium',
              reason: _phaseNameStr(widget.currentPhaseIndex),
            ))
        .toList();

    // Ring draw-in
    _ringAnimCtrl = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _ringAnim = CurvedAnimation(parent: _ringAnimCtrl, curve: Curves.easeOutCubic);

    // Clock hand rotation
    _handAnimCtrl = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    // Content fade
    _contentFadeCtrl = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _contentFade = CurvedAnimation(parent: _contentFadeCtrl, curve: Curves.easeOut);

    // Set initial hand position from current cycle day
    _handAngle = _computeAngle(_selectedCycleDay, _effectiveCycleLength);
    _targetHandAngle = _handAngle;

    _handAnim = Tween<double>(begin: _handAngle, end: _handAngle).animate(
      CurvedAnimation(parent: _handAnimCtrl, curve: Curves.easeInOutCubic),
    );

    _ringAnimCtrl.forward();
    _contentFadeCtrl.forward();
  }

  @override
  void dispose() {
    _ringAnimCtrl.dispose();
    _handAnimCtrl.dispose();
    _contentFadeCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────

  int get _effectiveCycleLength {
    final l = widget.cycleInfo?.averageCycleLength?.round() ?? widget.cycleDuration;
    return l < 15 ? widget.cycleDuration : l;
  }

  int get _selectedCycleDay {
    if (widget.lastPeriodStart == null) return widget.cycleInfo?.cycleDay ?? 1;
    final len = _effectiveCycleLength;
    final targetDate = DateTime.now().add(Duration(days: _selectedOffset));
    final d = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final start = DateTime(widget.lastPeriodStart!.year, widget.lastPeriodStart!.month, widget.lastPeriodStart!.day);
    final diffDays = d.difference(start).inDays;
    int cycleDay;
    if (diffDays >= 0) {
      cycleDay = (diffDays % len) + 1;
    } else {
      cycleDay = len - ((-diffDays) % len) + 1;
      if (cycleDay > len) cycleDay = 1;
    }
    return cycleDay;
  }

  int get _ovulationDay {
    final len = _effectiveCycleLength;
    int o = len - 14;
    if (o <= widget.periodDuration + 1) o = widget.periodDuration + 2;
    if (o > len - 2) o = len - 2;
    return o;
  }

  /// Angle on the ring clock: day 1 = top (-π/2), clockwise.
  double _computeAngle(int cycleDay, int totalDays) {
    final progress = (cycleDay - 1) / totalDays;
    return -math.pi / 2 + (progress * 2 * math.pi);
  }

  String _phaseNameStr(int phaseIdx) {
    const map = {0: 'ovulatory', 1: 'luteal', 2: 'follicular', 3: 'menstrual'};
    return map[phaseIdx] ?? 'ovulatory';
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

  String _catImageForPhaseIdx(int phaseIdx) {
    switch (phaseIdx) {
      case 0: return 'assets/images/bella_ovulatoria.png';
      case 1: return 'assets/images/bella_lutea.png';
      case 2: return 'assets/images/bella_folicular.png';
      case 3: return 'assets/images/bella_menstrual.png';
      default: return 'assets/images/bella_menstrual.png';
    }
  }

  String _shortDayName(int weekday) => ['lun','mar','mié','jue','vie','sáb','dom'][weekday - 1];
  String _shortMonthName(int month) => ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'][month - 1];

  // ─────────────────────────────────────────────────────────────
  //  FETCH PREDICTIONS (+ animate hand)
  // ─────────────────────────────────────────────────────────────

  Future<void> _selectOffset(int offset) async {
    if (offset == _selectedOffset) return;

    // 1. Compute new cycle day and hand angle before state update
    final newCycleDay = _computeCycleDayForOffset(offset);
    final newAngle = _computeAngle(newCycleDay, _effectiveCycleLength);

    // 2. Determine phase for the new date
    int newPhaseIdx = _phases[offset] ?? widget.currentPhaseIndex;
    if (!_phases.containsKey(offset) && widget.lastPeriodStart != null) {
      final targetDate = DateTime.now().add(Duration(days: offset));
      final phase = CycleService.instance.getPhaseForDate(
        date: targetDate,
        lastPeriodStart: widget.lastPeriodStart!,
        effectiveCycleDuration: _effectiveCycleLength,
        periodDuration: widget.periodDuration,
      );
      newPhaseIdx = _phaseIndexFromEnum(phase);
    }

    // 3. Animate the clock hand
    _animateHand(newAngle);

    // 4. Fade out content, switch offset, fetch, fade back in
    await _contentFadeCtrl.reverse();
    setState(() {
      _selectedOffset = offset;
      if (!_phases.containsKey(offset)) _phases[offset] = newPhaseIdx;
    });
    _ringAnimCtrl.reset();
    _ringAnimCtrl.forward();
    _contentFadeCtrl.forward();

    // 5. Fetch enriched predictions if not cached
    if (!_predictions.containsKey(offset)) {
      _fetchPredictionsForOffset(offset, newPhaseIdx, newCycleDay);
    }
  }

  void _animateHand(double targetAngle) {
    final currentAngle = _handAnim.value;
    // Handle wrap-around: always rotate forward (clockwise)
    double delta = targetAngle - currentAngle;
    if (delta < -math.pi) delta += 2 * math.pi;
    final correctedTarget = currentAngle + delta;

    _handAnim = Tween<double>(begin: currentAngle, end: correctedTarget).animate(
      CurvedAnimation(parent: _handAnimCtrl, curve: Curves.easeInOutCubic),
    );
    _handAnimCtrl
      ..reset()
      ..forward();
  }

  Future<void> _fetchPredictionsForOffset(int offset, int phaseIdx, int cycleDay) async {
    if (widget.userId == null) return;
    setState(() => _isLoading = true);

    try {
      final phaseNameStr = _phaseNameStr(phaseIdx);

      // Get historical scores from the existing service first
      final historical = await ClinicalAnalysisService.instance.predictSymptoms(
        widget.userId!, phaseNameStr, limit: 10,
      );

      // Convert list to score map (rank-based)
      final Map<String, double> historicalMap = {};
      for (int i = 0; i < historical.length; i++) {
        historicalMap[historical[i]] = 10.0 - i;
      }

      // Blend with clinical prior via PhaseSymptomClassifier
      final enriched = await PhaseSymptomClassifier.instance.getPredictions(
        userId: widget.userId!,
        phaseName: phaseNameStr,
        cycleDay: cycleDay,
        cycleDuration: _effectiveCycleLength,
        periodDuration: widget.periodDuration,
        historicalScores: historicalMap,
        limit: 5,
      );

      if (mounted) {
        setState(() {
          _predictions[offset] = enriched;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _computeCycleDayForOffset(int offset) {
    if (widget.lastPeriodStart == null) return widget.cycleInfo?.cycleDay ?? 1;
    final len = _effectiveCycleLength;
    final targetDate = DateTime.now().add(Duration(days: offset));
    final d = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final start = DateTime(widget.lastPeriodStart!.year, widget.lastPeriodStart!.month, widget.lastPeriodStart!.day);
    final diffDays = d.difference(start).inDays;
    int cycleDay;
    if (diffDays >= 0) {
      cycleDay = (diffDays % len) + 1;
    } else {
      cycleDay = len - ((-diffDays) % len) + 1;
      if (cycleDay > len) cycleDay = 1;
    }
    return cycleDay;
  }

  int _phaseIndexFromEnum(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.ovulatory: return 0;
      case CyclePhase.luteal: return 1;
      case CyclePhase.follicular: return 2;
      case CyclePhase.menstrual: return 3;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final colors = Theme.of(context).extension<BellotaColors>() ?? BellotaColors.light;
        final daysUntil = widget.nextPeriodDate.difference(DateTime.now()).inDays;
        final currentDay = _selectedCycleDay;
        final phaseIdx = _phases[_selectedOffset] ?? widget.currentPhaseIndex;

        return Scaffold(
          backgroundColor: colors.basilica,
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildTopHeader(context, colors),
                Container(
                  transform: Matrix4.translationValues(0.0, -32.0, 0.0),
                  decoration: BoxDecoration(
                    color: colors.basilica,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 40),
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          daysUntil <= 0 ? 'Tu período puede iniciar hoy' : 'Tu próximo período inicia en $daysUntil días',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.textoDark, fontFamily: 'Outfit', height: 1.1),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Día $currentDay de tu ciclo · ${_phaseName(context)}',
                          style: TextStyle(fontSize: 15, color: colors.textoMedio, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        _buildCycleClockCard(context, colors, currentDay, phaseIdx),
                        const SizedBox(height: 24),
                        _buildPredictionCard(context, colors),
                        const SizedBox(height: 24),
                        if (widget.activeAlerts != null && widget.activeAlerts!.isNotEmpty)
                          _buildAlertsCard(context, colors),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildTopHeader(BuildContext context, BellotaColors colors) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFBC4B4D), Color(0xFFC85556)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 48),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10, top: -20,
            child: Opacity(
              opacity: 0.18,
              child: Image.asset('assets/images/bellota_outline.png', width: 180, height: 180),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Resumen Diario', style: TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildDateSelector(context, colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, BellotaColors colors) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 14,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedOffset;
          final date = DateTime.now().add(Duration(days: index));
          final dayName = index == 0 ? 'Hoy' : _shortDayName(date.weekday);
          final dateStr = '${date.day} ${_shortMonthName(date.month)}';

          return GestureDetector(
            onTap: () => _selectOffset(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: isSelected ? 70 : 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSelected ? 17 : 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontFamily: 'Outfit',
                    ),
                    child: Text(dayName),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: isSelected
                        ? Container(
                            key: ValueKey('pill_$index'),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))]),
                            child: Text(dateStr, style: const TextStyle(color: Color(0xFFC74C4D), fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        : Text(
                            key: ValueKey('date_$index'),
                            dateStr,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w400),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  CYCLE CLOCK CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildCycleClockCard(BuildContext context, BellotaColors colors, int currentDay, int phaseIdx) {
    final len = _effectiveCycleLength;
    final oDay = _ovulationDay;
    int follicularDays = oDay - 2 - widget.periodDuration;
    if (follicularDays < 0) follicularDays = 0;
    int lutealDays = len - (oDay + 1);
    if (lutealDays < 0) lutealDays = 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.melon.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: colors.chilero.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ── Clock Ring ──
          SizedBox(
            width: 240, height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dotted ring (draw-in animation)
                AnimatedBuilder(
                  animation: _ringAnim,
                  builder: (_, __) => CustomPaint(
                    size: const Size(220, 220),
                    painter: _ClockRingPainter(
                      currentDay: currentDay,
                      totalDays: len,
                      periodDuration: widget.periodDuration,
                      ovulationDay: oDay,
                      colors: colors,
                      progress: _ringAnim.value,
                    ),
                  ),
                ),

                // Inner circle with cat + text
                AnimatedBuilder(
                  animation: _ringAnim,
                  builder: (_, __) {
                    final scale = Curves.easeOutBack.transform(_ringAnim.value).clamp(0.0, 1.1);
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 155, height: 155,
                        decoration: BoxDecoration(color: colors.chilero.withOpacity(0.12), shape: BoxShape.circle),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  transitionBuilder: (child, anim) => FadeTransition(
                                    opacity: anim,
                                    child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)), child: child),
                                  ),
                                  child: Image.asset(_catImageForPhaseIdx(phaseIdx), key: ValueKey(phaseIdx), fit: BoxFit.contain),
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
                                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                                  child: child,
                                ),
                              ),
                              child: Column(
                                key: ValueKey(currentDay),
                                children: [
                                  Text('Día $currentDay', style: TextStyle(color: colors.chilero, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Outfit', height: 1.0)),
                                  Text(_phaseName(context), style: TextStyle(color: colors.chilero.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600, height: 1.5)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // ── CLOCK HAND (animated) ──
                AnimatedBuilder(
                  animation: _handAnimCtrl.status == AnimationStatus.dismissed ? AlwaysStoppedAnimation(_computeAngle(currentDay, len)) : _handAnim,
                  builder: (_, __) {
                    final angle = _handAnimCtrl.status == AnimationStatus.dismissed
                        ? _computeAngle(currentDay, len)
                        : _handAnim.value;
                    const r = 107.0;
                    const cx = 120.0;
                    const cy = 120.0;
                    final dx = cx + r * math.cos(angle);
                    final dy = cy + r * math.sin(angle);

                    return Positioned(
                      left: dx - 14,
                      top: dy - 14,
                      child: AnimatedOpacity(
                        opacity: _ringAnim.value,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: colors.chilero,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [BoxShadow(color: colors.chilero.withOpacity(0.45), blurRadius: 10, spreadRadius: 1)],
                          ),
                          child: Center(
                            child: Text(
                              '$currentDay',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Legend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildLegendDot(colors.chilero, 'Menstrual · ${widget.periodDuration}d', isSelected: true, colors: colors),
            const SizedBox(width: 16),
            _buildLegendDot(colors.chiltoma, 'Folicular · ${follicularDays}d', colors: colors),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildLegendDot(colors.melon, 'Ovulatoria · 3d', colors: colors),
            const SizedBox(width: 16),
            _buildLegendDot(colors.asuncion, 'Lútea · ${lutealDays}d', colors: colors),
          ]),

          const SizedBox(height: 24),

          CustomPaint(size: const Size(double.infinity, 1), painter: _DashedLinePainter(color: colors.melon.withOpacity(0.4))),

          const SizedBox(height: 24),

          // Symptoms registered row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Síntomas registrados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Outfit', color: colors.textoDark)),
                  const SizedBox(height: 6),
                  Text(
                    widget.todaySymptoms.isEmpty ? 'Día tranquilo: aún no registras síntomas hoy.' : '${widget.todaySymptoms.length} síntomas registrados hoy.',
                    style: TextStyle(fontSize: 13, color: colors.textoMedio, height: 1.3),
                  ),
                ],
              )),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SymptomLogScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: colors.chilero, borderRadius: BorderRadius.circular(20)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Registrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text, {bool isSelected = false, required BellotaColors colors}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: isSelected ? BoxDecoration(border: Border.all(color: color, width: 1.2), borderRadius: BorderRadius.circular(20), color: color.withOpacity(0.08)) : null,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: isSelected ? color : colors.textoMedio, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  PREDICTION CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildPredictionCard(BuildContext context, BellotaColors colors) {
    final preds = _predictions[_selectedOffset];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Predicción de síntomas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Outfit', color: colors.textoDark)),
        const SizedBox(height: 8),
        Text(
          'Esto es lo típico de la fase ${_phaseName(context).toLowerCase()}. Se irá ajustando a ti cuando registres tus síntomas.',
          style: TextStyle(fontSize: 14, color: colors.textoMedio, height: 1.4),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim,
            child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)), child: child)),
          child: Container(
            key: ValueKey(_selectedOffset),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colors.melon.withOpacity(0.3), width: 1),
              boxShadow: [BoxShadow(color: colors.chilero.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: _isLoading
                ? const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : preds == null || preds.isEmpty
                    ? Padding(padding: const EdgeInsets.all(30), child: Center(child: Text('Sin predicciones disponibles.', style: TextStyle(color: colors.textoMedio))))
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        itemCount: preds.length,
                        separatorBuilder: (_, __) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: CustomPaint(size: const Size(double.infinity, 1), painter: _DashedLinePainter(color: colors.melon.withOpacity(0.4))),
                        ),
                        itemBuilder: (context, index) => _buildPredictionRow(preds[index], colors),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionRow(SymptomPrediction pred, BellotaColors colors) {
    final sympName = AppTranslations.get('registration_form', pred.symptomKey, languageNotifier.currentLang, context: context);
    final confidenceText = pred.confidence == 'high' ? 'Muy probable' : pred.confidence == 'medium' ? 'Probable' : 'Posible';
    final confidenceColor = pred.confidence == 'high' ? colors.chilero : pred.confidence == 'medium' ? colors.melon : colors.textoMedio;
    final acorns = pred.confidence == 'high' ? 4 : pred.confidence == 'medium' ? 3 : 2;

    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sympName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Outfit', color: colors.textoDark)),
            const SizedBox(height: 4),
            Text(confidenceText, style: TextStyle(color: confidenceColor, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        )),
        Row(children: List.generate(4, (i) => Padding(
          padding: const EdgeInsets.only(left: 4),
          child: BellotaIcon(color: i < acorns ? colors.chilero : colors.textoMedio.withOpacity(0.2), size: 16),
        ))),
      ],
    );
  }

  Widget _buildAlertsCard(BuildContext context, BellotaColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertas de salud', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Outfit', color: colors.textoDark)),
        const SizedBox(height: 8),
        Text('Basado en tus registros recientes.', style: TextStyle(fontSize: 14, color: colors.textoMedio, height: 1.4)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colors.melon.withOpacity(0.3), width: 1),
            boxShadow: [BoxShadow(color: colors.chilero.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: widget.activeAlerts!.length,
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CustomPaint(size: const Size(double.infinity, 1), painter: _DashedLinePainter(color: colors.melon.withOpacity(0.4))),
            ),
            itemBuilder: (context, index) {
              final alert = widget.activeAlerts![index];
              final isHigh = alert.severity == 'high';
              final color = isHigh ? colors.chilero : colors.melon;
              final icon = isHigh ? Icons.warning_rounded : Icons.info_outline_rounded;
              
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isHigh ? 'Atención médica sugerida' : 'Observación', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Outfit', color: color)),
                        const SizedBox(height: 4),
                        Text(
                          'Síntomas detectados: ${alert.triggerSymptoms.join(', ')}',
                          style: TextStyle(color: colors.textoMedio, fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}


  // ─────────────────────────────────────────────────────────────
  //  ALERTS CARD

// ─────────────────────────────────────────────────────────────
//  PAINTERS
// ─────────────────────────────────────────────────────────────

/// Clock-ring: paints colored dots around a circle.
/// Day 1 is always at the top (-π/2). Dots are drawn clockwise.
/// The current day's dot is handled by the overlay clock hand widget.
class _ClockRingPainter extends CustomPainter {
  final int currentDay;
  final int totalDays;
  final int periodDuration;
  final int ovulationDay;
  final BellotaColors colors;
  final double progress; // 0.0→1.0 draw-in animation

  const _ClockRingPainter({
    required this.currentDay,
    required this.totalDays,
    required this.periodDuration,
    required this.ovulationDay,
    required this.colors,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const startAngle = -math.pi / 2; // Day 1 at top
    final anglePerDay = (2 * math.pi) / totalDays;

    final dotsToShow = (totalDays * progress).round();

    for (int i = 0; i < dotsToShow; i++) {
      final day = i + 1;

      Color dotColor;
      if (day >= 1 && day <= periodDuration) {
        dotColor = colors.chilero;
      } else if (day >= ovulationDay - 1 && day <= ovulationDay + 1) {
        dotColor = colors.melon;
      } else if (day > periodDuration && day < ovulationDay - 1) {
        dotColor = colors.chiltoma;
      } else {
        dotColor = colors.asuncion;
      }

      // Current day handled by the overlay indicator — draw smaller ghost dot
      final isCurrentDay = day == currentDay;
      final dotRadius = isCurrentDay ? 3.0 : 4.5;
      final opacity = isCurrentDay ? 0.25 : (0.6 * progress);

      final angle = startAngle + (i * anglePerDay);
      final dx = center.dx + radius * math.cos(angle);
      final dy = center.dy + radius * math.sin(angle);

      canvas.drawCircle(
        Offset(dx, dy),
        dotRadius,
        Paint()..color = dotColor.withOpacity(opacity)..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClockRingPainter old) =>
      old.currentDay != currentDay || old.progress != progress || old.totalDays != totalDays;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}