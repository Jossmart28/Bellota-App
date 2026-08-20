import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import 'login_screen.dart';

/// Dashboard principal de Bellota - Calendario Menstrual
/// Diseño fiel a las 4 variantes del mockup de referencia.
/// Las fases se cambian con un tap en el círculo de fase.
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

  // ── Definición de las 4 fases ──
  final List<_PhaseData> _phases = [
    _PhaseData(
      name: 'Fase\nOvulatoria',
      shortName: 'Ovulatoria',
      color: Color(0xFFEE8658), // Melón / naranja
      borderColor: Color(0xFFD97A4A),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: [
        'Lorem ipsum dolor sit',
        'Amet consectetur',
        'Adipiscing elit sed',
        'Do eiusmod tempor',
      ],
    ),
    _PhaseData(
      name: 'Fase\nLútea',
      shortName: 'Lútea',
      color: Color(0xFFB0C4D8), // Asunción / azul-lavanda
      borderColor: Color(0xFF8FAFC8),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: [
        'Lorem ipsum dolor sit',
        'Amet consectetur',
        'Adipiscing elit sed',
        'Do eiusmod tempor',
      ],
    ),
    _PhaseData(
      name: 'Fase\nFolicular',
      shortName: 'Folicular',
      color: Color(0xFFB5C9A1), // Chiltoma / verde
      borderColor: Color(0xFF97B580),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: [
        'Lorem ipsum dolor sit',
        'Amet consectetur',
        'Adipiscing elit sed',
        'Do eiusmod tempor',
      ],
    ),
    _PhaseData(
      name: 'Fase\nMenstrual',
      shortName: 'Menstrual',
      color: Color(0xFFD35D53), // Chilero / rojo
      borderColor: Color(0xFFB94A42),
      symptomsTitle: 'Síntomas\nRegistrados',
      symptoms: [
        'Lorem ipsum dolor sit',
        'Amet consectetur',
        'Adipiscing elit sed',
        'Do eiusmod tempor',
      ],
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
    setState(() {
      _userName = prefs.getString('userName') ?? 'UsuarioApp';
      _userEmail = prefs.getString('userEmail') ?? 'correo@ejemplo.com';
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

  void _cyclePhase() {
    setState(() {
      _currentPhaseIndex = (_currentPhaseIndex + 1) % _phases.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_currentPhaseIndex];
    // Fondo general crema claro
    const bgColor = Color(0xFFF5EDE3); // Asunción-like background

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // ══════════════════════════════════════
                // HEADER — Avatar + nombre + logo + campana + foto
                // ══════════════════════════════════════
                _buildHeader(),
                const SizedBox(height: 20),
                // ══════════════════════════════════════
                // INICIO DEL PERIODO — Toggle switch
                // ══════════════════════════════════════
                _buildPeriodoToggle(),
                const SizedBox(height: 24),
                // ══════════════════════════════════════
                // PREDICCIONES — Card
                // ══════════════════════════════════════
                _buildPrediccionesSection(),
                const SizedBox(height: 24),
                // ══════════════════════════════════════
                // RESUMEN DE HOY — Con círculo de fase
                // ══════════════════════════════════════
                _buildResumenSection(phase),
                const SizedBox(height: 24),
                // ══════════════════════════════════════
                // INFORMACIÓN ADICIONAL — Card con contenido
                // ══════════════════════════════════════
                _buildInfoAdicionalSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      // ══════════════════════════════════════
      // BOTTOM NAVIGATION BAR — 5 ítems
      // ══════════════════════════════════════
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ────────────────────────────────────────
  // HEADER
  // ────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar circular
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8D5C0),
            border: Border.all(color: const Color(0xFFD4B896), width: 2),
          ),
          child: const Icon(Icons.person, color: Color(0xFF7A4F47), size: 24),
        ),
        const SizedBox(width: 10),
        // Nombre + email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3D2B27),
                ),
              ),
              Text(
                _userEmail,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7A4F47),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // Logo Bellota icono (estilizado)
        GestureDetector(
          onTap: () {}, // Botón sin función por ahora
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF7EACC),
            ),
            child: Center(
              child: Text(
                '🌰',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Campana de notificaciones
        GestureDetector(
          onTap: () {}, // Botón sin función por ahora
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BellotaColors.chilero,
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        // Foto de perfil / icono adicional
        GestureDetector(
          onTap: () {}, // Botón sin función por ahora
          onLongPress: _logout, // Cierre de sesión (manteniendo pulsado)
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8D5C0),
              border: Border.all(color: const Color(0xFFD4B896), width: 1.5),
            ),
            child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF7A4F47), size: 18),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────
  // INICIO DEL PERIODO — Toggle
  // ────────────────────────────────────────
  Widget _buildPeriodoToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
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
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3D2B27),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: _periodoIniciado,
              onChanged: (val) => setState(() => _periodoIniciado = val),
              activeThumbColor: Colors.white,
              activeTrackColor: BellotaColors.chilero,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFD4C4B0),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────
  // PREDICCIONES
  // ────────────────────────────────────────
  Widget _buildPrediccionesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Predicciones',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D2B27),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
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
              // Columna izquierda — fecha de próximo periodo
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lorem ipsum dolor sit amet...',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7A4F47),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '25/Feb.',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: BellotaColors.chilero,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur.',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF7A4F47),
                      ),
                    ),
                  ],
                ),
              ),
              // Divider vertical
              Container(
                width: 1,
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: const Color(0xFFE0D0C0),
              ),
              // Columna derecha — síntomas predichos
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lorem ipsum dolor sit...',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF3D2B27),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _bulletItem('Lorem ipsum dolor'),
                    _bulletItem('Amet consectetur'),
                    _bulletItem('Adipiscing elit'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF7A4F47),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF7A4F47),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────
  // RESUMEN DE HOY — Círculo de fase + síntomas
  // ────────────────────────────────────────
  Widget _buildResumenSection(_PhaseData phase) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de hoy',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D2B27),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
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
              // Círculo de fase — tappable para cambiar
              GestureDetector(
                onTap: _cyclePhase,
                child: AnimatedContainer(
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
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Síntomas registrados
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.symptomsTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3D2B27),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...phase.symptoms.map(
                      (s) => _bulletItem(s),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────
  // INFORMACIÓN ADICIONAL
  // ────────────────────────────────────────
  Widget _buildInfoAdicionalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información adicional',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3D2B27),
          ),
        ),
        const SizedBox(height: 12),
        // Card de información
        GestureDetector(
          onTap: () {}, // Botón sin función por ahora
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
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
                // Imagen placeholder
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFF7EACC),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: const Color(0xFFEEDFC8),
                      child: Center(
                        child: Icon(
                          Icons.article_outlined,
                          size: 40,
                          color: const Color(0xFFC5975B),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Texto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Lorem ipsum dolor sit amet consectetur?',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3D2B27),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7A4F47),
                          height: 1.4,
                        ),
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

  // ────────────────────────────────────────
  // BOTTOM NAVIGATION BAR — 5 ítems
  // ────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Inicio', 0),
              _navItem(Icons.favorite_border_rounded, 'Salud', 1),
              _navCenterButton(),
              _navItem(Icons.location_on_outlined, 'Mapa', 3),
              _navItem(Icons.person_outline_rounded, 'Perfil', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? BellotaColors.chilero : const Color(0xFFB0A090),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? BellotaColors.chilero : const Color(0xFFB0A090),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navCenterButton() {
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = 2),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFEE8658), Color(0xFFD35D53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: BellotaColors.chilero.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

// ────────────────────────────────────────
// Modelo de datos de fase
// ────────────────────────────────────────
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
