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

  // ── Definición de las 4 fases ──
  final List<_PhaseData> _phases = [
    _PhaseData(
      name: 'Fase\nOvulatoria',
      shortName: 'Ovulatoria',
      color: BellotaColors.melon,
      borderColor: Color(0xFFD97A4A),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: ['Fuerte dolor', 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
    ),
    _PhaseData(
      name: 'Fase\nLútea',
      shortName: 'Lútea',
      color: BellotaColors.asuncion,
      borderColor: Color(0xFF8FAFC8),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: ['Cansancio', 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
    ),
    _PhaseData(
      name: 'Fase\nFolicular',
      shortName: 'Folicular',
      color: BellotaColors.chiltoma,
      borderColor: Color(0xFF97B580),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: ['Energía alta', 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
    ),
    _PhaseData(
      name: 'Fase\nMenstrual',
      shortName: 'Menstrual',
      color: BellotaColors.chilero,
      borderColor: Color(0xFFB94A42),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: ['Cólicos', 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
    ),
  ];

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

    String? profileImagePath = prefs.getString('profileImagePath');

    setState(() {
      _userName = userName;
      _userEmail = userEmail;
      _userId = userId;
      _profileImagePath ??= profileImagePath;
    });

    if (userId != null) {
      await _loadDashboardData(userId);
    }
  }

  Future<void> _loadDashboardData(int userId) async {
    // 1. Cargar perfil para duración de ciclo (si existe) y foto de perfil
    final profile = await DatabaseHelper.instance.getProfile(userId);
    if (profile != null) {
      _cycleDuration = profile['cycle_duration'] as int? ?? 28;
      if (profile['profile_image_path'] != null) {
        setState(() {
          _profileImagePath = profile['profile_image_path'] as String?;
        });
      }
    }

    // 2. Determinar fase actual
    final now = DateTime.now();
    final lastPeriod = await DatabaseHelper.instance.getLastPeriodStart(userId);
    
    int cycleDay = 1;
    if (lastPeriod != null) {
      final diff = now.difference(lastPeriod).inDays;
      if (diff >= 0) {
        cycleDay = (diff % _cycleDuration) + 1;
      }
    } else {
      // Si no hay datos, simulamos o dejamos valor por defecto
      final diff = now.difference(DateTime(2026, 1, 1)).inDays;
      cycleDay = diff >= 0 ? (diff % _cycleDuration) + 1 : 1;
    }

    // Asignamos la fase según el día del ciclo
    if (cycleDay <= 5) {
      _currentPhaseIndex = 3; // Menstrual
    } else if (cycleDay <= 13) {
      _currentPhaseIndex = 2; // Folicular
    } else if (cycleDay <= 16) {
      _currentPhaseIndex = 0; // Ovulatoria
    } else {
      _currentPhaseIndex = 1; // Lútea
    }
    
    // Próximo periodo estimado
    int daysUntilNext = _cycleDuration - cycleDay + 1;
    _nextPeriodDate = now.add(Duration(days: daysUntilNext));

    // 3. Cargar síntomas registrados HOY
    String todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final log = await DatabaseHelper.instance.getDailyLog(userId, todayKey);

    List<String> combinedSymptoms = [];
    if (log != null) {
      if ((log['period_start'] as int?) == 1) {
        _periodoIniciado = true;
      } else {
        _periodoIniciado = false;
      }
      
      List<String> s = List<String>.from(jsonDecode(log['symptoms'] as String? ?? '[]'));
      combinedSymptoms.addAll(s);
    } else {
      _periodoIniciado = false;
    }

    setState(() {
      _todaySymptoms = combinedSymptoms;
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
    return Scaffold(
      backgroundColor: BellotaColors.basilica, // Fondo original correcto
      body: SafeArea(
        child: _getBody(context),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _getBody(BuildContext context) {
    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardContent(context);
      case 1:
        return CalendarScreen();
      case 3:
        return MapScreen();
      case 4:
        return ProfileScreen();
      default:
        return Center(
          child: Text(
            'Próximamente',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: BellotaColors.textoMedio),
          ),
        );
    }
  }

  Widget _buildDashboardContent(BuildContext context) {
    final phase = _phases[_currentPhaseIndex];
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
            _buildSectionLabel(context, 'Predicciones'),
            SizedBox(height: 10),
            _buildPrediccionesCard(context),
            SizedBox(height: 28),
            _buildSectionLabel(context, 'Resumen de hoy'),
            SizedBox(height: 10),
            _buildResumenCard(context, phase),
            SizedBox(height: 28),
            _buildSectionLabel(context, 'Información para ti'),
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
          onLanguagePressed: () {},
          onTalkBackPressed: () {},
          onNotificationPressed: () {},
        ),
      ],
    );
  }

  // ────────────────────────────
  // INICIO DEL PERIODO — Toggle
  // ────────────────────────────
  Widget _buildPeriodoToggle(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: BellotaColors.blanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BellotaColors.chilero.withValues(alpha: 0.07),
            blurRadius: 14,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: BellotaColors.chilero.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.water_drop_outlined,
                  size: 18,
                  color: BellotaColors.chilero,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Inicio del periodo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BellotaColors.textoDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: _periodoIniciado,
              onChanged: (val) async {
                setState(() => _periodoIniciado = val);
                if (_userId != null) {
                  final now = DateTime.now();
                  String todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                  final log = await DatabaseHelper.instance.getDailyLog(_userId!, todayKey);
                  List<String> s = [];
                  List<String> f = [];
                  List<String> x = [];
                  if (log != null) {
                    s = List<String>.from(jsonDecode(log['symptoms'] as String? ?? '[]'));
                    f = List<String>.from(jsonDecode(log['flujo'] as String? ?? '[]'));
                    x = List<String>.from(jsonDecode(log['sexo'] as String? ?? '[]'));
                  }
                  await DatabaseHelper.instance.saveDailyLog(
                    userId: _userId!,
                    date: todayKey,
                    periodStart: val,
                    symptoms: s,
                    sexo: x,
                    flujo: f,
                  );
                  _loadDashboardData(_userId!);
                }
              },
              activeThumbColor: BellotaColors.blanco,
              activeTrackColor: BellotaColors.chilero,
              inactiveThumbColor: BellotaColors.blanco,
              inactiveTrackColor: BellotaColors.textoMedio.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
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
                  'Tu próximo periodo será...',
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
                  'Basado en tus últimos ciclos.',
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
                  'Síntomas esperados',
                  style: textTheme.bodySmall?.copyWith(
                    color: BellotaColors.textoDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                _bulletItem(context, 'Cambios de humor'),
                _bulletItem(context, 'Sensibilidad'),
                _bulletItem(context, 'Cansancio'),
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
                  'Síntomas Registrados',
                  style: textTheme.titleMedium?.copyWith(
                    color: BellotaColors.textoDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                if (_todaySymptoms.isEmpty)
                  Text(
                    'Ningún síntoma registrado.',
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
              _navItem(context, Icons.home_filled, 'Inicio', 0),
              _navItem(context, Icons.calendar_month_rounded, 'Calendario', 1),
              _navItem(context, Icons.article_outlined, 'Registro', 2),
              _navItem(context, Icons.location_on_outlined, 'Mapa', 3),
              _navItem(context, Icons.person_outline_rounded, 'Perfil', 4),
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