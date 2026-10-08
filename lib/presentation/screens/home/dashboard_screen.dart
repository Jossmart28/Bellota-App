import 'package:bellotadevelopment/core/constants/app_keys.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bellotadevelopment/presentation/screens/hospitals/hospital_hub_screen.dart';
import 'package:bellotadevelopment/presentation/common/health_info_carousel.dart';
import 'package:bellotadevelopment/presentation/common/cycle_ring_widget.dart';
import 'package:bellotadevelopment/presentation/common/bellota_empty_state.dart';
import 'package:bellotadevelopment/presentation/common/bellota_icon.dart';
import 'package:bellotadevelopment/domain/services/health_prediction_service.dart';


import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/presentation/common/bellota_top_actions.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/domain/repositories/user_repository.dart';
import 'package:bellotadevelopment/domain/repositories/auth_repository.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/domain/repositories/profile_repository.dart';
import 'package:bellotadevelopment/presentation/screens/auth/login_screen.dart';
import 'package:bellotadevelopment/presentation/screens/notifications/notifications_screen.dart';
import 'package:bellotadevelopment/presentation/screens/hospitals/hospital_hub_screen.dart';
import 'package:bellotadevelopment/presentation/screens/calendar/calendar_screen.dart';
import 'package:bellotadevelopment/presentation/screens/health_log/symptom_log_screen.dart';
import 'package:bellotadevelopment/presentation/screens/profile/profile_screen.dart';

import 'package:bellotadevelopment/core/services/cycle_service.dart';
import 'package:bellotadevelopment/core/services/notification_service.dart';

import 'package:bellotadevelopment/core/services/clinical_analysis_service.dart';
import 'package:bellotadevelopment/presentation/screens/health_log/resumen_diario_screen.dart';

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

  // Datos dinÃ¯Â¿Â½micos para el dashboard
  List<String> _todaySymptoms = [];
  DateTime _nextPeriodDate = DateTime.now().add(Duration(days: 14));
  int _cycleDuration = 28;
  int _periodDuration = 5;
  DateTime? _lastPeriodStart;
  List<DateTime> _allPeriodStarts = [];
  String? _contraceptive;
  CycleInfo? _cycleInfo;
  bool _hasPeriodsRegistered = true;

  List<String> _predictedSymptoms = ['mood_swings', 'sensitivity', 'fatigue'];
  String? _todayMood;
  List<String> _medicalConditions = [];
  List<ClinicalAlert> _activeAlerts = [];

  // â”€â”€ Definición de las 4 fases â”€â”€
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
      userId = await sl<AuthRepository>().getUserIdByEmail(userEmail);
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
    final profileModel = await sl<ProfileRepository>().getProfile(userId);
    final profile = profileModel?.toMap() ?? {};
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
    final lastPeriod = await sl<DailyLogRepository>().getLastPeriodStart(userId);
      _lastPeriodStart = lastPeriod;
    final allPeriodStarts = await sl<DailyLogRepository>().getAllPeriodStartDates(userId);
    
    // Cargar datos de fertilidad del ciclo actual (hasta 45 días atrás para mayor seguridad)
    List<Map<String, dynamic>>? fertilityData;
    if (lastPeriod != null) {
      String lastPeriodStr = "${lastPeriod.year}-${lastPeriod.month.toString().padLeft(2, '0')}-${lastPeriod.day.toString().padLeft(2, '0')}";
      String nowStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final logsModels = await sl<DailyLogRepository>().getLogsInRange(userId, lastPeriodStr, nowStr);
      final logs = logsModels.map((m) => m.toMap()).toList();
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

    // 5. Cargar predicciones inteligentes de síntomas (Próximos 5 días)
    String? contraceptive = profile?['contraceptive_method'] as String?;
      _contraceptive = contraceptive;
    
    final topSymptoms = await sl<HealthPredictionService>().getPredictedSymptomsV2(
      userId, 
      phaseNameStr,
      medicalConds,
      contraceptive,
      limit: 5,
    );
    List<String> predictedSymptoms = topSymptoms.isNotEmpty ? topSymptoms : ['mood_swings', 'headache', 'bloating'];

    // 6. Cargar síntomas registrados HOY y estado de ánimo
    String todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final logModel = await sl<DailyLogRepository>().getDailyLog(userId, todayKey);
    final log = logModel?.toMap();

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
      _allPeriodStarts = allPeriodStarts;
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
        CalendarScreen(),
        const SizedBox(), // Placeholder for symptom log
        HospitalHubScreen(),
        ProfileScreen(),
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context, String lang) {
    return Stack(
      children: [
        // â”€â”€ Decoración: marca de agua floral en esquina superior derecha â”€â”€
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

                // â”€â”€ Botón de acceso al Resumen Diario â”€â”€
                _buildResumenDiarioBanner(context),

                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Tu ciclo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).bellotaColors.textoDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTuCicloCard(context),

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
                HealthInfoCarousel(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }



  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BANNER / BOTÃƒâ€œN Ã¢â‚¬â€ Acceso a Resumen Diario
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
              userId: _userId,
              lastPeriodStart: _lastPeriodStart,
              cycleDuration: _cycleDuration,
              periodDuration: _periodDuration,
              contraceptive: _contraceptive,
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

          onNotificationPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationsScreen()),
            );
          },
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // RESUMEN DE HOY
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // ─────────────────────────────────────────────────────────────
  // TU CICLO CARD  — Acorn bar chart
  // ─────────────────────────────────────────────────────────────
  Widget _buildTuCicloCard(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;
    final sorted = List<DateTime>.from(_allPeriodStarts)..sort();
    // We need at least 3 registered period starts to show coloured data
    final hasEnoughData = sorted.length >= 3;

    // Build bars: each bar represents one complete cycle (gap between two consecutive period starts)
    final List<_CycleBar> bars = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final len = sorted[i + 1].difference(sorted[i]).inDays;
      if (len > 5 && len < 65) {
        bars.add(_CycleBar(date: sorted[i], length: len, isCurrent: false, isEstimate: false));
      }
    }
    // Add the in-progress current cycle bar
    if (sorted.isNotEmpty) {
      final lastStart = sorted.last;
      final currentLen = _cycleInfo?.cycleDay ?? DateTime.now().difference(lastStart).inDays + 1;
      bars.add(_CycleBar(date: lastStart, length: currentLen, isCurrent: true, isEstimate: !hasEnoughData));
    }

    // Only show up to last 4 complete cycles + current
    final visibleBars = bars.length > 5 ? bars.sublist(bars.length - 5) : bars;
    final int maxLen = visibleBars.isEmpty ? _cycleDuration : visibleBars.map((b) => b.length).reduce((a, b) => a > b ? a : b);

    // Regularity colour
    final isIrregular = _cycleInfo?.isIrregular ?? false;
    final activeColor = hasEnoughData
        ? (isIrregular ? colors.melon : colors.chilero)
        : colors.textoMedio.withOpacity(0.3);
    final activeDarkColor = hasEnoughData
        ? (isIrregular ? const Color(0xFFD97A4A) : const Color(0xFFBC4B4D))
        : colors.textoMedio.withOpacity(0.15);

    const monthNames = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: colors.chilero.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ─────────────────────────────────────────────────────
        Row(children: [
          BellotaIcon(color: hasEnoughData ? activeColor : colors.textoMedio.withOpacity(0.4), size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Tu ciclo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Outfit', color: colors.textoDark),
          )),
          if (hasEnoughData)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isIrregular ? colors.melon.withOpacity(0.12) : colors.chilero.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isIrregular ? 'Irregular' : 'Regular',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold,
                  color: isIrregular ? colors.melon : colors.chilero,
                ),
              ),
            ),
        ]),
        const SizedBox(height: 20),

        // ── Acorn bar chart ─────────────────────────────────────────────────
        if (visibleBars.isEmpty)
          _buildEmptyAcornChart(colors)
        else
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                // 1. Background (dashed lines and shaded zone)
                Positioned.fill(
                  child: Padding(
                    // Leave room for top labels and bottom labels
                    padding: const EdgeInsets.only(top: 25, bottom: 42),
                    child: CustomPaint(
                      painter: _ChartBackgroundPainter(
                        color: hasEnoughData ? const Color(0xFFE5D5C5) : colors.textoMedio.withOpacity(0.15),
                      ),
                    ),
                  ),
                ),
                
                // 2. Bars and Labels
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: visibleBars.map((bar) {
                    final fraction = maxLen > 0 ? bar.length / maxLen : 0.5;
                    final isCurrent = bar.isCurrent;
                    
                    // In pixel perfect spec, the body is melon/orange (#F1956A), current is light salmon dashed
                    final barColor = isCurrent ? activeColor : const Color(0xFFF1956A); 
                    final topTextColor = isCurrent ? activeColor : const Color(0xFF6B3A22);
                    final bottomTextColor = const Color(0xFF6B3A22).withOpacity(0.8);
                    
                    final dateLabel = '${bar.date.day.toString().padLeft(2, '0')}/${bar.date.month.toString().padLeft(2, '0')}';
                    final monthLabel = monthNames[bar.date.month - 1];

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Day count label on top
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: Text(
                                '${bar.length}',
                                key: ValueKey(bar.length),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: hasEnoughData ? topTextColor : colors.textoMedio,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Animated pixel-perfect acorn bar
                            _DashboardAcornBar(
                              fraction: fraction,
                              maxHeight: 105,
                              color: hasEnoughData ? barColor : colors.textoMedio.withOpacity(0.15),
                              isActive: hasEnoughData,
                              isCurrent: isCurrent,
                            ),
                            const SizedBox(height: 6),
                            
                            // Bottom Labels (month name or "Actual", then date)
                            if (isCurrent)
                              Text('Actual', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: activeColor))
                            else
                              Text(monthLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: bottomTextColor)),
                            
                            Text(dateLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isCurrent ? activeColor.withOpacity(0.8) : bottomTextColor)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // ── Bottom info strip ───────────────────────────────────────────────
        if (!hasEnoughData) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.basilica,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              ...List.generate(3, (i) {
                final done = i < sorted.length;
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: done ? colors.chilero : colors.textoMedio.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : Icons.circle_outlined,
                    color: done ? Colors.white : colors.textoMedio.withOpacity(0.35),
                    size: 13,
                  ),
                );
              }),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sorted.length < 3
                      ? 'Registra ${3 - sorted.length} período${3 - sorted.length == 1 ? '' : 's'} más para ver tu regularidad'
                      : 'Calculando regularidad...',
                  style: TextStyle(fontSize: 12, color: colors.textoMedio, fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isIrregular
                  ? colors.melon.withOpacity(0.08)
                  : colors.chilero.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              Icon(
                isIrregular ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                color: isIrregular ? colors.melon : colors.chilero,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(
                isIrregular
                    ? 'Tu ciclo varía más de 7 días. Consulta a tu médico si es reciente.'
                    : 'Promedio: ${_cycleInfo?.averageCycleLength?.toStringAsFixed(0) ?? _cycleDuration} días — ciclo regular.',
                style: TextStyle(fontSize: 12, color: isIrregular ? colors.melon : colors.chilero, height: 1.4),
              )),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildEmptyAcornChart(BellotaColors colors) {
    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (i) {
          final fractions = [0.55, 0.75, 0.65, 0.85, 0.5];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                _DashboardAcornBar(
                  fraction: fractions[i],
                  maxHeight: 90,
                  color: colors.textoMedio.withOpacity(0.2),
                  isActive: false,
                  isCurrent: i == 4,
                ),
                const SizedBox(height: 6),
                Container(
                  width: 24, height: 6,
                  decoration: BoxDecoration(
                    color: colors.textoMedio.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

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
                    title: 'Día tranquilo',
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
      case 'great': return 'Ã°Å¸ËœÂ';
      case 'good': return 'Ã°Å¸â„¢â€š';
      case 'neutral': return 'Ã°Å¸ËœÂ';
      case 'low': return 'Ã°Å¸Ëœâ€';
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






// ─────────────────────────────────────────────────────────────
// Data model for Tu ciclo bar chart
// ─────────────────────────────────────────────────────────────
class _CycleBar {
  final DateTime date;
  final int length;
  final bool isCurrent;
  final bool isEstimate;
  const _CycleBar({required this.date, required this.length, required this.isCurrent, required this.isEstimate});
}

// ─────────────────────────────────────────────────────────────
// Pixel-Perfect Acorn Chart Implementation
// ─────────────────────────────────────────────────────────────

class _DashboardAcornBar extends StatefulWidget {
  final double fraction;     // 0.0 – 1.0
  final double maxHeight;
  final Color color;
  final bool isActive;
  final bool isCurrent;

  const _DashboardAcornBar({
    required this.fraction,
    required this.maxHeight,
    required this.color,
    required this.isActive,
    required this.isCurrent,
  });

  @override
  State<_DashboardAcornBar> createState() => _DashboardAcornBarState();
}

class _DashboardAcornBarState extends State<_DashboardAcornBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void didUpdateWidget(_DashboardAcornBar old) {
    super.didUpdateWidget(old);
    if (old.fraction != widget.fraction) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        // Leave room for the cap/stem to not get clipped
        final paddedHeight = widget.maxHeight + 15;
        final targetH = widget.maxHeight * widget.fraction;
        // Ensure minimum height
        final animH = (targetH * _anim.value).clamp(20.0, widget.maxHeight);

        return SizedBox(
          width: 38,
          height: paddedHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: Size(38, animH + 15), // +15 for the cap overlap at top
              painter: _PixelPerfectAcornPainter(
                color: widget.color,
                isActive: widget.isActive,
                isCurrent: widget.isCurrent,
                barHeight: animH,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PixelPerfectAcornPainter extends CustomPainter {
  final Color color;
  final bool isActive;
  final bool isCurrent;
  final double barHeight;

  const _PixelPerfectAcornPainter({
    required this.color,
    required this.isActive,
    required this.isCurrent,
    required this.barHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // We draw from bottom up to leave room for the cap at the top.
    // The cap takes about 12-15px above the bar body.
    final bottomY = size.height;
    final topY = bottomY - barHeight;

    if (isCurrent) {
      // ── "Actual" Cycle: Dashed pill, fully rounded, no cap ──
      final paint = Paint()
        ..color = color.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      
      final rect = RRect.fromLTRBR(2, topY, w - 2, bottomY, Radius.circular(w / 2));
      canvas.drawRRect(rect, paint);

      // Draw dashed border
      final borderPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      _drawDashedRRect(canvas, rect, borderPaint);

      // Draw little acorn icon near top
      if (barHeight > 30) {
        _drawMiniAcornIcon(canvas, Offset(w / 2, topY + 16), color);
      }
    } else {
      // ── Completed Cycle: Solid pill body + cap on top ──
      
      // 1. Body (Flat top, rounded bottom)
      final bodyPaint = Paint()
        ..color = isActive ? color : const Color(0xFFD6D6D6)
        ..style = PaintingStyle.fill;
      
      final bodyRect = RRect.fromRectAndCorners(
        Rect.fromLTRB(4, topY, w - 4, bottomY),
        topLeft: Radius.zero,
        topRight: Radius.zero,
        bottomLeft: Radius.circular((w - 8) / 2),
        bottomRight: Radius.circular((w - 8) / 2),
      );
      canvas.drawRRect(bodyRect, bodyPaint);

      // 2. Cap (Dark brown, sits on top, wider than body)
      final capColor = isActive ? const Color(0xFF6B3A22) : const Color(0xFFAAAAAA);
      final capPaint = Paint()
        ..color = capColor
        ..style = PaintingStyle.fill;
      
      final capH = 9.0;
      final capRect = RRect.fromRectAndCorners(
        Rect.fromLTRB(0, topY - capH, w, topY),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );
      canvas.drawRRect(capRect, capPaint);

      // 3. Stem
      final stemPaint = Paint()
        ..color = capColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(w / 2, topY - capH), Offset(w / 2, topY - capH - 4), stemPaint);
    }
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final Path path = Path()..addRRect(rrect);
    final dashWidth = 4.0;
    final dashSpace = 4.0;
    double distance = 0.0;

    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        final Path extractPath = measurePath.extractPath(distance, distance + dashWidth);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
      distance = 0.0; // Reset for next metric
    }
  }

  void _drawMiniAcornIcon(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    
    // Tiny cap
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 12, height: 8),
      3.14159, 3.14159, // Top half
      false, paint..style = PaintingStyle.fill
    );
    // Tiny body
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 2), width: 10, height: 10),
      0, 3.14159, // Bottom half
      false, paint..style = PaintingStyle.stroke
    );
  }

  @override
  bool shouldRepaint(_PixelPerfectAcornPainter old) =>
      old.color != color || old.isActive != isActive || old.barHeight != barHeight;
}

class _ChartBackgroundPainter extends CustomPainter {
  final Color color;

  _ChartBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // We have 3 dashed lines: top, middle, bottom
    // The space between top and middle is shaded.
    final double topY = 0;
    final double midY = h * 0.4;
    final double bottomY = h;

    // Draw shaded band between top and middle
    final bandPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(0, topY, w, midY), bandPaint);

    // Draw dashed lines
    final linePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawDashedLine(canvas, Offset(0, topY), Offset(w, topY), linePaint);
    _drawDashedLine(canvas, Offset(0, midY), Offset(w, midY), linePaint);
    _drawDashedLine(canvas, Offset(0, bottomY), Offset(w, bottomY), linePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dashWidth = 4.0;
    final dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      canvas.drawLine(
        Offset(startX, p1.dy),
        Offset(startX + dashWidth > p2.dx ? p2.dx : startX + dashWidth, p1.dy),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_ChartBackgroundPainter old) => old.color != color;
}
