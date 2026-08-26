import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import '../widgets/bellota_icon.dart';
import '../database/database_helper.dart';
import 'symptom_log_screen.dart';

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

  CalendarViewType _currentView = CalendarViewType.monthly;
  final DateTime _currentDate = DateTime.now(); // Fecha real actual
  DateTime _displayDate = DateTime.now(); // Fecha del mes/semana que se está viendo
  DateTime? _selectedDate; // Día seleccionado por la usuaria

  // Controlador para el scroll en la vista de mes
  late PageController _monthPageController;
  final int _initialPage = 1200;

  // Estado para la Subventana de la vista anual
  DateTime? _annualDetailMonth;

  final List<String> _dayNames = ['DOM', 'LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB'];
  final List<String> _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _monthPageController = PageController(initialPage: _initialPage);
    _selectedDate = _currentDate;
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    String userName = prefs.getString('userName') ?? 'UsuarioApp';
    String userEmail = prefs.getString('userEmail') ?? 'correo@ejemplo.com';
    int? userId = prefs.getInt('userId');

    if (userId == null && userEmail != 'correo@ejemplo.com') {
      userId = await DatabaseHelper.instance.getUserIdByEmail(userEmail);
      if (userId != null) {
        await prefs.setInt('userId', userId);
      }
    }

    DateTime? lastPeriodStart;
    DateTime? firstPeriodStart;
    if (userId != null) {
      lastPeriodStart = await DatabaseHelper.instance.getLastPeriodStart(userId);
      firstPeriodStart = await DatabaseHelper.instance.getFirstPeriodStart(userId);
    }

    setState(() {
      _userName = userName;
      _userEmail = userEmail;
      _userId = userId;
      _lastPeriodStart = lastPeriodStart;
      _firstPeriodStart = firstPeriodStart;
    });
  }

  // ──────────────────────────────────────────
  // LÓGICA SIMULADA DE FASES (Ciclo 28 días)
  // ──────────────────────────────────────────
  Color _getPhaseColorForDay(DateTime date) {
    if (_lastPeriodStart == null) {
      return Colors.grey[300]!; // Color neutral si no hay registro
    }

    // Calcula la diferencia de días
    final diff = date.difference(_lastPeriodStart!).inDays;
    
    // Extrapolamos hacia atrás y hacia adelante (diff puede ser negativo)
    final cycleDay = (diff % 28) + 1;

    if (cycleDay <= 5) return BellotaColors.chilero; // Menstrual
    if (cycleDay <= 13) return BellotaColors.chiltoma; // Folicular
    if (cycleDay <= 16) return BellotaColors.melon; // Ovulatoria
    return BellotaColors.asuncion; // Lútea
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ══════════════
        // HEADER GLOBAL
        // ══════════════
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          child: _buildHeader(context),
        ),

        // ════════════════════════════
        // CONTROLES DE VISTA Y TÍTULO
        // ════════════════════════════
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildViewSelectorRow(),
        ),
        const SizedBox(height: 10),

        // LEYENDA
        if (_currentView != CalendarViewType.weekly)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildPhaseLegend(),
          ),

        // ═════════════════════════════════════
        // CONTENIDO DEL CALENDARIO SCROLLABLE
        // ═════════════════════════════════════
        Expanded(
          child: _buildCalendarBody(),
        ),
      ],
    );
  }

  Widget _buildCalendarBody() {
    if (_currentView == CalendarViewType.annual && _annualDetailMonth != null) {
      return Column(
        children: [
          _buildAnnualDetailHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  _buildMonthlyCalendar(_annualDetailMonth!.year, _annualDetailMonth!.month),
                  if (_selectedDate != null) _buildSymptomsBox(),
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
          _buildCalendarContent(),
          if (_selectedDate != null && _currentView != CalendarViewType.annual)
            _buildSymptomsBox(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ───────────────────
  // HEADER Y CONTROLES
  // ───────────────────
  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BellotaColors.nancite,
            border: Border.all(color: BellotaColors.textoMedio.withValues(alpha: 0.3), width: 2),
          ),
          child: const Icon(Icons.person, color: BellotaColors.textoMedio, size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_userName, style: textTheme.titleMedium?.copyWith(color: BellotaColors.textoDark, fontWeight: FontWeight.w700)),
              Text(_userEmail, style: textTheme.bodySmall, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const BellotaTopActions(
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
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      title = '${startOfWeek.day} - ${endOfWeek.day} ${_monthNames[startOfWeek.month - 1]} ${startOfWeek.year}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: BellotaColors.textoDark,
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
    String currentLabel = _currentView == CalendarViewType.annual ? 'Año' :
    _currentView == CalendarViewType.monthly ? 'Mes' : 'Sem.';

    return PopupMenuButton<CalendarViewType>(
      onSelected: (view) => setState(() {
        _currentView = view;
        _annualDetailMonth = null;
        _displayDate = _currentDate;
        _selectedDate = view != CalendarViewType.annual ? _currentDate : null;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 40),
      itemBuilder: (context) => const [
        PopupMenuItem(value: CalendarViewType.weekly, child: Text('Vista Semanal')),
        PopupMenuItem(value: CalendarViewType.monthly, child: Text('Vista Mensual')),
        PopupMenuItem(value: CalendarViewType.annual, child: Text('Vista Anual')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: BellotaColors.chilero,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vista', style: TextStyle(color: BellotaColors.blanco.withValues(alpha: 0.8), fontSize: 12)),
            const SizedBox(width: 6),
            Container(width: 1, height: 12, color: BellotaColors.blanco.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(currentLabel, style: const TextStyle(color: BellotaColors.blanco, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ─────────────────
  // LEYENDA DE FASES
  // ─────────────────
  Widget _buildPhaseLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          _legendItem(BellotaColors.chilero, 'Menstrual'),
          _legendItem(BellotaColors.chiltoma, 'Folicular'),
          _legendItem(BellotaColors.melon, 'Ovulatoria'),
          _legendItem(BellotaColors.asuncion, 'Lútea'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: BellotaColors.textoMedio)),
      ],
    );
  }

  // ────────────────────────
  // DISTRIBUIDOR DE VISTAS
  // ────────────────────────
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

  // ── VISTA SEMANAL ──
  Widget _buildWeeklyView() {
    int weekday = _displayDate.weekday == 7 ? 0 : _displayDate.weekday;
    DateTime startOfWeek = _displayDate.subtract(Duration(days: weekday));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildDaysHeader(),
          const SizedBox(height: 8),
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

// ── VISTA MENSUAL (SWIPEABLE) ──
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_currentView == CalendarViewType.annual && _annualDetailMonth == null) ...[
            Text(_monthNames[month - 1], style: Theme.of(context).textTheme.titleMedium?.copyWith(color: BellotaColors.chilero, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ],
          _buildDaysHeader(),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth + emptyDays,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.85,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < emptyDays) return const SizedBox();
              DateTime date = DateTime(year, month, index - emptyDays + 1);
              return _buildDayCell(date);
            },
          ),
        ],
      ),
    );
  }

  // ── VISTA ANUAL ──
  Widget _buildAnnualView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: _buildMonthlyCalendar(_displayDate.year, index + 1),
        );
      },
    );
  }

  Widget _buildAnnualDetailHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _annualDetailMonth = null;
            _selectedDate = null;
          }),
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: BellotaColors.chilero),
          label: const Text('Volver al Año', style: TextStyle(color: BellotaColors.chilero, fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: BellotaColors.chilero.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────
  // COMPONENTES DEL CALENDARIO
  // ───────────────────────────
  Widget _buildDaysHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _dayNames.map((day) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: BellotaColors.chilero, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(
                day,
                style: const TextStyle(color: BellotaColors.blanco, fontWeight: FontWeight.bold, fontSize: 10),
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

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;

          if (_currentView == CalendarViewType.annual && _annualDetailMonth == null) {
            _annualDetailMonth = DateTime(date.year, date.month, 1);
          } else if (_currentView == CalendarViewType.weekly) {
            _displayDate = date;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: _currentView == CalendarViewType.weekly ? const EdgeInsets.symmetric(horizontal: 3) : EdgeInsets.zero,
        width: _currentView == CalendarViewType.weekly ? 40 : null,
        height: _currentView == CalendarViewType.weekly ? 60 : null,
        decoration: BoxDecoration(
          color: phaseColor.withValues(alpha: isSelected ? 1.0 : 0.6),
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: BellotaColors.textoDark, width: 1.5) : null,
          boxShadow: isSelected ? [BoxShadow(color: phaseColor.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 2))] : [],
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              color: isSelected ? BellotaColors.blanco : BellotaColors.textoDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────
  // CAJA DE SÍNTOMAS Y BELLOTAS
  // ───────────────────────────
  Widget _buildSymptomsBox() {
    if (_selectedDate == null) return const SizedBox();
    final textTheme = Theme.of(context).textTheme;
    String dateStr = '${_dayNames[_selectedDate!.weekday == 7 ? 0 : _selectedDate!.weekday]}, ${_selectedDate!.day} de ${_monthNames[_selectedDate!.month - 1]} ${_selectedDate!.year}';
    String dateKey = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final isFuture = _selectedDate!.isAfter(todayEnd);
    
    bool isBeforeFirstPeriod = false;
    if (_firstPeriodStart != null) {
      final firstStart = DateTime(_firstPeriodStart!.year, _firstPeriodStart!.month, _firstPeriodStart!.day);
      final selected = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      isBeforeFirstPeriod = selected.isBefore(firstStart);
    }

    bool canRegister = !isFuture && !isBeforeFirstPeriod;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _userId != null ? DatabaseHelper.instance.getDailyLog(_userId!, dateKey) : Future.value(null),
      builder: (context, snapshot) {
        final log = snapshot.data;
        List<String> symptoms = [];
        List<String> sexo = [];
        List<String> flujo = [];
        bool periodStart = false;

        if (log != null) {
          symptoms = List<String>.from(jsonDecode(log['symptoms'] as String? ?? '[]'));
          sexo = List<String>.from(jsonDecode(log['sexo'] as String? ?? '[]'));
          flujo = List<String>.from(jsonDecode(log['flujo'] as String? ?? '[]'));
          periodStart = (log['period_start'] as int?) == 1;
        }

        bool hasData = symptoms.isNotEmpty || sexo.isNotEmpty || flujo.isNotEmpty || periodStart;

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BellotaColors.blanco,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dateStr, style: textTheme.titleMedium?.copyWith(color: BellotaColors.textoDark, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Botón de Registro
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canRegister ? () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SymptomLogScreen(selectedDate: _selectedDate),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                         _loadUser(); // Recargar fechas importantes por si cambió el inicio de periodo
                      });
                    }
                  } : null,
                  icon: const Text('🌰', style: TextStyle(fontSize: 18)),
                  label: const Text('Registrar síntomas', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BellotaColors.chilero,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Lorem ipsum', style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),

              if (!hasData)
                Text(
                  'No hay registros para este día.\nPresiona el botón para agregar.',
                  style: textTheme.bodyMedium?.copyWith(color: BellotaColors.textoMedio),
                ),

              if (periodStart)
                _buildSymptomItem(BellotaColors.chilero, 'Inicio del período'),
              ...symptoms.map((s) => _buildSymptomItem(BellotaColors.asuncion, s)),
              ...sexo.map((s) => _buildSymptomItem(BellotaColors.melon, s)),
              ...flujo.map((s) => _buildSymptomItem(const Color(0xFFA566C1), s)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSymptomItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BellotaIcon(color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}