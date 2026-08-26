import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../theme/bellota_colors.dart';
import '../widgets/bellota_top_actions.dart';
import '../database/database_helper.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'calendar_screen.dart';
import 'symptom_log_screen.dart';
import 'profile_screen.dart';

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

  // Datos dinámicos para el dashboard
  List<String> _todaySymptoms = [];
  DateTime _nextPeriodDate = DateTime.now().add(const Duration(days: 14));
  int _cycleDuration = 28;

  // ── Definición de las 4 fases ──
  final List<_PhaseData> _phases = [
    const _PhaseData(
      name: 'Fase\nOvulatoria',
      shortName: 'Ovulatoria',
      color: BellotaColors.melon,
      borderColor: Color(0xFFD97A4A),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: ['Fuerte dolor', 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
    ),
    const _PhaseData(
      name: 'Fase\nLútea',
      shortName: 'Lútea',
      color: BellotaColors.asuncion,
      borderColor: Color(0xFF8FAFC8),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: ['Cansancio', 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
    ),
    const _PhaseData(
      name: 'Fase\nFolicular',
      shortName: 'Folicular',
      color: BellotaColors.chiltoma,
      borderColor: Color(0xFF97B580),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: ['Energía alta', 'Amet consectetur', 'Adipiscing elit sed', 'Do eiusmod tempor'],
    ),
    const _PhaseData(
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
      const SystemUiOverlayStyle(
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
    }
  }

  Future<void> _loadDashboardData(int userId) async {
    // 1. Cargar perfil para duración de ciclo (si existe)
    final profile = await DatabaseHelper.instance.getProfile(userId);
    if (profile != null) {
      _cycleDuration = profile['cycle_duration'] as int? ?? 28;
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
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
        return const CalendarScreen();
      case 3:
        return const MapScreen();
      case 4:
        return const ProfileScreen();
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
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildPeriodoToggle(context),
            const SizedBox(height: 24),
            _buildPrediccionesSection(context),
            const SizedBox(height: 24),
            _buildResumenSection(context, phase),
            const SizedBox(height: 24),
            _buildInfoAdicionalSection(context),
            const SizedBox(height: 20),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BellotaColors.nancite,
              border: Border.all(color: BellotaColors.textoMedio.withValues(alpha: 0.3), width: 2),
            ),
            child: const Icon(Icons.person, color: BellotaColors.textoMedio, size: 24),
          ),
        ),
        const SizedBox(width: 10),

        // Nombre + email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: textTheme.titleMedium?.copyWith(color: BellotaColors.textoDark, fontWeight: FontWeight.w700),
              ),
              Text(
                _userEmail,
                style: textTheme.bodySmall,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: BellotaColors.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Inicio del periodo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: BellotaColors.textoDark, fontSize: 15),
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
  Widget _buildPrediccionesSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final List<String> monthNamesShort = [
      'Ene.', 'Feb.', 'Mar.', 'Abr.', 'May.', 'Jun.',
      'Jul.', 'Ago.', 'Sep.', 'Oct.', 'Nov.', 'Dic.'
    ];
    String dateStr = '${_nextPeriodDate.day}/${monthNamesShort[_nextPeriodDate.month - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Predicciones',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: BellotaColors.blanco,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: textTheme.headlineLarge?.copyWith(color: BellotaColors.chilero, fontSize: 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Basado en tus últimos ciclos.',
                      style: textTheme.bodySmall?.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: BellotaColors.textoMedio.withValues(alpha: 0.2),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Síntomas esperados',
                      style: textTheme.bodySmall?.copyWith(color: BellotaColors.textoDark, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    _bulletItem(context, 'Cambios de humor'),
                    _bulletItem(context, 'Sensibilidad'),
                    _bulletItem(context, 'Cansancio'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bulletItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: BellotaColors.textoMedio,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────
  // RESUMEN DE HOY
  // ───────────────
  Widget _buildResumenSection(BuildContext context, _PhaseData phase) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de hoy',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: BellotaColors.blanco,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: phase.color.withValues(alpha: 0.85),
                  border: Border.all(color: phase.borderColor, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: phase.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    phase.name,
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge?.copyWith(fontSize: 13, height: 1.2),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Síntomas Registrados',
                      style: textTheme.titleMedium?.copyWith(color: BellotaColors.textoDark, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    if (_todaySymptoms.isEmpty)
                      Text('Ningún síntoma registrado.', style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                    if (_todaySymptoms.isNotEmpty)
                      ..._todaySymptoms.take(4).map((s) => _bulletItem(context, s)),
                    if (_todaySymptoms.length > 4)
                      Text('+${_todaySymptoms.length - 4} más', style: textTheme.bodySmall?.copyWith(color: BellotaColors.chilero, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────
  // INFORMACIÓN ADICIONAL
  // ──────────────────────
  Widget _buildInfoAdicionalSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información adicional',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: BellotaColors.blanco,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: BellotaColors.nancite,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.article_outlined,
                      size: 40,
                      color: BellotaColors.melon,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cómo afecta el estrés tu ciclo?',
                        style: textTheme.titleMedium?.copyWith(color: BellotaColors.textoDark, fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'El estrés crónico puede alterar tus niveles hormonales, provocando retrasos en tu periodo o cambios en la ovulación.',
                        style: textTheme.bodySmall?.copyWith(fontSize: 10, height: 1.4),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────
  // BOTTOM NAVIGATION BAR
  // ───────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BellotaColors.blanco,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              builder: (context) => const SymptomLogScreen(),
            ),
          );
          if (result == true) {
            _loadUser(); // Refresh dashboard data
          }
        } else {
          setState(() => _selectedNavIndex = index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? BellotaColors.chilero : BellotaColors.textoMedio,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? BellotaColors.chilero : BellotaColors.textoMedio,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 6),
              Container(
                height: 3,
                width: 32,
                decoration: BoxDecoration(
                  color: BellotaColors.chilero,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ] else ...[
              const SizedBox(height: 9),
            ]
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

  const _PhaseData({
    required this.name,
    required this.shortName,
    required this.color,
    required this.borderColor,
    required this.symptomsTitle,
    required this.symptoms,
  });
}