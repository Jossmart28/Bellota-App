import '../core/constants/app_keys.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import '../widgets/bellota_icon.dart';
import '../database/database_helper.dart';
import 'symptom_log_screen.dart';
import '../core/services/cycle_service.dart';

enum CalendarViewType { weekly, monthly, annual }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _userName = 'UsuarioApp';
  String _userEmail = 'correo@ejemplo.com';
  int? _userId;
  DateTime? _lastPeriodStart;
  DateTime? _firstPeriodStart;
  int _cycleDuration = 28;
  int _periodDuration = 5;
  int _effectiveCycleDuration = 28;
  List<DateTime> _allPeriodStarts = [];
  Set<String> _loggedDates = {};

  CalendarViewType _currentView = CalendarViewType.monthly;
  final DateTime _currentDate = DateTime.now(); // Fecha real actual
  DateTime _displayDate = DateTime.now(); // Fecha del mes/semana que se está viendo
  DateTime? _selectedDate; // Día seleccionado por la usuaria

  // Controlador para el scroll en la vista de mes
  late PageController _monthPageController;
  final int _initialPage = 1200;

  // Estado para la Subventana de la vista anual
  DateTime? _annualDetailMonth;

  Future<Map<String, dynamic>?>? _selectedDayLogFuture;

  void _loadSelectedDayLog() {
    if (_selectedDate != null && _userId != null) {
      _selectedDayLogFuture = DatabaseHelper.instance.getDailyLog(_userId!, '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}');
    }
  }

  List<String> get _dayNames {
    final lang = languageNotifier.currentLang;
    return [
      AppTranslations.get('calendar', 'sun', lang),
      AppTranslations.get('calendar', 'mon', lang),
      AppTranslations.get('calendar', 'tue', lang),
      AppTranslations.get('calendar', 'wed', lang),
      AppTranslations.get('calendar', 'thu', lang),
      AppTranslations.get('calendar', 'fri', lang),
      AppTranslations.get('calendar', 'sat', lang),
    ];
  }

  List<String> get _monthNames {
    final lang = languageNotifier.currentLang;
    return [
      AppTranslations.get('calendar', 'jan', lang),
      AppTranslations.get('calendar', 'feb', lang),
      AppTranslations.get('calendar', 'mar', lang),
      AppTranslations.get('calendar', 'apr', lang),
      AppTranslations.get('calendar', 'may', lang),
      AppTranslations.get('calendar', 'jun', lang),
      AppTranslations.get('calendar', 'jul', lang),
      AppTranslations.get('calendar', 'aug', lang),
      AppTranslations.get('calendar', 'sep', lang),
      AppTranslations.get('calendar', 'oct', lang),
      AppTranslations.get('calendar', 'nov', lang),
      AppTranslations.get('calendar', 'dec', lang),
    ];
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _currentDate;
    _monthPageController = PageController(initialPage: _initialPage);
    _loadInitialData();
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final String userName = prefs.getString(AppKeys.userName) ?? 'UsuarioApp';
    final String userEmail = prefs.getString(AppKeys.userEmail) ?? 'correo@ejemplo.com';
    final int? userId = prefs.getInt(AppKeys.userId);

    DateTime? lastPeriodStart;
    DateTime? firstPeriodStart;
    int cycleDuration = 28;
    int periodDuration = 5;
    List<DateTime> allPeriodStarts = [];
    Set<String> loggedDates = {};
    int effectiveDuration = 28;

    if (userId != null) {
      lastPeriodStart = await DatabaseHelper.instance.getLastPeriodStart(userId);
      if (!mounted) return;
      firstPeriodStart = await DatabaseHelper.instance.getFirstPeriodStart(userId);
      if (!mounted) return;
      allPeriodStarts = await DatabaseHelper.instance.getAllPeriodStartDates(userId);
      if (!mounted) return;
      
      // Load cycle configuration from profile
      final profile = await DatabaseHelper.instance.getProfile(userId);
      if (!mounted) return;
      if (profile != null) {
        cycleDuration = profile['cycle_duration'] as int? ?? 28;
        periodDuration = profile['period_duration'] as int? ?? 5;
      }
      
      effectiveDuration = CycleService.instance.getEffectiveCycleDuration(cycleDuration, allPeriodStarts.isNotEmpty ? allPeriodStarts : null);

      // Load logged dates for dots (we fetch +/- 2 years around current date to be safe)
      final startRange = '${_currentDate.year - 2}-01-01';
      final endRange = '${_currentDate.year + 2}-12-31';
      loggedDates = await DatabaseHelper.instance.getLoggedDatesInRange(userId, startRange, endRange);
      if (!mounted) return;
    }

    setState(() {
      _userName = userName;
      _userEmail = userEmail;
      _userId = userId;
      _lastPeriodStart = lastPeriodStart;
      _firstPeriodStart = firstPeriodStart;
      _cycleDuration = cycleDuration;
      _periodDuration = periodDuration;
      _effectiveCycleDuration = effectiveDuration;
      _allPeriodStarts = allPeriodStarts;
      _loggedDates = loggedDates;
      _loadSelectedDayLog();
    });
  }

  Color _getPhaseColorForDay(DateTime date) {
    if (_lastPeriodStart == null) {
      return Colors.grey[300]!; // Color neutral si no hay registro
    }

    final phase = CycleService.instance.getPhaseForDate(
      date: date,
      lastPeriodStart: _lastPeriodStart!,
      effectiveCycleDuration: _effectiveCycleDuration,
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
    return Column(
      children: [
        // ●●●●●●●●●●●●●●
        // HEADER GLOBAL
        // ●●●●●●●●●●●●●●
        Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: _buildHeader(context),
        ),

        // ●●●●●●●●●●●●●●●●●●●●●●●●●●●●
        // ●●●●●●●●●●●●●●●●●●●●●●●●●●●●
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _buildViewSelectorRow(),
        ),
        SizedBox(height: 10),

        // LEYENDA
        if (_currentView != CalendarViewType.weekly)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _buildPhaseLegend(),
          ),

        // ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
        // CONTENIDO DEL CALENDARIO SCROLLABLE
        // ●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●●
        Expanded(
          child: _buildCalendarBody(),
        ),
      ],
    );
        },
    );
  }

  Widget _buildCalendarBody() {
    if (_currentView == CalendarViewType.annual && _annualDetailMonth != null) {
      return Column(
        children: [
          _buildAnnualDetailHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Column(
                children: [
                  _buildMonthlyCalendar(_annualDetailMonth!.year, _annualDetailMonth!.month),
                  if (_selectedDate != null) _buildSymptomsBox(),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      child: Column(
        children: [
          _buildCalendarContent(),
          if (_selectedDate != null && _currentView != CalendarViewType.annual)
            _buildSymptomsBox(),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  // HEADER Y CONTROLES
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Spacer(),
        BellotaTopActions(
          showSettings: false,
          showNotifications: false,
        ),
      ],
    );
  }

  Widget _buildViewSelectorRow() {
    String title = '';
    if (_currentView == CalendarViewType.annual && _annualDetailMonth == null) {
      title = '${_displayDate.year}';
    } else if (_currentView == CalendarViewType.monthly || _annualDetailMonth != null) {
      DateTime refDate = _annualDetailMonth ?? _displayDate;
      title = '${_monthNames[refDate.month - 1]} ${refDate.year}';
    } else {
      int weekday = _displayDate.weekday == 7 ? 0 : _displayDate.weekday;
      DateTime startOfWeek = _displayDate.subtract(Duration(days: weekday));
      DateTime endOfWeek = startOfWeek.add(Duration(days: 6));
      title = '${startOfWeek.day} - ${endOfWeek.day} ${_monthNames[startOfWeek.month - 1]} ${startOfWeek.year}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Theme.of(context).bellotaColors.textoDark,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildCustomDropdown(),
      ],
    );
  }

  Widget _buildCustomDropdown() {
    String currentLabel = _currentView == CalendarViewType.annual ? AppTranslations.get('calendar_views', 'year', languageNotifier.currentLang) :
    _currentView == CalendarViewType.monthly ? AppTranslations.get('calendar_views', 'month', languageNotifier.currentLang) : AppTranslations.get('calendar_views', 'week_short', languageNotifier.currentLang);

    return PopupMenuButton<CalendarViewType>(
      onSelected: (view) => setState(() {
        _currentView = view;
        _annualDetailMonth = null;
        _displayDate = _currentDate;
        _selectedDate = view != CalendarViewType.annual ? _currentDate : null;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: Offset(0, 40),
      itemBuilder: (context) => [
        PopupMenuItem(value: CalendarViewType.weekly, child: Text(AppTranslations.get('calendar_views', 'weekly_view', languageNotifier.currentLang))),
        PopupMenuItem(value: CalendarViewType.monthly, child: Text(AppTranslations.get('calendar_views', 'monthly_view', languageNotifier.currentLang))),
        PopupMenuItem(value: CalendarViewType.annual, child: Text(AppTranslations.get('calendar_views', 'yearly_view', languageNotifier.currentLang))),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).bellotaColors.chilero,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppTranslations.get('calendar_views', 'view', languageNotifier.currentLang), style: TextStyle(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.8), fontSize: 12)),
            SizedBox(width: 6),
            Container(width: 1, height: 12, color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.5)),
            SizedBox(width: 6),
            Text(currentLabel, style: TextStyle(color: Theme.of(context).bellotaColors.blanco, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // LEYENDA DE FASES
  Widget _buildPhaseLegend() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          _legendItem(Theme.of(context).bellotaColors.chilero, AppTranslations.get('cycle_phases', 'menstrual', languageNotifier.currentLang)),
          _legendItem(Theme.of(context).bellotaColors.chiltoma, AppTranslations.get('cycle_phases', 'follicular', languageNotifier.currentLang)),
          _legendItem(Theme.of(context).bellotaColors.melon, AppTranslations.get('cycle_phases', 'ovulatory', languageNotifier.currentLang)),
          _legendItem(Theme.of(context).bellotaColors.asuncion, AppTranslations.get('cycle_phases', 'luteal', languageNotifier.currentLang)),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).bellotaColors.textoMedio)),
      ],
    );
  }

  // DISTRIBUIDOR DE VISTAS
  Widget _buildCalendarContent() {
    switch (_currentView) {
      case CalendarViewType.weekly:
        return _buildWeeklyView();
      case CalendarViewType.monthly:
        return _buildMonthlySwipeable();
      case CalendarViewType.annual:
        return _buildAnnualView();
    }
  }

  Widget _buildWeeklyView() {
    int weekday = _displayDate.weekday == 7 ? 0 : _displayDate.weekday;
    DateTime startOfWeek = _displayDate.subtract(Duration(days: weekday));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildDaysHeader(),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              DateTime date = startOfWeek.add(Duration(days: index));
              return _buildDayCell(date);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySwipeable() {
    return SizedBox(
      height: 440,
      child: PageView.builder(
        controller: _monthPageController,
        onPageChanged: (index) {
          setState(() {
            int offset = index - _initialPage;
            // Actualiza el mes en pantalla sin perder la selección del día
            _displayDate = DateTime(_currentDate.year, _currentDate.month + offset, 1);
          });
        },
        itemBuilder: (context, index) {
          int offset = index - _initialPage;
          DateTime monthDate = DateTime(_currentDate.year, _currentDate.month + offset, 1);
          return _buildMonthlyCalendar(monthDate.year, monthDate.month);
        },
      ),
    );
  }

  Widget _buildMonthlyCalendar(int year, int month) {
    int daysInMonth = DateTime(year, month + 1, 0).day;
    int firstWeekday = DateTime(year, month, 1).weekday;
    int emptyDays = firstWeekday == 7 ? 0 : firstWeekday;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_currentView == CalendarViewType.annual && _annualDetailMonth == null) ...[
            Text(_monthNames[month - 1], style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).bellotaColors.chilero, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
          ],
          _buildDaysHeader(),
          SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + emptyDays,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.85,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < emptyDays) return SizedBox();
              DateTime date = DateTime(year, month, index - emptyDays + 1);
              return _buildDayCell(date);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnualView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: 24),
          child: _buildMonthlyCalendar(_displayDate.year, index + 1),
        );
      },
    );
  }

  Widget _buildAnnualDetailHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 20, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _annualDetailMonth = null;
            _selectedDate = null;
          }),
          icon: Icon(Icons.arrow_back_ios_rounded, size: 16, color: Theme.of(context).bellotaColors.chilero),
          label: Text(AppTranslations.get('calendar_views', 'back_to_year', languageNotifier.currentLang), style: TextStyle(color: Theme.of(context).bellotaColors.chilero, fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }

  // COMPONENTES DEL CALENDARIO
  Widget _buildDaysHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _dayNames.map((day) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2),
            padding: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: Theme.of(context).bellotaColors.chilero, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(
                day,
                style: TextStyle(color: Theme.of(context).bellotaColors.blanco, fontWeight: FontWeight.bold, fontSize: 10),
                maxLines: 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(DateTime date) {
    bool isSelected = _selectedDate != null &&
        date.year == _selectedDate!.year &&
        date.month == _selectedDate!.month &&
        date.day == _selectedDate!.day;

    Color phaseColor = _getPhaseColorForDay(date);
    String dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    bool hasLog = _loggedDates.contains(dateKey);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
          _loadSelectedDayLog();

          if (_currentView == CalendarViewType.annual && _annualDetailMonth == null) {
            _annualDetailMonth = DateTime(date.year, date.month, 1);
          } else if (_currentView == CalendarViewType.weekly) {
            _displayDate = date;
          }
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: _currentView == CalendarViewType.weekly ? EdgeInsets.symmetric(horizontal: 3) : EdgeInsets.zero,
        width: _currentView == CalendarViewType.weekly ? 40 : null,
        height: _currentView == CalendarViewType.weekly ? 60 : null,
        decoration: BoxDecoration(
          color: phaseColor.withValues(alpha: isSelected ? 1.0 : 0.6),
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: Theme.of(context).bellotaColors.textoDark, width: 1.5) : null,
          boxShadow: isSelected ? [BoxShadow(color: phaseColor.withValues(alpha: 0.5), blurRadius: 4, offset: Offset(0, 2))] : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.textoDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (hasLog)
              Positioned(
                bottom: _currentView == CalendarViewType.weekly ? 8 : 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.textoDark.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Traduce una clave de síntoma/flujo/sexo al idioma actual
  String _translateKey(String key) {
    final lang = languageNotifier.currentLang;
    // Intentar en registration_form primero (contiene la mayoría de claves)
    final translated = AppTranslations.get('registration_form', key, lang);
    // Si devuelve la misma key, intentar en symptoms
    if (translated == key) {
      return AppTranslations.get('symptoms', key, lang);
    }
    return translated;
  }

  // ———————————————————————————
  // CAJA DE SÍNTOMAS Y BELLOTAS
  // ———————————————————————————
  Widget _buildSymptomsBox() {
    if (_selectedDate == null) return SizedBox();
    final textTheme = Theme.of(context).textTheme;
    final lang = languageNotifier.currentLang;
    final _de = lang == 'en' ? '' : ' de ';
    String dateStr = lang == 'en'
        ? '${_dayNames[_selectedDate!.weekday == 7 ? 0 : _selectedDate!.weekday]}, ${_monthNames[_selectedDate!.month - 1]} ${_selectedDate!.day}, ${_selectedDate!.year}'
        : '${_dayNames[_selectedDate!.weekday == 7 ? 0 : _selectedDate!.weekday]}, ${_selectedDate!.day}$_de${_monthNames[_selectedDate!.month - 1]} ${_selectedDate!.year}';
    String dateKey = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final isFuture = _selectedDate!.isAfter(todayEnd);
    
    bool canRegister = !isFuture;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _selectedDayLogFuture,
      builder: (context, snapshot) {
        final log = snapshot.data;
        List<String> symptoms = [];
        List<String> sexo = [];
        List<String> flujo = [];
        bool periodStart = false;

        if (log != null) {
          try {
            symptoms = List<String>.from(jsonDecode(log['symptoms'] as String? ?? '[]'));
          } catch (_) {
            symptoms = [];
          }
          try {
            sexo = List<String>.from(jsonDecode(log['sexo'] as String? ?? '[]'));
          } catch (_) {
            sexo = [];
          }
          try {
            flujo = List<String>.from(jsonDecode(log['flujo'] as String? ?? '[]'));
          } catch (_) {
            flujo = [];
          }
          periodStart = (log['period_start'] as int?) == 1;
        }

        bool hasData = symptoms.isNotEmpty || sexo.isNotEmpty || flujo.isNotEmpty || periodStart;

        return Container(
          margin: EdgeInsets.fromLTRB(20, 24, 20, 0),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).bellotaColors.blanco,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr, style: textTheme.titleMedium?.copyWith(color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),

              // Botón de Registro
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canRegister ? () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SymptomLogScreen(selectedDate: _selectedDate),
                      ),
                    );
                    if (result == true) {
                      _loadInitialData(); // Recargar fechas importantes
                      setState(() {
                        _loadSelectedDayLog(); // Refrescar síntomas del día seleccionado
                      });
                    }
                  } : null,
                  child: Text(AppTranslations.get('symptoms_and_actions', 'log_symptoms', languageNotifier.currentLang), style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).bellotaColors.chilero,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              SizedBox(height: 16),

              if (!hasData)
                Text(
                  AppTranslations.get('symptoms_and_actions', 'no_entries_day', languageNotifier.currentLang),
                  style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).bellotaColors.textoMedio),
                ),

              if (periodStart)
                _buildSymptomItem(Theme.of(context).bellotaColors.chilero, AppTranslations.get('symptoms_and_actions', 'period_start', languageNotifier.currentLang)),
              ...symptoms.map((s) => _buildSymptomItem(Theme.of(context).bellotaColors.asuncion, _translateKey(s))),
              ...sexo.map((s) => _buildSymptomItem(Theme.of(context).bellotaColors.melon, _translateKey(s))),
              ...flujo.map((s) => _buildSymptomItem(Color(0xFFA566C1), _translateKey(s))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSymptomItem(Color color, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BellotaIcon(color: color, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}


