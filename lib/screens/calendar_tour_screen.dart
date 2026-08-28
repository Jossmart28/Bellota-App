import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../database/database_helper.dart';
import '../widgets/bellota_icon.dart';
import 'personal_data_screen.dart';

/// Full-screen calendar tour that overlays a tutorial on top of the calendar.
/// Guides the user to mark the start of their last period.
class CalendarTourScreen extends StatefulWidget {
  const CalendarTourScreen({super.key});

  @override
  State<CalendarTourScreen> createState() => _CalendarTourScreenState();
}

class _CalendarTourScreenState extends State<CalendarTourScreen>
    with TickerProviderStateMixin {
  int _tourStep = 0; // 0 = overlay tip, 1 = calendar selection active
  DateTime _displayDate = DateTime.now();
  DateTime? _selectedPeriodStart;
  int? _userId;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _overlayFadeController;
  late Animation<double> _overlayFadeAnim;

  final List<String> _dayNames = ['DOM', 'LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB'];
  final List<String> _monthNames = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _overlayFadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
      value: 1.0,
    );
    _overlayFadeAnim = CurvedAnimation(
      parent: _overlayFadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _overlayFadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    int? uid = prefs.getInt('userId');
    String email = prefs.getString('userEmail') ?? '';
    if (uid == null && email.isNotEmpty) {
      uid = await DatabaseHelper.instance.getUserIdByEmail(email);
      if (uid != null) await prefs.setInt('userId', uid);
    }
    setState(() => _userId = uid);
  }

  Future<void> _confirmPeriodStart() async {
    if (_selectedPeriodStart == null) return;

    if (_userId != null) {
      String dateKey =
          '${_selectedPeriodStart!.year}-${_selectedPeriodStart!.month.toString().padLeft(2, '0')}-${_selectedPeriodStart!.day.toString().padLeft(2, '0')}';
      await DatabaseHelper.instance.saveDailyLog(
        userId: _userId!,
        date: dateKey,
        periodStart: true,
        symptoms: [],
        sexo: [],
        flujo: [],
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_tour_done', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => PersonalDataScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _dismissOverlay() {
    _overlayFadeController.reverse().then((_) {
      setState(() => _tourStep = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BellotaColors.basilica,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main Calendar Content ──
            Positioned.fill(
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 8),
                  _buildCalendar(),
                  SizedBox(height: 16),
                  if (_tourStep == 1) _buildSelectionPanel(),
                ],
              ),
            ),

            // ── Tour Overlay (Step 0) ──
            if (_tourStep == 0)
              FadeTransition(
                opacity: _overlayFadeAnim,
                child: _buildTourOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          BellotaIcon(color: BellotaColors.chilero, size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthNames[_displayDate.month - 1]} ${_displayDate.year}',
                  style: TextStyle(
                    color: BellotaColors.textoDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _tourStep == 0 ? AppTranslations.get('onboarding', 'lets_start', languageNotifier.currentLang) : AppTranslations.get('onboarding', 'tap_start_day', languageNotifier.currentLang),
                  style: TextStyle(
                    color: BellotaColors.textoMedio.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Prev/Next month arrows
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: BellotaColors.chilero),
                onPressed: () => setState(() {
                  _displayDate = DateTime(_displayDate.year, _displayDate.month - 1, 1);
                }),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: BellotaColors.chilero),
                onPressed: () => setState(() {
                  _displayDate = DateTime(_displayDate.year, _displayDate.month + 1, 1);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    int year = _displayDate.year;
    int month = _displayDate.month;
    int daysInMonth = DateTime(year, month + 1, 0).day;
    int firstWeekday = DateTime(year, month, 1).weekday;
    int emptyDays = firstWeekday == 7 ? 0 : firstWeekday;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _dayNames.map((d) => Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2),
                padding: EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: BellotaColors.chilero,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(d,
                    style: TextStyle(color: BellotaColors.blanco, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ),
            )).toList(),
          ),
          SizedBox(height: 8),
          // Day grid
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
              final date = DateTime(year, month, index - emptyDays + 1);
              final isSelected = _selectedPeriodStart != null &&
                  date.year == _selectedPeriodStart!.year &&
                  date.month == _selectedPeriodStart!.month &&
                  date.day == _selectedPeriodStart!.day;
              final isFuture = date.isAfter(DateTime.now());

              return GestureDetector(
                onTap: !isFuture
                    ? () {
                        if (_tourStep == 0) {
                          _dismissOverlay();
                        }
                        setState(() {
                          if (isSelected) {
                            _selectedPeriodStart = null;
                          } else {
                            _selectedPeriodStart = date;
                          }
                        });
                      }
                    : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isFuture
                        ? Colors.grey[200]
                        : (isSelected ? BellotaColors.chilero : BellotaColors.blanco),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? BellotaColors.chilero : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: BellotaColors.chilero.withValues(alpha: 0.4), blurRadius: 4)]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isFuture ? Colors.grey[400] : (isSelected ? BellotaColors.blanco : BellotaColors.textoDark),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionPanel() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedPeriodStart != null)
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: BellotaColors.chilero.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BellotaColors.chilero.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Column(
                  children: [
                    BellotaIcon(color: BellotaColors.chilero, size: 32),
                    SizedBox(height: 10),
                    Text(
                      '${_dayNames[_selectedPeriodStart!.weekday == 7 ? 0 : _selectedPeriodStart!.weekday]}, ${_selectedPeriodStart!.day} de ${_monthNames[_selectedPeriodStart!.month - 1]}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: BellotaColors.textoDark,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AppTranslations.get('symptoms_and_actions', 'last_period_start', languageNotifier.currentLang),
                      style: TextStyle(
                        color: BellotaColors.textoMedio.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 16),
          // Confirm button
          AnimatedOpacity(
            opacity: _selectedPeriodStart != null ? 1.0 : 0.0,
            duration: Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: _selectedPeriodStart == null,
              child: ElevatedButton(
                onPressed: _selectedPeriodStart != null ? _confirmPeriodStart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BellotaColors.chilero,
                  foregroundColor: BellotaColors.blanco,
                  padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                ),
                child: Text(AppTranslations.get('onboarding', 'confirm', languageNotifier.currentLang), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
          SizedBox(height: 16),
          // Prompt text
          Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text(
              'Toca el día en que comenzó\ntu último período',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: BellotaColors.textoMedio,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourOverlay() {
    return Container(
      color: BellotaColors.textoDark.withValues(alpha: 0.72),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated bellota
              ScaleTransition(
                scale: _pulseAnim,
                child: BellotaIcon(color: BellotaColors.nancite, size: 64),
              ),
              SizedBox(height: 32),
              Text(
                AppTranslations.get('onboarding', 'welcome', languageNotifier.currentLang),
                style: TextStyle(
                  color: BellotaColors.blanco,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Para comenzar, necesitamos saber cuándo fue el primer día de tu último período.\n\nToca un día en el calendario para marcarlo.',
                style: TextStyle(
                  color: BellotaColors.blanco.withValues(alpha: 0.85),
                  fontSize: 15,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              // Arrow pointing down
              Column(
                children: [
                  Icon(Icons.arrow_downward_rounded,
                      color: BellotaColors.nancite.withValues(alpha: 0.8), size: 28),
                  SizedBox(height: 4),
                  Text(
                    AppTranslations.get('onboarding', 'calendar_is_below', languageNotifier.currentLang),
                    style: TextStyle(
                      color: BellotaColors.nancite.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _dismissOverlay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BellotaColors.chilero,
                    foregroundColor: BellotaColors.blanco,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 6,
                  ),
                  child: Text(
                    AppTranslations.get('onboarding', 'got_it_lets_go', languageNotifier.currentLang),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
