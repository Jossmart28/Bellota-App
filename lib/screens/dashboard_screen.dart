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
import 'hospital_hub_screen.dart';
import 'calendar_screen.dart';
import 'symptom_log_screen.dart';
import 'profile_screen.dart';
import '../widgets/health_info_carousel.dart';
import '../core/services/cycle_service.dart';
import '../core/services/notification_service.dart';
import '../widgets/cycle_ring_widget.dart';
import '../core/services/clinical_analysis_service.dart';
import 'resumen_diario_screen.dart';
import '../widgets/bellota_empty_state.dart';
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

  // Datos dinï¿½micos para el dashboard
  List<String> _todaySymptoms = [];
  DateTime _nextPeriodDate = DateTime.now().add(Duration(days: 14));
  int _cycleDuration = 28;
  int _periodDuration = 5;
  DateTime? _lastPeriodStart;
  String? _contraceptive;
  CycleInfo? _cycleInfo;
  bool _hasPeriodsRegistered = true;

  List<String> _predictedSymptoms = ['mood_swings', 'sensitivity', 'fatigue'];
  String? _todayMood;
  List<String> _medicalConditions = [];
  List<ClinicalAlert> _activeAlerts = [];

  // â”€â”€ DefiniciÃ³n de las 4 fases â”€â”€
  List<_PhaseData> _getPhases(String lang) {
    return [
      _PhaseData(
        name: '${AppLocalizations.of(context)!.cyclePhasesPhase}\n${AppLocalizations.of(context)!.cyclePhasesOvulatory}',
        shortName: AppLocalizations.of(context)!.cyclePhasesOvulatory,
        color: Theme.of(context).bellotaColors.melon,
        borderColor: Color(0xFFD97A4A),
        symptomsTitle: 'SÃ­ntomas\nRegistrados',
        symptoms: [AppLocalizations.of(context)!.symptomsSeverePain],
      ),
      _PhaseData(
        name: '${AppLocalizations.of(context)!.cyclePhasesPhase}\n${AppLocalizations.of(context)!.cyclePhasesLuteal}',
        shortName: AppLocalizations.of(context)!.cyclePhasesLuteal,
        color: Theme.of(context).bellotaColors.asuncion,
        borderColor: Color(0xFF8FAFC8),
        symptomsTitle: 'SÃ­ntomas\nRegistrados',
        symptoms: [AppLocalizations.of(context)!.symptomsFatigue],
      ),
      _PhaseData(
        name: '${AppLocalizations.of(context)!.cyclePhasesPhase}\n${AppLocalizations.of(context)!.cyclePhasesFollicular}',
        shortName: AppLocalizations.of(context)!.cyclePhasesFollicular,
        color: Theme.of(context).bellotaColors.chiltoma,
        borderColor: Color(0xFF97B580),
        symptomsTitle: 'SÃ­ntomas\nRegistrados',
        symptoms: [AppLocalizations.of(context)!.symptomsHighEnergy],
      ),
      _PhaseData(
        name: '${AppLocalizations.of(context)!.cyclePhasesPhase}\n${AppLocalizations.of(context)!.cyclePhasesMenstrual}',
        shortName: AppLocalizations.of(context)!.cyclePhasesMenstrual,
        color: Theme.of(context).bellotaColors.chilero,
        borderColor: Color(0xFFD46A63),
        symptomsTitle: 'SÃ­ntomas\nRegistrados',
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
    // 1. Cargar perfil para duraciÃ³n de ciclo, foto y condiciones mÃ©dicas
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

    // 2. Obtener datos de perÃ­odos y fertilidad
    final now = DateTime.now();
    final lastPeriod = await DatabaseHelper.instance.getLastPeriodStart(userId);
      _lastPeriodStart = lastPeriod;
    final allPeriodStarts = await DatabaseHelper.instance.getAllPeriodStartDates(userId);
    
    // Cargar datos de fertilidad del ciclo actual (hasta 45 dÃ­as atrÃ¡s para mayor seguridad)
    List<Map<String, dynamic>>? fertilityData;
    if (lastPeriod != null) {
      String lastPeriodStr = "${lastPeriod.year}-${lastPeriod.month.toString().padLeft(2, '0')}-${lastPeriod.day.toString().padLeft(2, '0')}";
      String nowStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final logs = await DatabaseHelper.instance.getLogsInRange(userId, lastPeriodStr, nowStr);
      if (logs.isNotEmpty) {
        fertilityData = logs.map((l) => {
          'date': l['date'],
          'lh_test_result': l['lh_test_result'],
          'basal_temp': l['basal_temp'],
        }).toList();
      }
    }
    
    // 3. Calcular info del ciclo usando CycleService
    final cycleInfo = CycleService.instance.calculateCycleInfo(
      referenceDate: now,
      lastPeriodStart: lastPeriod,
      cycleDuration: _cycleDuration,
      periodDuration: _periodDuration,
      allPeriodStarts: allPeriodStarts.isNotEmpty ? allPeriodStarts : null,
      medicalConditions: medicalConds.isNotEmpty ? medicalConds : null,
      fertilityData: fertilityData,
    );

    // 4. Mapear fase a Ã­ndice del array _phases
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

    // 5. Cargar predicciones inteligentes de sÃ­ntomas (PrÃ³ximos 5 dÃ­as)
    String? contraceptive = profile?['contraceptive_method'] as String?;
      _contraceptive = contraceptive;
    
    final topSymptoms = await DatabaseHelper.instance.getPredictedSymptomsV2(
      userId, 
      phaseNameStr,
      medicalConds,
      contraceptive,
      limit: 5,
    );
    List<String> predictedSymptoms = topSymptoms.isNotEmpty ? topSymptoms : ['mood_swings', 'headache', 'bloating'];

    // 6. Cargar sÃ­ntomas registrados HOY y estado de Ã¡nimo
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

    final activeAlerts = await ClinicalAnalysisService.instance.analyzeHealthState(userId);

    setState(() {
      _activeAlerts = activeAlerts;
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
        const HospitalHubScreen(),
        const ProfileScreen(),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context, String lang) {
    return Stack(
      children: [
        // â”€â”€ DecoraciÃ³n: marca de agua floral en esquina superior derecha â”€â”€
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

                // â”€â”€ BotÃ³n de acceso al Resumen Diario â”€â”€
                _buildResumenDiarioBanner(context),

                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    AppLocalizations.of(context)!.dashboardTodaysSummary,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).bellotaColors.textoDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildResumenCard(context, _getPhases(languageNotifier.currentLang)[_currentPhaseIndex]),

                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    AppLocalizations.of(context)!.dashboardInformationForYou,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).bellotaColors.textoDark,
                    ),
                  ),
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



  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BANNER / BOTÃ“N â€” Acceso a Resumen Diario
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _getMascotImageForPhase(int index) {
    if (index < 0 || index > 3) return 'assets/images/bella_mascot.png';
    // 0: ovulatoria, 1: lutea, 2: folicular, 3: menstrual
    switch (index) {
      case 0: return 'assets/images/bella_ovulatoria.png';
      case 1: return 'assets/images/bella_lutea.png';
      case 2: return 'assets/images/bella_folicular.png';
      case 3: return 'assets/images/bella_menstrual.png';
      default: return 'assets/images/bella_mascot.png';
    }
  }

  Widget _buildResumenDiarioBanner(BuildContext context) {

    final phase = _getPhases(languageNotifier.currentLang)[_currentPhaseIndex];
    final List<String> monthNamesShort = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final String dateStr = '${_nextPeriodDate.day} ${monthNamesShort[_nextPeriodDate.month - 1]}';
    final daysUntil = _nextPeriodDate.difference(DateTime.now()).inDays;

    final bool hasCriticalAlert = _activeAlerts.any((a) => a.severity == 'high');

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
              activeAlerts: _activeAlerts,
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
                      'assets/images/bella_banner.jpg',
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
                      "PrÃ³ximo perÃ­odo: $dateStr",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysUntil <= 0
                          ? "Puede estar comenzando hoy"
                          : "En $daysUntil ${daysUntil == 1 ? 'dÃ­a' : 'dÃ­as'}",
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
                        "${_predictedSymptoms.length} sÃ­ntomas esperados",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      "Registra tu primer perÃ­odo para ver predicciones",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Flecha de navegaciÃ³n flotante con cÃ¡psula translÃºcida
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // HEADER CON BOTONERA GLOBAL
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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



  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // PREDICCIONES
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPrediccionesCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final List<String> monthNamesShort = [
      'Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.',
      'Jul.', 'Ago.', 'Sep.', 'Oct.', 'Nov.', 'Dic.'
    ];
    String dateStr = '${_nextPeriodDate.day}/${monthNamesShort[_nextPeriodDate.month - 1]}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    'âš ï¸ Predicciones pueden variar por PCOS',
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


  /// Traduce una clave de sÃ­ntoma al idioma actual
  String _translateSymptomKey(String key) {
    final lang = languageNotifier.currentLang;
    // Buscar en registration_form (donde estÃ¡n fever, headache, etc.)
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // RESUMEN DE HOY
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildResumenCard(BuildContext context, _PhaseData phase) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: phase.color.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CycleRingWidget(
            cycleInfo: _cycleInfo,
            phaseColor: phase.color,
            phaseBorder: phase.borderColor,
            phaseName: phase.name.replaceAll('\n', ' '),
            todayMood: _todayMood,
            size: 116,
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
                  BellotaEmptyState(
                    title: 'DÃ­a tranquilo',
                    message: AppLocalizations.of(context)!.symptomsAndActionsNoSymptomsLogged,
                    compact: true,
                    imagePath: _getMascotImageForPhase(_currentPhaseIndex),
                  ),
                if (_todaySymptoms.isNotEmpty)
                  ..._todaySymptoms.take(4).map((s) => _bulletItem(context, _translateSymptomKey(s))),
                if (_todaySymptoms.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '+${_todaySymptoms.length - 4} mÃ¡s',
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





  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BOTTOM NAVIGATION BAR
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
            // Recargar datos si volvemos a Inicio (por si cambiÃ³ la foto u otra cosa en Perfil)
            _loadUser();
          }
        }
        // Recargar datos cuando venimos del tab de Perfil al Inicio
        // Esto asegura que nombre, foto y correo estÃ©n actualizados
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
      case 'great': return 'ðŸ˜';
      case 'good': return 'ðŸ™‚';
      case 'neutral': return 'ðŸ˜';
      case 'low': return 'ðŸ˜”';
      case 'bad': return 'ðŸ˜¢';
      default: return '';
    }
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Modelo de datos de fase
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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




