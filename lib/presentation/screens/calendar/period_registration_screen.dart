// ─────────────────────────────────────────────────────────────────────────────
// period_registration_screen.dart
// Asks user to register their last 3 period starts using the same calendar
// visual as CalendarTourScreen. Calculates regularity and saves to DB.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:bellotadevelopment/core/constants/app_keys.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/presentation/common/bellota_icon.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/domain/repositories/auth_repository.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';

class PeriodRegistrationScreen extends StatefulWidget {
  /// Called when all 3 periods have been confirmed and saved.
  final VoidCallback? onComplete;
  const PeriodRegistrationScreen({super.key, this.onComplete});

  @override
  State<PeriodRegistrationScreen> createState() =>
      _PeriodRegistrationScreenState();
}

class _PeriodRegistrationScreenState extends State<PeriodRegistrationScreen>
    with TickerProviderStateMixin {
  // Up to 3 registered period starts (sorted ascending)
  final List<DateTime> _registeredPeriods = [];
  DateTime? _selectedDate;
  DateTime _displayDate = DateTime.now();
  int? _userId;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _entryCtrl;
  late Animation<double> _entryAnim;

  // For the acorn "pip" animation when a period is confirmed
  late AnimationController _pipCtrl;
  late Animation<double> _pipAnim;

  static const int _requiredPeriods = 3;

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

  @override
  void initState() {
    super.initState();
    _loadUser();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _entryAnim =
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);

    _pipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pipAnim = CurvedAnimation(parent: _pipCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _pipCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    int? uid = prefs.getInt(AppKeys.userId);
    final email = prefs.getString(AppKeys.userEmail) ?? '';
    if (uid == null && email.isNotEmpty) {
      uid = await sl<AuthRepository>().getUserIdByEmail(email);
      if (uid != null) await prefs.setInt(AppKeys.userId, uid);
    }
    setState(() => _userId = uid);
  }

  // ── Confirm selected date as a period start ─────────────────────────────────
  Future<void> _confirmSelectedDate() async {
    if (_selectedDate == null) return;
    if (_registeredPeriods.any((d) =>
        d.year == _selectedDate!.year &&
        d.month == _selectedDate!.month &&
        d.day == _selectedDate!.day)) return;

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
      await Future.delayed(const Duration(milliseconds: 800));
      _finish();
    }
  }

  void _finish() {
    if (mounted) {
      widget.onComplete?.call();
      if (Navigator.canPop(context)) Navigator.pop(context, _registeredPeriods);
    }
  }

  void _removeLastPeriod() {
    if (_registeredPeriods.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _registeredPeriods.removeLast());
  }

  // ── Grid dates for current display month ────────────────────────────────────
  List<DateTime?> _gridDates() {
    final firstDay = DateTime(_displayDate.year, _displayDate.month, 1);
    final startOffset = firstDay.weekday == 7 ? 0 : firstDay.weekday;
    final daysInMonth =
        DateTime(_displayDate.year, _displayDate.month + 1, 0).day;
    final cells = startOffset + daysInMonth;
    final totalCells = (cells / 7).ceil() * 7;

    return List.generate(totalCells, (i) {
      final dayNum = i - startOffset + 1;
      if (dayNum < 1 || dayNum > daysInMonth) return null;
      return DateTime(_displayDate.year, _displayDate.month, dayNum);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final colors = Theme.of(context).bellotaColors;
        final registered = _registeredPeriods.length;
        final remaining = _requiredPeriods - registered;

        return Scaffold(
          backgroundColor: colors.basilica,
          body: SafeArea(
            child: FadeTransition(
              opacity: _entryAnim,
              child: Column(
                children: [
                  _buildHeader(colors, registered),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildProgressPips(colors, registered),
                          const SizedBox(height: 8),
                          _buildCalendar(colors),
                          const SizedBox(height: 16),
                          _buildBottomPanel(colors, remaining),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BellotaColors colors, int registered) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          BellotaIcon(color: colors.chilero, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthNames[_displayDate.month - 1]} ${_displayDate.year}',
                  style: TextStyle(
                    color: colors.textoDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Outfit',
                  ),
                ),
                Text(
                  registered < _requiredPeriods
                      ? 'Toca el inicio de cada período'
                      : '¡Listo! Períodos registrados',
                  style: TextStyle(
                    color: colors.textoMedio,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() =>
                _displayDate = DateTime(_displayDate.year, _displayDate.month - 1)),
            icon: Icon(Icons.chevron_left_rounded, color: colors.chilero, size: 28),
          ),
          IconButton(
            onPressed: _displayDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
                ? () => setState(() =>
                    _displayDate = DateTime(_displayDate.year, _displayDate.month + 1))
                : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _displayDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month))
                  ? colors.chilero
                  : colors.textoMedio.withOpacity(0.3),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ── Acorn progress pips ──────────────────────────────────────────────────────
  Widget _buildProgressPips(BellotaColors colors, int registered) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_requiredPeriods, (i) {
          final done = i < registered;
          final isCurrent = i == registered;
          return AnimatedBuilder(
            animation: _pipAnim,
            builder: (ctx, child) {
              final scale = (done && i == registered - 1)
                  ? _pipAnim.value
                  : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Acorn body
                          _AcornIcon(
                            size: 48,
                            filled: done,
                            color: done
                                ? colors.chilero
                                : isCurrent
                                    ? colors.melon
                                    : colors.textoMedio.withOpacity(0.25),
                          ),
                          if (done)
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: colors.chilero,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.check, size: 9, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        done
                            ? '${_registeredPeriods[i].day} ${_monthNames[_registeredPeriods[i].month - 1].substring(0, 3)}'
                            : 'Período ${i + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: done ? FontWeight.bold : FontWeight.normal,
                          color: done ? colors.chilero : colors.textoMedio.withOpacity(0.5),
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
    );
  }

  // ── Calendar grid ──────────────────────────────────────────────────────────
  Widget _buildCalendar(BellotaColors colors) {
    final days = _dayNames;
    final grid = _gridDates();
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Day labels
          Row(
            children: days
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textoMedio,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar cells
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: grid.map((date) {
              if (date == null) return const SizedBox.shrink();

              final isFuture = date.isAfter(today);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = _selectedDate != null &&
                  date.year == _selectedDate!.year &&
                  date.month == _selectedDate!.month &&
                  date.day == _selectedDate!.day;
              final isRegistered = _registeredPeriods.any((d) =>
                  d.year == date.year &&
                  d.month == date.month &&
                  d.day == date.day);

              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedDate = date);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isRegistered
                        ? colors.chilero
                        : isSelected
                            ? colors.chilero.withOpacity(0.85)
                            : isFuture
                                ? Colors.grey.shade200
                                : colors.blanco,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected && !isRegistered
                        ? Border.all(color: colors.chilero, width: 1.5)
                        : Border.all(
                            color: isSelected || isRegistered
                                ? colors.chilero
                                : Colors.grey.shade300,
                            width: isSelected || isRegistered ? 2 : 1,
                          ),
                    boxShadow: isSelected || isRegistered
                        ? [BoxShadow(color: colors.chilero.withOpacity(0.35), blurRadius: 5)]
                        : null,
                  ),
                  child: Center(
                    child: isRegistered
                        ? BellotaIcon(color: Colors.white, size: 16)
                        : Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isFuture
                                  ? Colors.grey.shade400
                                  : isSelected
                                      ? colors.blanco
                                      : colors.textoDark,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Bottom selection panel ─────────────────────────────────────────────────
  Widget _buildBottomPanel(BellotaColors colors, int remaining) {
    final canUndo = _registeredPeriods.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected date chip
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedDate != null
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
                        border: Border.all(
                          color: colors.chilero.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          BellotaIcon(color: colors.chilero, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            '${_dayNames[_selectedDate!.weekday == 7 ? 0 : _selectedDate!.weekday]}, '
                            '${_selectedDate!.day} de ${_monthNames[_selectedDate!.month - 1]}',
                            style: TextStyle(
                              color: colors.textoDark,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Inicio del período',
                            style: TextStyle(
                              color: colors.textoMedio.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    key: const ValueKey('empty'),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    child: Text(
                      remaining > 0
                          ? 'Toca un día en el calendario\npara marcarlo'
                          : '¡Ya registraste todos tus períodos!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textoMedio,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Confirm button
          if (_selectedDate != null && remaining > 0) ...[
            ElevatedButton(
              onPressed: _confirmSelectedDate,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.chilero,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 4,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Outfit',
                ),
              ),
              child: Text('Confirmar período ${_registeredPeriods.length + 1} de $_requiredPeriods'),
            ),
          ],
          if (canUndo) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _removeLastPeriod,
              icon: Icon(Icons.undo_rounded, color: colors.textoMedio, size: 16),
              label: Text(
                'Deshacer último',
                style: TextStyle(color: colors.textoMedio, fontSize: 13),
              ),
            ),
          ],
          if (!canUndo && _selectedDate == null) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                Icon(Icons.touch_app_rounded, color: colors.textoMedio.withOpacity(0.4), size: 18),
                Text(
                  'Desliza entre meses con las flechas',
                  style: TextStyle(color: colors.textoMedio.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Acorn painter widget ─────────────────────────────────────────────────────
class _AcornIcon extends StatelessWidget {
  final double size;
  final bool filled;
  final Color color;

  const _AcornIcon({required this.size, required this.filled, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AcornPainter(color: color, filled: filled),
      ),
    );
  }
}

class _AcornPainter extends CustomPainter {
  final Color color;
  final bool filled;

  const _AcornPainter({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final w = size.width;
    final h = size.height;

    // Cap (top part of acorn) - roughly top 40%
    final capRect = Rect.fromLTWH(w * 0.08, h * 0.02, w * 0.84, h * 0.42);
    final capPath = Path()
      ..moveTo(w * 0.2, h * 0.44)
      ..lineTo(w * 0.08, h * 0.44)
      ..arcToPoint(Offset(w * 0.08, h * 0.22), radius: Radius.circular(h * 0.22), clockwise: false)
      ..arcToPoint(Offset(w * 0.92, h * 0.22), radius: Radius.circular(w * 0.5), clockwise: false)
      ..arcToPoint(Offset(w * 0.92, h * 0.44), radius: Radius.circular(h * 0.22), clockwise: false)
      ..lineTo(w * 0.8, h * 0.44)
      ..close();
    canvas.drawPath(capPath, paint);

    // Stem on top
    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.62, h * 0.22), Offset(w * 0.72, h * 0.04), stemPaint);

    // Body (bottom round part)
    final bodyPath = Path()
      ..moveTo(w * 0.2, h * 0.44)
      ..lineTo(w * 0.8, h * 0.44)
      ..cubicTo(w * 0.9, h * 0.55, w * 0.95, h * 0.7, w * 0.5, h * 0.98)
      ..cubicTo(w * 0.05, h * 0.7, w * 0.1, h * 0.55, w * 0.2, h * 0.44)
      ..close();
    canvas.drawPath(bodyPath, paint);

    // Cross-hatch lines on cap (only when filled)
    if (filled) {
      final linePaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      for (int i = 1; i < 4; i++) {
        final x = w * 0.08 + (w * 0.84 / 4) * i;
        canvas.drawLine(Offset(x, h * 0.22), Offset(x, h * 0.44), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_AcornPainter old) =>
      old.color != color || old.filled != filled;
}
