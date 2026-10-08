// ─────────────────────────────────────────────────────────────────────────────
// calendar_tour_screen.dart
//
// First-run onboarding: asks user to register their last 3 period starts.
// Visually identical to CalendarScreen (colored phase cells, red rounded header)
// but greyed out until periods are registered. Saves each start to DB.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:bellotadevelopment/core/constants/app_keys.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/presentation/common/bellota_icon.dart';
import 'package:bellotadevelopment/presentation/screens/profile/personal_data_screen.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/domain/repositories/auth_repository.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/core/services/cycle_service.dart';

/// Full-screen calendar tour that overlays a tutorial on top of the calendar.
/// Guides the user to mark the start of their last 3 periods.
class CalendarTourScreen extends StatefulWidget {
  const CalendarTourScreen({super.key});

  @override
  State<CalendarTourScreen> createState() => _CalendarTourScreenState();
}

class _CalendarTourScreenState extends State<CalendarTourScreen>
    with TickerProviderStateMixin {

  // ── State ───────────────────────────────────────────────────────────────────
  DateTime _displayDate = DateTime.now();
  DateTime? _selectedDate;
  int? _userId;

  // Registered period starts (sorted ascending)
  final List<DateTime> _registeredPeriods = [];
  static const int _requiredPeriods = 3;

  // Default cycle params (will be read from prefs later)
  int _cycleDuration = 28;
  int _periodDuration = 5;

  // ── Animations ───────────────────────────────────────────────────────────────
  late AnimationController _headerAnimCtrl;
  late AnimationController _calendarAnimCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _pipCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _calendarFade;
  late Animation<Offset> _calendarSlide;
  late Animation<double> _pulseAnim;
  late Animation<double> _pipAnim;

  // ── Localization helpers ─────────────────────────────────────────────────────
  List<String> get _dayNames => [
        AppLocalizations.of(context)!.calendarSun,
        AppLocalizations.of(context)!.calendarMon,
        AppLocalizations.of(context)!.calendarTue,
        AppLocalizations.of(context)!.calendarWed,
        AppLocalizations.of(context)!.calendarThu,
        AppLocalizations.of(context)!.calendarFri,
        AppLocalizations.of(context)!.calendarSat,
      ];

  List<String> get _monthNames => [
        AppLocalizations.of(context)!.calendarJan,
        AppLocalizations.of(context)!.calendarFeb,
        AppLocalizations.of(context)!.calendarMar,
        AppLocalizations.of(context)!.calendarApr,
        AppLocalizations.of(context)!.calendarMay,
        AppLocalizations.of(context)!.calendarJun,
        AppLocalizations.of(context)!.calendarJul,
        AppLocalizations.of(context)!.calendarAug,
        AppLocalizations.of(context)!.calendarSep,
        AppLocalizations.of(context)!.calendarOct,
        AppLocalizations.of(context)!.calendarNov,
        AppLocalizations.of(context)!.calendarDec,
      ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadUser();

    _headerAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _calendarAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _headerFade = CurvedAnimation(parent: _headerAnimCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerAnimCtrl, curve: Curves.easeOutCubic));
    _calendarFade = CurvedAnimation(parent: _calendarAnimCtrl, curve: Curves.easeOut);
    _calendarSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _calendarAnimCtrl, curve: Curves.easeOutCubic));
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pipAnim = CurvedAnimation(parent: _pipCtrl, curve: Curves.elasticOut);

    _headerAnimCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _calendarAnimCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimCtrl.dispose();
    _calendarAnimCtrl.dispose();
    _pulseCtrl.dispose();
    _pipCtrl.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────────
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    int? uid = prefs.getInt(AppKeys.userId);
    final email = prefs.getString(AppKeys.userEmail) ?? '';
    if (uid == null && email.isNotEmpty) {
      uid = await sl<AuthRepository>().getUserIdByEmail(email);
      if (uid != null) await prefs.setInt(AppKeys.userId, uid);
    }
    if (mounted) setState(() => _userId = uid);
  }

  // ── Phase colors ──────────────────────────────────────────────────────────────
  /// Returns the phase color for a given date.
  /// Grey when no periods registered yet; real colors once we have data.
  Color _phaseColor(DateTime date) {
    if (_registeredPeriods.length < _requiredPeriods) return Colors.grey.shade200;

    final phase = CycleService.instance.getPhaseForDateV2(
      date: date,
      allPeriodStarts: _registeredPeriods,
      defaultCycleDuration: _cycleDuration,
      periodDuration: _periodDuration,
    );
    final colors = Theme.of(context).bellotaColors;
    switch (phase) {
      case CyclePhase.menstrual:   return colors.chilero;
      case CyclePhase.follicular:  return colors.chiltoma;
      case CyclePhase.ovulatory:   return colors.melon;
      case CyclePhase.luteal:      return colors.asuncion;
    }
  }

  bool _isPeriodStart(DateTime date) =>
      _registeredPeriods.any((d) =>
          d.year == date.year && d.month == date.month && d.day == date.day);

  // ── Confirm a period start ────────────────────────────────────────────────────
  Future<void> _confirmPeriodStart() async {
    if (_selectedDate == null) return;
    if (_isPeriodStart(_selectedDate!)) return;

    HapticFeedback.mediumImpact();
    final date = _selectedDate!;
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (_userId != null) {
      final log = await sl<DailyLogRepository>().getDailyLog(_userId!, dateKey);
      await sl<DailyLogRepository>().saveDailyLogV2(
        userId: _userId!,
        date: dateKey,
        periodStart: true,
        symptoms: log?.symptoms ?? [],
        sexo: log?.sexo ?? [],
        flujo: log?.flujo ?? [],
        bleedingIntensity: log?.bleedingIntensity,
        clots: log?.clots,
        spotting: log?.spotting ?? false,
        spottingDays: log?.spottingDays,
        sexualSymptoms: log?.sexualSymptoms,
        painLevel: log?.painLevel,
        painCharacter: log?.painCharacter,
        painDays: log?.painDays,
        treatment: log?.treatment,
        physicalSymptoms: log?.physicalSymptoms ?? [],
        emotionalSymptoms: log?.emotionalSymptoms ?? [],
        breastExam: log?.breastExam,
        notes: log?.notes,
      );
    }

    setState(() {
      _registeredPeriods.add(date);
      _registeredPeriods.sort();
      _selectedDate = null;
    });
    _pipCtrl.forward(from: 0);

    if (_registeredPeriods.length >= _requiredPeriods) {
      await Future.delayed(const Duration(milliseconds: 700));
      _finish();
    }
  }

  void _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_tour_done', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const PersonalDataScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final colors = Theme.of(context).bellotaColors;
        return Scaffold(
          backgroundColor: colors.basilica,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────────
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: _buildHeader(colors),
                  ),
                ),

                // ── Phase legend ──────────────────────────────────────────────
                _buildPhaseLegend(colors),

                // ── Calendar ──────────────────────────────────────────────────
                Expanded(
                  child: SlideTransition(
                    position: _calendarSlide,
                    child: FadeTransition(
                      opacity: _calendarFade,
                      child: _buildCalendarBody(colors),
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

  // ── Header — same red rounded card as CalendarScreen ─────────────────────────
  Widget _buildHeader(BellotaColors colors) {
    final registered = _registeredPeriods.length;
    final remaining = _requiredPeriods - registered;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.chilero, colors.chilero.withOpacity(0.75)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colors.chilero.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          BellotaIcon(color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthNames[_displayDate.month - 1]} ${_displayDate.year}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  registered < _requiredPeriods
                      ? 'Marca $remaining período${remaining == 1 ? '' : 's'} anterior${remaining == 1 ? '' : 'es'}'
                      : '¡Listo! Períodos registrados ✓',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Month nav arrows
          IconButton(
            onPressed: () => setState(() =>
                _displayDate = DateTime(_displayDate.year, _displayDate.month - 1)),
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _displayDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
                ? () => setState(() =>
                    _displayDate = DateTime(_displayDate.year, _displayDate.month + 1))
                : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _displayDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              size: 28,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Phase legend ──────────────────────────────────────────────────────────────
  Widget _buildPhaseLegend(BellotaColors colors) {
    final hasData = _registeredPeriods.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(hasData ? colors.chilero : Colors.grey.shade300, AppLocalizations.of(context)!.cyclePhasesMenstrual),
          const SizedBox(width: 10),
          _legendDot(hasData ? colors.chiltoma : Colors.grey.shade300, AppLocalizations.of(context)!.cyclePhasesFollicular),
          const SizedBox(width: 10),
          _legendDot(hasData ? colors.melon : Colors.grey.shade300, AppLocalizations.of(context)!.cyclePhasesOvulatory),
          const SizedBox(width: 10),
          _legendDot(hasData ? colors.asuncion : Colors.grey.shade300, AppLocalizations.of(context)!.cyclePhasesLuteal),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Theme.of(context).bellotaColors.textoMedio)),
      ],
    );
  }

  // ── Calendar body ─────────────────────────────────────────────────────────────
  Widget _buildCalendarBody(BellotaColors colors) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // TableCalendar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TableCalendar(
            firstDay: DateTime(DateTime.now().year - 3),
            lastDay: DateTime.now(),
            focusedDay: _displayDate,
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerVisible: false,
            daysOfWeekVisible: true,
            daysOfWeekHeight: 38,
            rowHeight: 52,
            availableGestures: AvailableGestures.horizontalSwipe,
            selectedDayPredicate: (day) =>
                _selectedDate != null && isSameDay(_selectedDate!, day),
            onDaySelected: (selected, focused) {
              // Don't allow selecting future dates
              if (selected.isAfter(DateTime.now())) return;
              // Don't allow re-selecting already registered period starts
              if (_isPeriodStart(selected)) return;
              HapticFeedback.selectionClick();
              setState(() {
                _selectedDate = selected;
                _displayDate = focused;
              });
            },
            onPageChanged: (focused) {
              setState(() => _displayDate = focused);
            },
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: true,
              cellMargin: EdgeInsets.all(3),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text = _dayNames[day.weekday == 7 ? 0 : day.weekday];
                return Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.chilero,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(text,
                          style: GoogleFonts.poppins(
                              color: colors.blanco,
                              fontWeight: FontWeight.w700,
                              fontSize: 10)),
                    ),
                  ),
                );
              },
              defaultBuilder: (ctx, day, _) => _buildDayCell(day),
              selectedBuilder: (ctx, day, _) => _buildDayCell(day, selected: true),
              todayBuilder: (ctx, day, _) => _buildDayCell(day),
              outsideBuilder: (ctx, day, _) =>
                  Opacity(opacity: 0.35, child: _buildDayCell(day)),
              disabledBuilder: (ctx, day, _) =>
                  Opacity(opacity: 0.2, child: _buildDayCell(day)),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Bottom panel ──────────────────────────────────────────────────────
        _buildBottomPanel(colors),

        const SizedBox(height: 40),
      ],
    );
  }

  // ── Individual day cell ───────────────────────────────────────────────────────
  Widget _buildDayCell(DateTime date, {bool selected = false}) {
    final isSelected = selected ||
        (_selectedDate != null && isSameDay(_selectedDate!, date));
    final isToday = isSameDay(date, DateTime.now());
    final isPeriodStart = _isPeriodStart(date);
    final phaseColor = _phaseColor(date);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isPeriodStart
            ? Theme.of(context).bellotaColors.chilero
            : isSelected
                ? phaseColor
                : phaseColor.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: isToday && !isSelected && !isPeriodStart
            ? Border.all(color: Theme.of(context).bellotaColors.textoDark, width: 2)
            : isSelected
                ? Border.all(color: Colors.white.withOpacity(0.6), width: 1.5)
                : null,
        boxShadow: isSelected || isPeriodStart
            ? [BoxShadow(color: phaseColor.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3))]
            : [],
      ),
      child: Center(
        child: isPeriodStart
            ? BellotaIcon(color: Colors.white, size: 16)
            : Text(
                '${date.day}',
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).bellotaColors.textoDark,
                  fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  height: 1,
                ),
              ),
      ),
    );
  }

  // ── Bottom panel with progress pips + confirm ─────────────────────────────────
  Widget _buildBottomPanel(BellotaColors colors) {
    final registered = _registeredPeriods.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress pips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_requiredPeriods, (i) {
              final done = i < registered;
              final isCurrent = i == registered;
              return AnimatedBuilder(
                animation: _pipAnim,
                builder: (ctx, child) {
                  final scale = (done && i == registered - 1) ? _pipAnim.value : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: done
                                  ? colors.chilero
                                  : isCurrent
                                      ? colors.chilero.withOpacity(0.25)
                                      : colors.textoMedio.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: isCurrent
                                  ? Border.all(color: colors.chilero, width: 2)
                                  : null,
                            ),
                            child: done
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                : Center(
                                    child: Text('${i + 1}',
                                        style: TextStyle(
                                          color: isCurrent ? colors.chilero : colors.textoMedio.withOpacity(0.4),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        )),
                                  ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            done && i < _registeredPeriods.length
                                ? '${_registeredPeriods[i].day} ${_monthNames[_registeredPeriods[i].month - 1].substring(0, 3)}'
                                : 'Período ${i + 1}',
                            style: TextStyle(
                              fontSize: 9,
                              color: done ? colors.chilero : colors.textoMedio.withOpacity(0.4),
                              fontWeight: done ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(height: 16),

          // Selected date confirm card
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedDate != null && registered < _requiredPeriods
                ? AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) =>
                        Transform.scale(scale: _pulseAnim.value, child: child),
                    child: Container(
                      key: ValueKey(_selectedDate),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.chilero.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.chilero.withOpacity(0.4), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          BellotaIcon(color: colors.chilero, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_dayNames[_selectedDate!.weekday == 7 ? 0 : _selectedDate!.weekday]}, ${_selectedDate!.day} de ${_monthNames[_selectedDate!.month - 1]}',
                                  style: TextStyle(
                                    color: colors.textoDark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Inicio del período ${registered + 1} de $_requiredPeriods',
                                  style: TextStyle(color: colors.textoMedio, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    key: const ValueKey('hint'),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      registered < _requiredPeriods
                          ? 'Toca el día en que comenzó tu último período'
                          : '¡Todos los períodos registrados!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textoMedio,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),

          if (_selectedDate != null && registered < _requiredPeriods) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _confirmPeriodStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.chilero,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 4,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Outfit'),
              ),
              child: Text('Confirmar período ${registered + 1} de $_requiredPeriods'),
            ),
          ],
          if (_registeredPeriods.isNotEmpty) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _registeredPeriods.removeLast());
              },
              icon: Icon(Icons.undo_rounded, color: colors.textoMedio, size: 15),
              label: Text('Deshacer último', style: TextStyle(color: colors.textoMedio, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
