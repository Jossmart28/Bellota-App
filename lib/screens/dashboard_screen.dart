import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import '../database/database_helper.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'calendar_screen.dart';
import 'symptom_log_screen.dart';
import 'profile_screen.dart';
import '../widgets/health_info_carousel.dart';
import '../core/services/cycle_service.dart';
import '../core/services/notification_service.dart';

/// Dashboard principal de Bellota
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentPhaseIndex = 0;
  int _selectedNavIndex = 0;
  bool _periodoIniciado = false;
  String _userName = 'UsuarioApp';
  String _userEmail = 'correo@ejemplo.com';
  int? _userId;
  String? _profileImagePath;

  // Datos dinámicos para el dashboard
  List<String> _todaySymptoms = [];
  DateTime _nextPeriodDate = DateTime.now().add(Duration(days: 14));
  int _cycleDuration = 28;
  int _periodDuration = 5;
  CycleInfo? _cycleInfo;
  bool _hasPeriodsRegistered = true;

  // ── Definición de las 4 fases ──
  List<_PhaseData> _getPhases(String lang) {
    return [
      _PhaseData(
        name: '${AppTranslations.get('cycle_phases', 'phase', lang)}\n${AppTranslations.get('cycle_phases', 'ovulatory', lang)}',
        shortName: AppTranslations.get('cycle_phases', 'ovulatory', lang),
        color: BellotaColors.melon,
        borderColor: Color(0xFFD97A4A),
        symptomsTitle: 'Síntomas\nRegistrados',
        symptoms: [AppTranslations.get('symptoms', 'severe_pain', lang), 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
      ),
      _PhaseData(
        name: '${AppTranslations.get('cycle_phases', 'phase', lang)}\n${AppTranslations.get('cycle_phases', 'luteal', lang)}',
        shortName: AppTranslations.get('cycle_phases', 'luteal', lang),
        color: BellotaColors.asuncion,
        borderColor: Color(0xFF8FAFC8),
        symptomsTitle: 'Síntomas\nRegistrados',
        symptoms: [AppTranslations.get('symptoms', 'fatigue', lang), 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
      ),
      _PhaseData(
        name: '${AppTranslations.get('cycle_phases', 'phase', lang)}\n${AppTranslations.get('cycle_phases', 'follicular', lang)}',
        shortName: AppTranslations.get('cycle_phases', 'follicular', lang),
        color: BellotaColors.chiltoma,
        borderColor: Color(0xFF97B580),
        symptomsTitle: 'Síntomas\nRegistrados',
        symptoms: [AppTranslations.get('symptoms', 'high_energy', lang), 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
      ),
      _PhaseData(
        name: '${AppTranslations.get('cycle_phases', 'phase', lang)}\n${AppTranslations.get('cycle_phases', 'menstrual', lang)}',
        shortName: AppTranslations.get('cycle_phases', 'menstrual', lang),
        color: BellotaColors.chilero,
        borderColor: Color(0xFFD46A63),
        symptomsTitle: 'Síntomas\nRegistrados',
        symptoms: [AppTranslations.get('symptoms', 'cramps', lang), 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
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

    setState(() {
      _userName = userName;
      _userEmail = userEmail;
      _userId = userId;
    });

    if (userId != null) {
      await _loadDashboardData(userId);

      // Solicitar permiso de notificaciones (si no se ha dado) y programar recordatorios
      final hasPermission =
          await NotificationService.instance.hasPermission();
      if (!hasPermission) {
        await NotificationService.instance.requestPermission();
      }
      await NotificationService.instance.scheduleAllNotifications(userId);
    }
  }

  Future<void> _loadDashboardData(int userId) async {
    // 1. Cargar perfil para duración de ciclo y foto de perfil
    final profile = await DatabaseHelper.instance.getProfile(userId);
    if (profile != null) {
      _cycleDuration = profile['cycle_duration'] as int? ?? 28;
      _periodDuration = profile['period_duration'] as int? ?? 5;
      setState(() {
        _profileImagePath = profile['profile_image_path'] as String?;
      });
    }

    // 2. Obtener datos de períodos
    final now = DateTime.now();
    final lastPeriod = await DatabaseHelper.instance.getLastPeriodStart(userId);
    final allPeriodStarts = await DatabaseHelper.instance.getAllPeriodStartDates(userId);
    
    // 3. Calcular info del ciclo usando CycleService
    final cycleInfo = CycleService.instance.calculateCycleInfo(
      referenceDate: now,
      lastPeriodStart: lastPeriod,
      cycleDuration: _cycleDuration,
      periodDuration: _periodDuration,
      allPeriodStarts: allPeriodStarts.isNotEmpty ? allPeriodStarts : null,
    );

    // 4. Mapear fase a índice del array _phases
    int phaseIndex;
    switch (cycleInfo.phase) {
      case CyclePhase.ovulatory:
        phaseIndex = 0;
      case CyclePhase.luteal:
        phaseIndex = 1;
      case CyclePhase.follicular:
        phaseIndex = 2;
      case CyclePhase.menstrual:
        phaseIndex = 3;
    }

    // 5. Cargar síntomas registrados HOY
    String todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final log = await DatabaseHelper.instance.getDailyLog(userId, todayKey);

    List<String> combinedSymptoms = [];
    bool periodoIniciado = false;
    if (log != null) {
      periodoIniciado = (log['period_start'] as int?) == 1;
      List<String> s = List<String>.from(jsonDecode(log['symptoms'] as String? ?? '[]'));
      combinedSymptoms.addAll(s);
    }

    setState(() {
      _currentPhaseIndex = phaseIndex;
      _cycleInfo = cycleInfo;
      _hasPeriodsRegistered = cycleInfo.hasData;
      _nextPeriodDate = cycleInfo.nextPeriodDate;
      _todaySymptoms = combinedSymptoms;
      _periodoIniciado = periodoIniciado;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          backgroundColor: BellotaColors.basilica, // Fondo original correcto
          body: SafeArea(
            child: _getBody(context, lang),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _getBody(BuildContext context, String lang) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardContent(context, lang);
      case 1:
        return CalendarScreen();
      case 3:
        return MapScreen();
      case 4:
        return ProfileScreen();
      default:
        return Center(
          child: Text(
            AppTranslations.get('dashboard', 'coming_soon', languageNotifier.currentLang),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: BellotaColors.textoMedio),
          ),
        );
    }
  }

  Widget _buildDashboardContent(BuildContext context, String lang) {
    final phase = _getPhases(lang)[_currentPhaseIndex];
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            _buildHeader(context),
            SizedBox(height: 28),
            _buildSectionLabel(context, AppTranslations.get('dashboard', 'predictions', languageNotifier.currentLang)),
            SizedBox(height: 10),
            if (!_hasPeriodsRegistered)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BellotaColors.blanco,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: BellotaColors.melon.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 40, color: BellotaColors.textoMedio.withValues(alpha: 0.5)),
                    SizedBox(height: 12),
                    Text(
                      'Registra tu primer período para ver predicciones',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BellotaColors.textoMedio),
                    ),
                  ],
                ),
              ),
            if (_hasPeriodsRegistered)
              _buildPrediccionesCard(context),
            SizedBox(height: 28),
            _buildSectionLabel(context, AppTranslations.get('dashboard', 'todays_summary', languageNotifier.currentLang)),
            SizedBox(height: 10),
            _buildResumenCard(context, phase),
            SizedBox(height: 28),
            _buildSectionLabel(context, AppTranslations.get('dashboard', 'information_for_you', languageNotifier.currentLang)),
            SizedBox(height: 10),
            HealthInfoCarousel(),
            SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  /// Etiqueta de sección con línea decorativa suave al lado
  Widget _buildSectionLabel(BuildContext context, String title) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          title,
          style: textTheme.headlineMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BellotaColors.textoMedio.withValues(alpha: 0.25),
                  BellotaColors.textoMedio.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────
  // HEADER CON BOTONERA GLOBAL
  // ───────────────────────────
  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        GestureDetector(
          onLongPress: _logout,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BellotaColors.nancite,
              border: Border.all(color: BellotaColors.melon.withValues(alpha: 0.45), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: BellotaColors.melon.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: _profileImagePath != null && File(_profileImagePath!).existsSync()
                  ? Image.file(
                      File(_profileImagePath!),
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                    )
                  : Image.asset(
                      'assets/images/default_avatar.png',
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                    ),
            ),
          ),
        ),
        SizedBox(width: 12),

        // Nombre + email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: textTheme.titleMedium?.copyWith(
                  color: BellotaColors.textoDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 1),
              Text(
                _userEmail,
                style: textTheme.bodySmall?.copyWith(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        BellotaTopActions(
          showSettings: false,
          showNotifications: true,
          onTalkBackPressed: () {},
          onNotificationPressed: () {},
        ),
      ],
    );
  }



  // ──────────────
  // PREDICCIONES
  // ──────────────
  Widget _buildPrediccionesCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final List<String> monthNamesShort = [
      'Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.',
      'Jul.', 'Ago.', 'Sep.', 'Oct.', 'Nov.', 'Dic.'
    ];
    String dateStr = '${_nextPeriodDate.day}/${monthNamesShort[_nextPeriodDate.month - 1]}';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BellotaColors.blanco,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: BellotaColors.melon.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.get('symptoms_and_actions', 'next_period_will_be', languageNotifier.currentLang),
                  style: textTheme.bodySmall?.copyWith(height: 1.4),
                ),
                SizedBox(height: 8),
                Text(
                  dateStr,
                  style: textTheme.headlineLarge?.copyWith(
                    color: BellotaColors.chilero,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  AppTranslations.get('symptoms_and_actions', 'based_on_last_cycles', languageNotifier.currentLang),
                  style: textTheme.bodySmall?.copyWith(fontSize: 9.5, height: 1.3),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 72,
            margin: EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BellotaColors.textoMedio.withValues(alpha: 0.0),
                  BellotaColors.textoMedio.withValues(alpha: 0.2),
                  BellotaColors.textoMedio.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.get('symptoms_and_actions', 'expected_symptoms', languageNotifier.currentLang),
                  style: textTheme.bodySmall?.copyWith(
                    color: BellotaColors.textoDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                _bulletItem(context, AppTranslations.get('symptoms', 'mood_swings', languageNotifier.currentLang)),
                _bulletItem(context, AppTranslations.get('symptoms', 'sensitivity', languageNotifier.currentLang)),
                _bulletItem(context, AppTranslations.get('symptoms', 'fatigue', languageNotifier.currentLang)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulletItem(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: BellotaColors.melon.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────
  // RESUMEN DE HOY
  // ───────────────
  Widget _buildResumenCard(BuildContext context, _PhaseData phase) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BellotaColors.blanco,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: phase.color.withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: 0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: phase.color.withValues(alpha: 0.80),
              border: Border.all(
                color: phase.borderColor.withValues(alpha: 0.7),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: phase.color.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                phase.name,
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(fontSize: 12.5, height: 1.25),
              ),
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.get('symptoms_and_actions', 'logged_symptoms', languageNotifier.currentLang),
                  style: textTheme.titleMedium?.copyWith(
                    color: BellotaColors.textoDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                if (_todaySymptoms.isEmpty)
                  Text(
                    AppTranslations.get('symptoms_and_actions', 'no_symptoms_logged', languageNotifier.currentLang),
                    style: textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                if (_todaySymptoms.isNotEmpty)
                  ..._todaySymptoms.take(4).map((s) => _bulletItem(context, s)),
                if (_todaySymptoms.length > 4)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      '+${_todaySymptoms.length - 4} más',
                      style: textTheme.bodySmall?.copyWith(
                        color: BellotaColors.chilero,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────
  // INFORMACIÓN ADICIONAL
  // ──────────────────────
  Widget _buildInfoAdicionalCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: BellotaColors.blanco,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: BellotaColors.chiltoma.withValues(alpha: 0.10),
              blurRadius: 18,
              spreadRadius: 0,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: BellotaColors.nancite,
              ),
              child: Center(
                child: Icon(
                  Icons.article_outlined,
                  size: 38,
                  color: BellotaColors.melon,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cómo afecta el estrés tu ciclo?',
                    style: textTheme.titleMedium?.copyWith(
                      color: BellotaColors.textoDark,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'El estrés crónico puede alterar tus niveles hormonales, provocando retrasos en tu periodo o cambios en la ovulación.',
                    style: textTheme.bodySmall?.copyWith(fontSize: 10.5, height: 1.5),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ───────────────────────
  // BOTTOM NAVIGATION BAR
  // ───────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BellotaColors.blanco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: BellotaColors.melon.withValues(alpha: 0.09),
            blurRadius: 24,
            spreadRadius: 0,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, Icons.home_filled, AppTranslations.get('navigation', 'home', languageNotifier.currentLang), 0),
              _navItem(context, Icons.calendar_month_rounded, AppTranslations.get('navigation', 'calendar', languageNotifier.currentLang), 1),
              _navItem(context, Icons.article_outlined, AppTranslations.get('navigation', 'log', languageNotifier.currentLang), 2),
              _navItem(context, Icons.location_on_outlined, AppTranslations.get('navigation', 'map', languageNotifier.currentLang), 3),
              _navItem(context, Icons.person_outline_rounded, languageNotifier.currentLang == 'mi' ? '' : AppTranslations.get('navigation', 'profile', languageNotifier.currentLang), 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () async {
        if (index == 2) {
          // Open the register screen directly for today
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SymptomLogScreen(),
            ),
          );
          if (result == true) {
            _loadUser(); // Refresh dashboard data
          }
        } else {
          setState(() => _selectedNavIndex = index);
          if (index == 0) {
            // Recargar datos si volvemos a Inicio (por si cambió la foto u otra cosa en Perfil)
            _loadUser();
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? BellotaColors.chilero.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? BellotaColors.chilero : BellotaColors.textoMedio,
            ),
            if (label.isNotEmpty) ...[
              SizedBox(height: 3),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? BellotaColors.chilero : BellotaColors.textoMedio,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────
// Modelo de datos de fase
// ─────────────────────────
class _PhaseData {
  final String name;
  final String shortName;
  final Color color;
  final Color borderColor;
  final String symptomsTitle;
  final List<String> symptoms;

  _PhaseData({
    required this.name,
    required this.shortName,
    required this.color,
    required this.borderColor,
    required this.symptomsTitle,
    required this.symptoms,
  });
}