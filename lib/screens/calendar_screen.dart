import '../core/constants/app_keys.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import '../widgets/bellota_icon.dart';
import '../database/database_helper.dart';
import 'symptom_log_screen.dart';
import '../core/services/cycle_service.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

enum CalendarViewType { weekly, monthly, annual }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  // ─── Data ────────────────────────────────────────────────────────
  int? _userId;
  DateTime? _lastPeriodStart;
  int _cycleDuration = 28;
  int _periodDuration = 5;
  int _effectiveCycleDuration = 28;
  List<DateTime> _allPeriodStarts = [];
  Set<String> _loggedDates = {};

  // ─── Navigation ──────────────────────────────────────────────────
  CalendarViewType _currentView = CalendarViewType.monthly;
  final DateTime _currentDate = DateTime.now();
  DateTime _displayDate = DateTime.now();
  DateTime? _selectedDate;
  DateTime? _annualDetailMonth;

  // ─── Animations ──────────────────────────────────────────────────
  late AnimationController _headerAnimController;
  late AnimationController _calendarAnimController;
  late AnimationController _pulseController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _calendarFade;
  late Animation<Offset> _calendarSlide;
  late Animation<double> _pulseAnim;

  // ─── Log Future ──────────────────────────────────────────────────
  Future<Map<String, dynamic>?>? _selectedDayLogFuture;

  // ─── Month names (eager) ─────────────────────────────────────────
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

  List<String> get _dayNames => [
        AppLocalizations.of(context)!.calendarSun,
        AppLocalizations.of(context)!.calendarMon,
        AppLocalizations.of(context)!.calendarTue,
        AppLocalizations.of(context)!.calendarWed,
        AppLocalizations.of(context)!.calendarThu,
        AppLocalizations.of(context)!.calendarFri,
        AppLocalizations.of(context)!.calendarSat,
      ];

  // ─── Lifecycle ───────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _selectedDate = _currentDate;

    _headerAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _calendarAnimController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _headerFade = CurvedAnimation(
        parent: _headerAnimController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _headerAnimController, curve: Curves.easeOutCubic));
    _calendarFade = CurvedAnimation(
        parent: _calendarAnimController, curve: Curves.easeOut);
    _calendarSlide = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _calendarAnimController, curve: Curves.easeOutCubic));
    _pulseAnim =
        Tween<double>(begin: 0.85, end: 1.0).animate(_pulseController);

    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 200),
        () => _calendarAnimController.forward());

    _loadInitialData();
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _calendarAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Data Loading ────────────────────────────────────────────────
  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt(AppKeys.userId);

    DateTime? lastPeriodStart;
    int cycleDuration = 28;
    int periodDuration = 5;
    List<DateTime> allPeriodStarts = [];
    Set<String> loggedDates = {};
    int effectiveDuration = 28;

    if (userId != null) {
      lastPeriodStart =
          await DatabaseHelper.instance.getLastPeriodStart(userId);
      if (!mounted) return;
      allPeriodStarts =
          await DatabaseHelper.instance.getAllPeriodStartDates(userId);
      if (!mounted) return;

      final profile = await DatabaseHelper.instance.getProfile(userId);
      if (!mounted) return;
      if (profile != null) {
        cycleDuration = profile['cycle_duration'] as int? ?? 28;
        periodDuration = profile['period_duration'] as int? ?? 5;
      }

      effectiveDuration = CycleService.instance.getEffectiveCycleDuration(
          cycleDuration, allPeriodStarts.isNotEmpty ? allPeriodStarts : null);

      final startRange = '${_currentDate.year - 3}-01-01';
      final endRange = '${_currentDate.year + 3}-12-31';
      loggedDates = await DatabaseHelper.instance
          .getLoggedDatesInRange(userId, startRange, endRange);
      if (!mounted) return;
    }

    setState(() {
      _userId = userId;
      _lastPeriodStart = lastPeriodStart;
      _cycleDuration = cycleDuration;
      _periodDuration = periodDuration;
      _effectiveCycleDuration = effectiveDuration;
      _allPeriodStarts = allPeriodStarts;
      _loggedDates = loggedDates;
      _loadSelectedDayLog();
    });
  }

  void _loadSelectedDayLog() {
    if (_selectedDate != null && _userId != null) {
      _selectedDayLogFuture = DatabaseHelper.instance.getDailyLog(
          _userId!,
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}');
    }
  }

  // ─── Phase colors ────────────────────────────────────────────────
  /// Returns phase color for [date] using per-cycle accurate calculation.
  Color _getPhaseColorForDay(DateTime date) {
    if (_allPeriodStarts.isEmpty) return Colors.grey[300]!;

    final phase = CycleService.instance.getPhaseForDateV2(
      date: date,
      allPeriodStarts: _allPeriodStarts,
      defaultCycleDuration: _cycleDuration,
      periodDuration: _periodDuration,
    );

    switch (phase) {
      case CyclePhase.menstrual:
        return Theme.of(context).bellotaColors.chilero;
      case CyclePhase.follicular:
        return Theme.of(context).bellotaColors.chiltoma;
      case CyclePhase.ovulatory:
        return Theme.of(context).bellotaColors.melon;
      case CyclePhase.luteal:
        return Theme.of(context).bellotaColors.asuncion;
    }
  }

  bool _isPeriodStartDay(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _allPeriodStarts.any((d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' ==
        key);
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, child) {
        return Column(
          children: [
            // ── Animated Header ─────────────────────────────────────
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: _buildHeader(context, colors),
              ),
            ),

            // ── Phase Legend ────────────────────────────────────────
            if (_currentView != CalendarViewType.annual)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPhaseLegend(colors),
                ),
              ),

            // ── Calendar Body ───────────────────────────────────────
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
        );
      },
    );
  }

  // ─── Header ──────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, BellotaColors colors) {
    String title = _getHeaderTitle();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.chilero,
            colors.chilero.withValues(alpha: 0.75),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.chilero.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          

          // ── Month / Week Title ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: colors.blanco,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                if (_lastPeriodStart != null)
                  Text(
                    _getNextPeriodLabel(),
                    style: GoogleFonts.poppins(
                      color: colors.blanco.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // ── View Selector ────────────────────────────────────────
          _buildViewSelector(colors),
          const SizedBox(width: 8),
          BellotaTopActions(
            showSettings: false,
            showNotifications: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCycleDayBadge(BellotaColors colors) {
    final d = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    final start = DateTime(_lastPeriodStart!.year, _lastPeriodStart!.month,
        _lastPeriodStart!.day);
    final diff = d.difference(start).inDays;
    final cycleDay = (diff % _effectiveCycleDuration) + 1;

    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: colors.blanco.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: colors.blanco.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$cycleDay',
              style: GoogleFonts.poppins(
                  color: colors.blanco,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  height: 1),
            ),
            Text(
              'día',
              style: GoogleFonts.poppins(
                  color: colors.blanco.withValues(alpha: 0.8), fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  String _getHeaderTitle() {
    if (_currentView == CalendarViewType.annual && _annualDetailMonth == null) {
      return '${_displayDate.year}';
    } else if (_annualDetailMonth != null) {
      return '${_monthNames[_annualDetailMonth!.month - 1]} ${_annualDetailMonth!.year}';
    } else if (_currentView == CalendarViewType.monthly) {
      return '${_monthNames[_displayDate.month - 1]} ${_displayDate.year}';
    } else {
      // weekly
      final weekday =
          _displayDate.weekday == 7 ? 0 : _displayDate.weekday;
      final start = _displayDate.subtract(Duration(days: weekday));
      final end = start.add(const Duration(days: 6));
      return '${start.day} – ${end.day} ${_monthNames[start.month - 1]}';
    }
  }

  String _getNextPeriodLabel() {
    if (_lastPeriodStart == null) return '';
    final today = DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
    final start = DateTime(
        _lastPeriodStart!.year, _lastPeriodStart!.month, _lastPeriodStart!.day);
    final diff = today.difference(start).inDays;
    final cyclesPassed = diff >= 0 ? diff ~/ _effectiveCycleDuration : 0;
    final currentCycleStart =
        start.add(Duration(days: cyclesPassed * _effectiveCycleDuration));
    final nextPeriod =
        currentCycleStart.add(Duration(days: _effectiveCycleDuration));
    final daysLeft = nextPeriod.difference(today).inDays;
    if (daysLeft <= 0) return 'Período esperado hoy o pronto';
    if (daysLeft == 1) return 'Próximo período en 1 día';
    return 'Próximo período en $daysLeft días';
  }

  Widget _buildViewSelector(BellotaColors colors) {
    final labels = {
      CalendarViewType.monthly: 'Mes',
      CalendarViewType.weekly: 'Semana',
      CalendarViewType.annual: 'Año',
    };
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _buildViewPickerSheet(colors),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.blanco.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.blanco.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labels[_currentView]!,
              style: GoogleFonts.poppins(
                  color: colors.blanco,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, color: colors.blanco, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildViewPickerSheet(BellotaColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.blanco,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: colors.textoMedio.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Vista del calendario',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.textoDark)),
          const SizedBox(height: 16),
          for (final entry in {
            CalendarViewType.monthly: ('Mensual', Icons.calendar_month_rounded),
            CalendarViewType.weekly: ('Semanal', Icons.view_week_rounded),
            CalendarViewType.annual: ('Anual', Icons.calendar_today_rounded),
          }.entries)
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              tileColor: _currentView == entry.key
                  ? colors.chilero.withValues(alpha: 0.1)
                  : null,
              leading: Icon(entry.value.$2,
                  color: _currentView == entry.key
                      ? colors.chilero
                      : colors.textoMedio),
              title: Text(entry.value.$1,
                  style: GoogleFonts.poppins(
                      fontWeight: _currentView == entry.key
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _currentView == entry.key
                          ? colors.chilero
                          : colors.textoDark)),
              trailing: _currentView == entry.key
                  ? Icon(Icons.check_circle_rounded, color: colors.chilero)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                setState(() {
                  _currentView = entry.key;
                  _annualDetailMonth = null;
                  _displayDate = _currentDate;
                  if (_currentView != CalendarViewType.annual) {
                    _selectedDate = _currentDate;
                    _loadSelectedDayLog();
                  } else {
                    _selectedDate = null;
                  }
                });
                _calendarAnimController
                  ..reset()
                  ..forward();
              },
            ),
        ],
      ),
    );
  }

  // ─── Phase Legend ─────────────────────────────────────────────────
  Widget _buildPhaseLegend(BellotaColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: [
          _legendItem(colors.chilero, AppLocalizations.of(context)!.cyclePhasesMenstrual),
          _legendItem(colors.chiltoma, AppLocalizations.of(context)!.cyclePhasesFollicular),
          _legendItem(colors.melon, AppLocalizations.of(context)!.cyclePhasesOvulatory),
          _legendItem(colors.asuncion, AppLocalizations.of(context)!.cyclePhasesLuteal),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).bellotaColors.textoMedio)),
      ],
    );
  }

  // ─── Calendar Body ────────────────────────────────────────────────
  Widget _buildCalendarBody(BellotaColors colors) {
    if (_currentView == CalendarViewType.annual && _annualDetailMonth != null) {
      return Column(
        children: [
          _buildAnnualDetailHeader(colors),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  _buildCompactMonthGrid(
                      _annualDetailMonth!.year, _annualDetailMonth!.month),
                  if (_selectedDate != null) _buildSymptomsBox(colors),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          if (_currentView == CalendarViewType.annual) _buildAnnualView(colors),
          if (_currentView != CalendarViewType.annual)
            _buildTableCalendar(colors),
          if (_selectedDate != null && _currentView != CalendarViewType.annual)
            _buildSymptomsBox(colors),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ─── TableCalendar (weekly & monthly) ────────────────────────────
  Widget _buildTableCalendar(BellotaColors colors) {
    final format = _currentView == CalendarViewType.weekly
        ? CalendarFormat.week
        : CalendarFormat.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TableCalendar(
        firstDay: DateTime(_currentDate.year - 5),
        lastDay: DateTime(_currentDate.year + 5),
        focusedDay: _displayDate,
        calendarFormat: format,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        headerVisible: false,
        daysOfWeekVisible: true,
        daysOfWeekHeight: 38,
        rowHeight: _currentView == CalendarViewType.weekly ? 72 : 52,
        availableGestures: AvailableGestures.horizontalSwipe,
        selectedDayPredicate: (day) =>
            _selectedDate != null &&
            isSameDay(_selectedDate!, day),
        onDaySelected: (selectedDay, focusedDay) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedDate = selectedDay;
            _displayDate = focusedDay;
            _loadSelectedDayLog();
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _displayDate = focusedDay;
          });
        },
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: true,
          cellMargin: EdgeInsets.all(3),
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            final text =
                _dayNames[day.weekday == 7 ? 0 : day.weekday];
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                    color: colors.chilero,
                    borderRadius: BorderRadius.circular(8)),
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
          defaultBuilder: (ctx, day, _) => _buildDayCell(day, false),
          selectedBuilder: (ctx, day, _) => _buildDayCell(day, true),
          todayBuilder: (ctx, day, _) => _buildDayCell(day, false),
          outsideBuilder: (ctx, day, _) => Opacity(
            opacity: 0.4,
            child: _buildDayCell(day, false),
          ),
          disabledBuilder: (ctx, day, _) => Opacity(
            opacity: 0.3,
            child: _buildDayCell(day, false),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, bool forceSelected) {
    final isSelected = forceSelected ||
        (_selectedDate != null && isSameDay(_selectedDate!, date));
    final isToday = isSameDay(date, _currentDate);
    final phaseColor = _allPeriodStarts.isEmpty
        ? Colors.grey[300]!
        : _getPhaseColorForDay(date);
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final hasLog = _loggedDates.contains(dateKey);
    final isPeriodStart = _isPeriodStartDay(date);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(2),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isSelected
            ? phaseColor
            : phaseColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: isToday
            ? Border.all(
                color: Theme.of(context).bellotaColors.textoDark, width: 2)
            : isSelected
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.6), width: 1.5)
                : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                    color: phaseColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ]
            : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: GoogleFonts.poppins(
                  color: isSelected || isPeriodStart
                      ? Colors.white
                      : Theme.of(context).bellotaColors.textoDark,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  height: 1,
                ),
              ),
              if (hasLog) ...[
                const SizedBox(height: 3),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context)
                            .bellotaColors
                            .textoDark
                            .withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Annual View ──────────────────────────────────────────────────
  Widget _buildAnnualView(BellotaColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: List.generate(12, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildCompactMonthGrid(_displayDate.year, i + 1),
          );
        }),
      ),
    );
  }

  Widget _buildCompactMonthGrid(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    // Sunday = 0, Monday = 1 …
    int emptyDays = firstDay.weekday == 7 ? 0 : firstDay.weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '${_monthNames[month - 1]} $year',
            style: GoogleFonts.poppins(
                color: Theme.of(context).bellotaColors.chilero,
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
        ),
        _buildDaysHeader(),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daysInMonth + emptyDays,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemBuilder: (ctx, index) {
            if (index < emptyDays) return const SizedBox();
            final date = DateTime(year, month, index - emptyDays + 1);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDate = date;
                  _loadSelectedDayLog();
                  if (_annualDetailMonth == null) {
                    _annualDetailMonth = DateTime(year, month, 1);
                  }
                });
              },
              child: _buildDayCell(date, false),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDaysHeader() {
    return Row(
      children: _dayNames.map((day) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.chilero,
                borderRadius: BorderRadius.circular(6)),
            child: Center(
              child: Text(day,
                  style: TextStyle(
                      color: Theme.of(context).bellotaColors.blanco,
                      fontWeight: FontWeight.bold,
                      fontSize: 9)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnnualDetailHeader(BellotaColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _annualDetailMonth = null;
            _selectedDate = null;
          }),
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 16, color: colors.chilero),
          label: Text(
              AppLocalizations.of(context)!.calendarViewsBackToYear,
              style: TextStyle(
                  color: colors.chilero, fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: colors.chilero.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }

  // ─── Symptoms Box ─────────────────────────────────────────────────
  Widget _buildSymptomsBox(BellotaColors colors) {
    if (_selectedDate == null) return const SizedBox();
    final lang = languageNotifier.currentLang;
    final de = lang == 'en' ? '' : ' de ';
    final dateStr = lang == 'en'
        ? '${_dayNames[_selectedDate!.weekday == 7 ? 0 : _selectedDate!.weekday]}, ${_monthNames[_selectedDate!.month - 1]} ${_selectedDate!.day}, ${_selectedDate!.year}'
        : '${_dayNames[_selectedDate!.weekday == 7 ? 0 : _selectedDate!.weekday]}, ${_selectedDate!.day}$de${_monthNames[_selectedDate!.month - 1]} ${_selectedDate!.year}';

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final canRegister = !_selectedDate!.isAfter(todayEnd);

    // Phase info for selected day
    final phaseColor = _allPeriodStarts.isEmpty
        ? Colors.grey
        : _getPhaseColorForDay(_selectedDate!);
    final phaseName = _allPeriodStarts.isEmpty
        ? ''
        : _getPhaseNameForDay(_selectedDate!);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _selectedDayLogFuture,
        builder: (context, snapshot) {
          final log = snapshot.data;
          List<String> symptoms = [];
          List<String> sexo = [];
          List<String> flujo = [];
          bool periodStart = false;

          if (log != null) {
            try {
              symptoms = List<String>.from(
                  jsonDecode(log['symptoms'] as String? ?? '[]'));
            } catch (_) {}
            try {
              sexo = List<String>.from(
                  jsonDecode(log['sexo'] as String? ?? '[]'));
            } catch (_) {}
            try {
              flujo = List<String>.from(
                  jsonDecode(log['flujo'] as String? ?? '[]'));
            } catch (_) {}
            periodStart = (log['period_start'] as int?) == 1;
          }

          final hasData = symptoms.isNotEmpty ||
              sexo.isNotEmpty ||
              flujo.isNotEmpty ||
              periodStart;

          return Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: colors.blanco,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Phase color top strip ──────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        phaseColor.withValues(alpha: 0.18),
                        phaseColor.withValues(alpha: 0.05),
                      ],
                      end: Alignment.centerRight,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr,
                          style: GoogleFonts.poppins(
                              color: colors.textoDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      if (phaseName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: phaseColor,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Text(phaseName,
                                  style: GoogleFonts.poppins(
                                      color: phaseColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Register button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: canRegister
                              ? () async {
                                  HapticFeedback.mediumImpact();
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SymptomLogScreen(
                                          selectedDate: _selectedDate),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadInitialData();
                                    setState(() => _loadSelectedDayLog());
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: Text(
                              AppLocalizations.of(context)!
                                  .symptomsAndActionsLogSymptoms,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.chilero,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[200],
                            disabledForegroundColor: Colors.grey[400],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Symptoms content ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: !hasData
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (periodStart)
                              _buildSymptomItem(
                                  colors.chilero,
                                  AppLocalizations.of(context)!
                                      .symptomsAndActionsPeriodStart),
                            ...symptoms.map((s) => _buildSymptomItem(
                                colors.asuncion, _translateKey(s))),
                            ...sexo.map((s) => _buildSymptomItem(
                                colors.melon, _translateKey(s))),
                            ...flujo.map((s) => _buildSymptomItem(
                                const Color(0xFFA566C1), _translateKey(s))),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getPhaseNameForDay(DateTime date) {
    final phase = CycleService.instance.getPhaseForDateV2(
      date: date,
      allPeriodStarts: _allPeriodStarts,
      defaultCycleDuration: _cycleDuration,
      periodDuration: _periodDuration,
    );
    switch (phase) {
      case CyclePhase.menstrual:
        return AppLocalizations.of(context)!.cyclePhasesMenstrual;
      case CyclePhase.follicular:
        return AppLocalizations.of(context)!.cyclePhasesFollicular;
      case CyclePhase.ovulatory:
        return AppLocalizations.of(context)!.cyclePhasesOvulatory;
      case CyclePhase.luteal:
        return AppLocalizations.of(context)!.cyclePhasesLuteal;
    }
  }

  Widget _buildSymptomItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BellotaIcon(color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _translateKey(String key) {
    final lang = languageNotifier.currentLang;
    final translated =
        AppTranslations.get('registration_form', key, lang, context: context);
    if (translated == key) {
      return AppTranslations.get('symptoms', key, lang, context: context);
    }
    return translated;
  }
}
