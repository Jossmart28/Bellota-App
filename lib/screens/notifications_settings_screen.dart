import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../database/database_helper.dart';

/// Pantalla de configuración de Recordatorios y Notificaciones
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _recordatorioPeriodo = true;
  bool _recordatorioOvulacion = true;
  bool _recordatorioPildora = false;
  bool _recordatorioHidratacion = false;
  bool _recordatorioEjercicio = false;
  bool _notificacionesApp = true;
  bool _sonidosNotificacion = true;
  bool _recordatorioCitaMedica = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail') ?? '';
    
    final userId = await DatabaseHelper.instance.getUserIdByEmail(email);
    if (userId != null) {
      final profile = await DatabaseHelper.instance.getProfile(userId);
      if (profile != null) {
        setState(() {
          _userId = userId;
          _recordatorioPeriodo = (profile['notif_periodo'] ?? 1) == 1;
          _recordatorioOvulacion = (profile['notif_ovulacion'] ?? 1) == 1;
          _recordatorioPildora = (profile['notif_pildora'] ?? 0) == 1;
          _recordatorioHidratacion = (profile['notif_hidratacion'] ?? 0) == 1;
          _recordatorioEjercicio = (profile['notif_ejercicio'] ?? 0) == 1;
          _notificacionesApp = (profile['notif_app'] ?? 1) == 1;
          _sonidosNotificacion = (profile['notif_sonidos'] ?? 1) == 1;
          _recordatorioCitaMedica = (profile['notif_cita_medica'] ?? 0) == 1;
        });
        return;
      }
    }

    setState(() {
      _recordatorioPeriodo = prefs.getBool('notif_periodo') ?? true;
      _recordatorioOvulacion = prefs.getBool('notif_ovulacion') ?? true;
      _recordatorioPildora = prefs.getBool('notif_pildora') ?? false;
      _recordatorioHidratacion = prefs.getBool('notif_hidratacion') ?? false;
      _recordatorioEjercicio = prefs.getBool('notif_ejercicio') ?? false;
      _notificacionesApp = prefs.getBool('notif_app') ?? true;
      _sonidosNotificacion = prefs.getBool('notif_sonidos') ?? true;
      _recordatorioCitaMedica = prefs.getBool('notif_cita_medica') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    if (_userId != null) {
      await DatabaseHelper.instance.updateProfileField(_userId!, key, value ? 1 : 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: BellotaColors.textoDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Recordatorios y Notificaciones',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: BellotaColors.textoDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sección: Recordatorios de Ciclo ──
            _sectionTitle('Recordatorios de Ciclo'),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.water_drop_outlined,
              iconColor: BellotaColors.chilero,
              title: 'Recordatorio de periodo',
              subtitle: 'Aviso antes del inicio de tu periodo',
              value: _recordatorioPeriodo,
              onChanged: (val) {
                setState(() => _recordatorioPeriodo = val);
                _saveSetting('notif_periodo', val);
              },
            ),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.favorite_border_rounded,
              iconColor: BellotaColors.melon,
              title: 'Recordatorio de ovulación',
              subtitle: 'Aviso en tus días fértiles',
              value: _recordatorioOvulacion,
              onChanged: (val) {
                setState(() => _recordatorioOvulacion = val);
                _saveSetting('notif_ovulacion', val);
              },
            ),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.medication_outlined,
              iconColor: BellotaColors.chiltoma,
              title: 'Recordatorio de píldora',
              subtitle: 'Recordatorio diario para tomar tu píldora',
              value: _recordatorioPildora,
              onChanged: (val) {
                setState(() => _recordatorioPildora = val);
                _saveSetting('notif_pildora', val);
              },
            ),

            const SizedBox(height: 24),

            // ── Sección: Bienestar ──
            _sectionTitle('Bienestar'),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.local_drink_outlined,
              iconColor: BellotaColors.asuncion,
              title: 'Recordatorio de hidratación',
              subtitle: 'Beber agua regularmente',
              value: _recordatorioHidratacion,
              onChanged: (val) {
                setState(() => _recordatorioHidratacion = val);
                _saveSetting('notif_hidratacion', val);
              },
            ),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.fitness_center_outlined,
              iconColor: BellotaColors.melon,
              title: 'Recordatorio de ejercicio',
              subtitle: 'Mantén tu rutina de actividad física',
              value: _recordatorioEjercicio,
              onChanged: (val) {
                setState(() => _recordatorioEjercicio = val);
                _saveSetting('notif_ejercicio', val);
              },
            ),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.calendar_month_outlined,
              iconColor: BellotaColors.chilero,
              title: 'Recordatorio de cita médica',
              subtitle: 'No olvides tus citas con el ginecólogo',
              value: _recordatorioCitaMedica,
              onChanged: (val) {
                setState(() => _recordatorioCitaMedica = val);
                _saveSetting('notif_cita_medica', val);
              },
            ),

            const SizedBox(height: 24),

            // ── Sección: General ──
            _sectionTitle('General'),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.notifications_outlined,
              iconColor: BellotaColors.textoDark,
              title: 'Notificaciones de la app',
              subtitle: 'Actualizaciones y novedades de Bellota',
              value: _notificacionesApp,
              onChanged: (val) {
                setState(() => _notificacionesApp = val);
                _saveSetting('notif_app', val);
              },
            ),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.volume_up_outlined,
              iconColor: BellotaColors.textoMedio,
              title: 'Sonidos de notificación',
              subtitle: 'Reproducir sonido con cada notificación',
              value: _sonidosNotificacion,
              onChanged: (val) {
                setState(() => _sonidosNotificacion = val);
                _saveSetting('notif_sonidos', val);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: BellotaColors.textoDark,
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BellotaColors.textoDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: BellotaColors.textoMedio,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
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
}
