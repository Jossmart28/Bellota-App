import '../core/constants/app_keys.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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
import '../widgets/cozy_section_header.dart';
import '../widgets/cozy_card.dart';
import 'resumen_diario_screen.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

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
  bool _profileImageExists = false;
  late List<Widget> _screens;

  // Datos din�micos para el dashboard
  List<String> _todaySymptoms = [];
  DateTime _nextPeriodDate = DateTime.now().add(Duration(days: 14));
  int _cycleDuration = 28;
  int _periodDuration = 5;
  CycleInfo? _cycleInfo;
  bool _hasPeriodsRegistered = true;

  List<String> _predictedSymptoms = ['mood_swings', 'sensitivity', 'fatigue'];
  String? _todayMood;
  List<String> _medicalConditions = [];

  // ── Definición de las 4 fases ──
  List<_PhaseData> _getPhases(String lang) {
    return [
      _PhaseData(
        name: '${AppLocalizations.of(context)!.cyclePhasesPhase}\n${AppLocalizations.of(context)!.cyclePhasesOvulatory}',
        shortName: AppLocalizations.of(context)!.cyclePhasesOvulatory,
        color: Theme.of(context).bellotaColors.melon,
        borderColor: Color(0xFFD97A4A),
        symptomsTitle: 'Síntomas\nRegistrados',
        symptoms: [AppLocalizations.of(context)!.symptomsSeverePain],
      ),
      _PhaseData(
        name: '${AppLocalizations.of(context)!.cyclePhasesPhase}\n${AppLocalizations.of(context)!.cyclePhasesLuteal}',
        shortName: AppLocalizations.of(context)!.cyclePhasesLuteal,
        color: Theme.of(context).bellotaColors.asuncion,
        borderColor: Color(0xFF8FAFC8),
        symptomsTitle: 'Síntomas\nRegistrados',
        symptoms: [AppLocalizations.of(context)!.symptomsFatigue],
      ),
      _PhaseData(
        name: '${AppLocalizations.of(context)!.cyclePhasesPhase}\n${AppLocalizations.of(context)!.cyclePhasesFollicular}',
        shortName: AppLocalizations.of(context)!.cyclePhasesFollicular,
        color: Theme.of(context).bellotaColors.chiltoma,
        borderColor: Color(0xFF97B580),
        symptomsTitle: 'Síntomas\nRegistrados',
        symptoms: [AppLocalizations.of(context)!.symptomsHighEnergy],
      ),
      _PhaseData(
        name: '${AppLocalizations.of(context)!.cyclePhasesPhase}\n${AppLocalizations.of(context)!.cyclePhasesMenstrual}',
        shortName: AppLocalizations.of(context)!.cyclePhasesMenstrual,
        color: Theme.of(context).bellotaColors.chilero,
        borderColor: Color(0xFFD46A63),
        symptomsTitle: 'Síntomas\nRegistrados',
        symptoms: [AppLocalizations.of(context)!.symptomsCramps],
      ),
    ];
  }

  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    String userName = prefs.getString(AppKeys.userName) ?? 'UsuarioApp';
    String userEmail = prefs.getString(AppKeys.userEmail) ?? 'correo@ejemplo.com';
    int? userId = prefs.getInt(AppKeys.userId);

    if (userId == null && userEmail != 'correo@ejemplo.com') {
      userId = await DatabaseHelper.instance.getUserIdByEmail(userEmail);
      if (userId != null) {
        await prefs.setInt(AppKeys.userId, userId);
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
    // 1. Cargar perfil para duración de ciclo, foto y condiciones médicas
    final profile = await DatabaseHelper.instance.getProfile(userId);
    List<String> medicalConds = [];
    if (profile != null) {
      _cycleDuration = profile['cycle_duration'] as int? ?? 28;
      _periodDuration = profile['period_duration'] as int? ?? 5;
      
      if (profile['medical_conditions'] != null) {
        try {
          medicalConds = List<String>.from(jsonDecode(profile['medical_conditions'].toString()));
        } catch (_) {}
      }

      setState(() {
        if (profile['username'] != null && profile['username'].toString().isNotEmpty) {
          _userName = profile['username'].toString();
        }
        _profileImagePath = profile['profile_image_path'] as String?;
        _profileImageExists = _profileImagePath != null && File(_profileImagePath!).existsSync();
        _medicalConditions = medicalConds;
      });
    }

    // 2. Obtener datos de períodos y fertilidad
    final now = DateTime.now();
    final lastPeriod = await DatabaseHelper.instance.getLastPeriodStart(userId);
    final allPeriodStarts = await DatabaseHelper.instance.getAllPeriodStartDates(userId);
    
    // Asumiremos que tenemos una función en DatabaseHelper para obtener datos de fertilidad del ciclo actual, 
    // pero por simplicidad pasaremos null si no la tenemos a mano (se requiere query adicional)
    
    // 3. Calcular info del ciclo usando CycleService
    final cycleInfo = CycleService.instance.calculateCycleInfo(
      referenceDate: now,
      lastPeriodStart: lastPeriod,
      cycleDuration: _cycleDuration,
      periodDuration: _periodDuration,
      allPeriodStarts: allPeriodStarts.isNotEmpty ? allPeriodStarts : null,
      medicalConditions: medicalConds.isNotEmpty ? medicalConds : null,
      fertilityData: null, // Idealmente cargaríamos los daily_logs del ciclo actual aquí
    );

    // 4. Mapear fase a índice del array _phases
    int phaseIndex;
    String phaseNameStr = '';
    switch (cycleInfo.phase) {
      case CyclePhase.ovulatory:
        phaseIndex = 0;
        phaseNameStr = 'ovulatory';
      case CyclePhase.luteal:
        phaseIndex = 1;
        phaseNameStr = 'luteal';
      case CyclePhase.follicular:
        phaseIndex = 2;
        phaseNameStr = 'follicular';
      case CyclePhase.menstrual:
        phaseIndex = 3;
        phaseNameStr = 'menstrual';
    }

    // 5. Cargar predicciones inteligentes de síntomas
    final topSymptoms = await DatabaseHelper.instance.getTopSymptomsForPhase(userId, phaseNameStr);
    List<String> predictedSymptoms = topSymptoms.isNotEmpty ? topSymptoms : ['mood_swings', 'sensitivity', 'fatigue'];

    // 6. Cargar síntomas registrados HOY y estado de ánimo
    String todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final log = await DatabaseHelper.instance.getDailyLog(userId, todayKey);

    List<String> combinedSymptoms = [];
    bool periodoIniciado = false;
    String? todayMood;
    
    if (log != null) {
      periodoIniciado = (log['period_start'] as int?) == 1;
      List<String> s = List<String>.from(jsonDecode(log['symptoms'] as String? ?? '[]'));
      combinedSymptoms.addAll(s);
      todayMood = log['mood'] as String?;
    }

    setState(() {
      _currentPhaseIndex = phaseIndex;
      _cycleInfo = cycleInfo;
      _hasPeriodsRegistered = cycleInfo.hasData;
      _nextPeriodDate = cycleInfo.nextPeriodDate;
      _todaySymptoms = combinedSymptoms;
      _periodoIniciado = periodoIniciado;
      _predictedSymptoms = predictedSymptoms;
      _todayMood = todayMood;
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
          backgroundColor: Theme.of(context).bellotaColors.basilica, // Fondo original correcto
          body: SafeArea(
            child: _getBody(context, lang),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _getBody(BuildContext context, String lang) {
    return IndexedStack(
      index: _selectedNavIndex,
      children: [
        Builder(builder: (context) => _buildDashboardContent(context, lang)),
        const CalendarScreen(),
        const SizedBox(), // Placeholder for symptom log
        const MapScreen(),
        const ProfileScreen(),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context, String lang) {
    return Stack(
      children: [
        // ── Decoración: marca de agua floral en esquina superior derecha ──
        Positioned(
          top: -10,
          right: -20,
          child: Opacity(
            opacity: 0.08,
            child: SvgPicture.asset(
              'assets/decorations/dashboard_bg_deco.svg',
              width: 250,
              height: 250,
              colorFilter: ColorFilter.mode(Theme.of(context).bellotaColors.textoDark, BlendMode.srcIn),
            ),
          ),
        ),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildHeader(context),
                const SizedBox(height: 28),

                // ── Botón de acceso al Resumen Diario ──
                _buildResumenDiarioBanner(context),

                const SizedBox(height: 28),
                CozySectionHeader(
                  title: AppLocalizations.of(context)!.dashboardTodaysSummary,
                ),
                const SizedBox(height: 10),
                _buildResumenCard(context, _getPhases(languageNotifier.currentLang)[_currentPhaseIndex]),

                const SizedBox(height: 28),
                CozySectionHeader(
                  title: AppLocalizations.of(context)!.dashboardInformationForYou,
                ),
                const SizedBox(height: 10),
                const HealthInfoCarousel(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }



  // ───────────────────────────────────────────────
  // BANNER / BOTÓN — Acceso a Resumen Diario
  // ───────────────────────────────────────────────
  Widget _buildResumenDiarioBanner(BuildContext context) {
    final phase = _getPhases(languageNotifier.currentLang)[_currentPhaseIndex];
    final List<String> monthNamesShort = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final String dateStr = '${_nextPeriodDate.day} ${monthNamesShort[_nextPeriodDate.month - 1]}';
    final daysUntil = _nextPeriodDate.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResumenDiarioScreen(
              nextPeriodDate: _nextPeriodDate,
              predictedSymptoms: _predictedSymptoms,
              todaySymptoms: _todaySymptoms,
              todayMood: _todayMood,
              medicalConditions: _medicalConditions,
              cycleInfo: _cycleInfo,
              currentPhaseIndex: _currentPhaseIndex,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              phase.color.withValues(alpha: 0.85),
              phase.borderColor.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: phase.color.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Patron decorativo de fondo
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Opacity(
                  opacity: 0.10,
                  child: Image.asset(
                    'assets/decorations/dashboard_bg_deco.svg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Imagen decorativa con fade suave hacia la derecha (no centrada)
            Positioned(
              right: -10,
              top: -10,
              bottom: -10,
              width: 155,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                      ],
                      stops: [0.0, 0.35],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Opacity(
                    opacity: 0.88,
                    child: Image.asset(
                      'assets/images/resumen_banner.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topRight,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 115, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Resumen Diario",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_hasPeriodsRegistered) ...[
                    Text(
                      "Próximo período: $dateStr",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysUntil <= 0
                          ? "Puede estar comenzando hoy"
                          : "En $daysUntil ${daysUntil == 1 ? 'día' : 'días'}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${_predictedSymptoms.length} síntomas esperados",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      "Registra tu primer período para ver predicciones",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Flecha de navegación flotante con cápsula translúcida
            Positioned(
              bottom: 14,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Ver detalle",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
              color: Theme.of(context).bellotaColors.nancite,
              border: Border.all(color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.45), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: _profileImageExists
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
                  color: Theme.of(context).bellotaColors.textoDark,
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

    return CozyCard(
      padding: const EdgeInsets.all(20),
      shadowColor: Theme.of(context).bellotaColors.melon,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.symptomsAndActionsNextPeriodWillBe,
                  style: textTheme.bodySmall?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).bellotaColors.chilero,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppLocalizations.of(context)!.symptomsAndActionsBasedOnLastCycles,
                  style: textTheme.bodySmall?.copyWith(fontSize: 9.5, height: 1.3),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.0),
                  Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.2),
                  Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.0),
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
                  AppLocalizations.of(context)!.symptomsAndActionsExpectedSymptoms,
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).bellotaColors.textoDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                if (_medicalConditions.contains('pcos')) ...[
                  Text(
                    '⚠️ Predicciones pueden variar por PCOS',
                    style: TextStyle(fontSize: 10, color: Theme.of(context).bellotaColors.melon),
                  ),
                  const SizedBox(height: 4),
                ],
                ..._predictedSymptoms.map((s) => _bulletItem(context, _translateSymptomKey(s))),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// Traduce una clave de síntoma al idioma actual
  String _translateSymptomKey(String key) {
    final lang = languageNotifier.currentLang;
    // Buscar en registration_form (donde están fever, headache, etc.)
    final categories = ['registration_form', 'symptoms_and_actions', 'symptoms'];
    for (final cat in categories) {
      final val = AppTranslations.get(cat, key, lang, context: context);
      if (val != key) return val;
    }
    // Si no se encuentra, retornar la clave formateada
    return key.replaceAll('_', ' ');
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
              color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.75),
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

    return CozyCard(
      padding: const EdgeInsets.all(20),
      shadowColor: phase.color,
      child: Row(
        children: [
          // Círculo de fase con anillo decorativo de puntos (petal ring)
          Stack(
            alignment: Alignment.center,
            children: [
              // Anillo exterior decorativo (puntos)
              CustomPaint(
                size: const Size(116, 116),
                painter: _PetalRingPainter(color: phase.borderColor.withValues(alpha: 0.35)),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: phase.color.withValues(alpha: 0.80),
                  border: Border.all(
                    color: phase.borderColor.withValues(alpha: 0.7),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: phase.color.withValues(alpha: 0.22),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        phase.name,
                        textAlign: TextAlign.center,
                        style: textTheme.labelLarge?.copyWith(fontSize: 12.5, height: 1.25),
                      ),
                      if (_todayMood != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getMoodEmoji(_todayMood!),
                          style: TextStyle(fontSize: 24),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.symptomsAndActionsLoggedSymptoms,
                  style: textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).bellotaColors.textoDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                if (_todaySymptoms.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Image.asset(
                        'assets/decorations/empty_state_cozy.png',
                        width: 54,
                        height: 54,
                        color: Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.7),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context)!.symptomsAndActionsNoSymptomsLogged,
                        style: textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).bellotaColors.textoMedio,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                if (_todaySymptoms.isNotEmpty)
                  ..._todaySymptoms.take(4).map((s) => _bulletItem(context, _translateSymptomKey(s))),
                if (_todaySymptoms.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '+${_todaySymptoms.length - 4} más',
                      style: textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).bellotaColors.chilero,
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





  // ───────────────────────
  // BOTTOM NAVIGATION BAR
  // ───────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bellotaColors.blanco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.09),
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
              _navItem(context, Icons.home_filled, AppLocalizations.of(context)!.navigationHome, 0),
              _navItem(context, Icons.calendar_month_rounded, AppLocalizations.of(context)!.navigationCalendar, 1),
              _navItem(context, Icons.article_outlined, AppLocalizations.of(context)!.navigationLog, 2),
              _navItem(context, Icons.location_on_outlined, AppLocalizations.of(context)!.navigationMap, 3),
              _navItem(context, Icons.person_outline_rounded, languageNotifier.currentLang == 'mi' ? '' : AppLocalizations.of(context)!.navigationProfile, 4),
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
        // Recargar datos cuando venimos del tab de Perfil al Inicio
        // Esto asegura que nombre, foto y correo estén actualizados
        if (index != 2 && _selectedNavIndex == 0) {
          _loadUser();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? Theme.of(context).bellotaColors.chilero : Theme.of(context).bellotaColors.textoMedio,
            ),
            if (label.isNotEmpty) ...[
              SizedBox(height: 3),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Theme.of(context).bellotaColors.chilero : Theme.of(context).bellotaColors.textoMedio,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'great': return '😁';
      case 'good': return '🙂';
      case 'neutral': return '😐';
      case 'low': return '😔';
      case 'bad': return '😢';
      default: return '';
    }
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

// ──────────────────────────────────────────────────────
// Petal Ring Painter — anillo de puntos orgánicos
// alrededor del círculo de fase en el resumen de hoy.
// ──────────────────────────────────────────────────────
class _PetalRingPainter extends CustomPainter {
  final Color color;
  _PetalRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const int dotCount = 24;
    const double dotRadius = 2.2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * math.pi * i) / dotCount - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_PetalRingPainter oldDelegate) =>
      oldDelegate.color != color;
}





