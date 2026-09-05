import '../core/constants/app_keys.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/bellota_colors.dart';
import '../database/database_helper.dart';
import '../core/services/notification_service.dart';

/// Pantalla de configuracion de Recordatorios y Notificaciones
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
  bool _notificacionesApp = true;
  bool _sonidosNotificacion = true;
  bool _recordatorioCitaMedica = false;
  bool _recordatorioDiario = true;

  // Hora del registro diario
  TimeOfDay _logTime = const TimeOfDay(hour: 21, minute: 0);

  // Horarios de pÃ­ldora (mÃ¡x 10)
  List<TimeOfDay> _pillTimes = [];

  // Citas mÃ©dicas semanales
  List<_ApptEntry> _appointments = [];

  int? _userId;
  bool _permissionGranted = true;
  bool _permissionChecked = false;

  static const _days = ['', 'Lunes', 'Martes', 'MiÃ©rcoles', 'Jueves', 'Viernes', 'SÃ¡bado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.instance.hasPermission();
    if (mounted) {
      setState(() {
        _permissionGranted = granted;
        _permissionChecked = true;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(AppKeys.userEmail) ?? '';
    final userId = await DatabaseHelper.instance.getUserIdByEmail(email);

    if (userId != null) {
      final profile = await DatabaseHelper.instance.getProfile(userId);

      // Load pill times from DB
      final pillRaw = await DatabaseHelper.instance.getPillTimesRaw(userId);
      final pills = pillRaw
          .map((r) => TimeOfDay(hour: r['hour'] as int, minute: r['minute'] as int))
          .toList();

      // Load appointments from DB
      final apptRaw = await DatabaseHelper.instance.getWeeklyAppointmentsRaw(userId);
      final appts = apptRaw
          .map((r) => _ApptEntry(
                weekday: r['weekday'] as int,
                time: TimeOfDay(hour: r['hour'] as int, minute: r['minute'] as int),
              ))
          .toList();

      if (profile != null && mounted) {
        setState(() {
          _userId = userId;
          _recordatorioPeriodo = (profile['notif_periodo'] ?? 1) == 1;
          _recordatorioOvulacion = (profile['notif_ovulacion'] ?? 1) == 1;
          _recordatorioPildora = (profile['notif_pildora'] ?? 0) == 1;
          _notificacionesApp = (profile['notif_app'] ?? 1) == 1;
          _sonidosNotificacion = (profile['notif_sonidos'] ?? 1) == 1;
          _recordatorioCitaMedica = (profile['notif_cita_medica'] ?? 0) == 1;
          _recordatorioDiario = (profile['notif_daily_log'] ?? 1) == 1;
          _logTime = TimeOfDay(
            hour: profile['notif_log_hour'] as int? ?? 21,
            minute: profile['notif_log_minute'] as int? ?? 0,
          );
          _pillTimes = pills.isEmpty ? [const TimeOfDay(hour: 8, minute: 0)] : pills;
          _appointments = appts;
        });
        return;
      }
    }

    setState(() {
      _pillTimes = [const TimeOfDay(hour: 8, minute: 0)];
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (_userId != null) {
      await DatabaseHelper.instance.updateProfileField(_userId!, key, value ? 1 : 0);
      await NotificationService.instance.scheduleAllNotifications(_userId!);
    }
  }

  Future<void> _savePillTimes() async {
    if (_userId == null) return;
    await DatabaseHelper.instance.setPillTimes(
      _userId!,
      _pillTimes.map((t) => {'h': t.hour, 'm': t.minute}).toList(),
    );
    await NotificationService.instance.scheduleAllNotifications(_userId!);
  }

  Future<void> _saveAppointments() async {
    if (_userId == null) return;
    await DatabaseHelper.instance.setWeeklyAppointments(
      _userId!,
      _appointments.map((a) => {'wd': a.weekday, 'h': a.time.hour, 'm': a.time.minute}).toList(),
    );
    await NotificationService.instance.scheduleAllNotifications(_userId!);
  }

  Future<void> _saveLogTime() async {
    if (_userId == null) return;
    await DatabaseHelper.instance.updateProfileField(_userId!, 'notif_log_hour', _logTime.hour);
    await DatabaseHelper.instance.updateProfileField(_userId!, 'notif_log_minute', _logTime.minute);
    await NotificationService.instance.scheduleAllNotifications(_userId!);
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.instance.requestPermission();
    if (mounted) setState(() => _permissionGranted = granted);
    if (granted && _userId != null) {
      await NotificationService.instance.scheduleAllNotifications(_userId!);
    }
    if (!granted && mounted) await openAppSettings();
  }

  String _fmtTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).bellotaColors.textoDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Recordatorios y Notificaciones',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).bellotaColors.textoDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_permissionChecked && !_permissionGranted) _buildPermissionBanner(),
            if (_permissionChecked && !_permissionGranted) const SizedBox(height: 16),

            // â”€â”€ General â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _sectionTitle('General'),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.notifications_outlined,
              iconColor: Theme.of(context).bellotaColors.textoDark,
              title: 'Notificaciones de la app',
              subtitle: 'Activar o desactivar todas las notificaciones',
              value: _notificacionesApp,
              onChanged: (val) async {
                setState(() => _notificacionesApp = val);
                await _saveSetting('notif_app', val);
                if (!val) await NotificationService.instance.cancelAll();
              },
            ),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.volume_up_outlined,
              iconColor: Theme.of(context).bellotaColors.textoMedio,
              title: 'Sonidos de notificaciÃ³n',
              subtitle: 'Reproducir sonido con cada notificaciÃ³n',
              value: _sonidosNotificacion,
              enabled: _notificacionesApp,
              onChanged: (val) {
                setState(() => _sonidosNotificacion = val);
                _saveSetting('notif_sonidos', val);
              },
            ),

            const SizedBox(height: 24),

            // â”€â”€ Recordatorios de Ciclo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _sectionTitle('Recordatorios de Ciclo'),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.water_drop_outlined,
              iconColor: Theme.of(context).bellotaColors.chilero,
              title: 'Recordatorio de periodo',
              subtitle: '3 dÃ­as antes del inicio estimado de tu periodo',
              value: _recordatorioPeriodo,
              enabled: _notificacionesApp,
              onChanged: (val) {
                setState(() => _recordatorioPeriodo = val);
                _saveSetting('notif_periodo', val);
              },
            ),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.favorite_border_rounded,
              iconColor: Theme.of(context).bellotaColors.melon,
              title: 'Recordatorio de ovulaciÃ³n',
              subtitle: '1 dÃ­a antes del inicio de tus dÃ­as fÃ©rtiles',
              value: _recordatorioOvulacion,
              enabled: _notificacionesApp,
              onChanged: (val) {
                setState(() => _recordatorioOvulacion = val);
                _saveSetting('notif_ovulacion', val);
              },
            ),

            const SizedBox(height: 24),

            // â”€â”€ PÃ­ldora â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _sectionTitle('PÃ­ldora'),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.medication_outlined,
              iconColor: Theme.of(context).bellotaColors.chiltoma,
              title: 'Recordatorio de pÃ­ldora',
              subtitle: 'RecibirÃ¡s una alarma por cada horario configurado',
              value: _recordatorioPildora,
              enabled: _notificacionesApp,
              onChanged: (val) {
                setState(() => _recordatorioPildora = val);
                _saveSetting('notif_pildora', val);
              },
            ),
            if (_recordatorioPildora && _notificacionesApp) ...[
              const SizedBox(height: 8),
              _buildPillTimesPanel(),
            ],

            const SizedBox(height: 24),

            // â”€â”€ Bienestar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _sectionTitle('Bienestar'),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.edit_note_outlined,
              iconColor: Theme.of(context).bellotaColors.asuncion,
              title: 'Registro diario',
              subtitle: 'Te recordamos registrar cÃ³mo te sentiste',
              value: _recordatorioDiario,
              enabled: _notificacionesApp,
              onChanged: (val) {
                setState(() => _recordatorioDiario = val);
                _saveSetting('notif_daily_log', val);
              },
            ),
            if (_recordatorioDiario && _notificacionesApp) ...[
              const SizedBox(height: 8),
              _buildSingleTimeCard(
                label: 'Hora del recordatorio diario',
                time: _logTime,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _logTime,
                    builder: (ctx, child) => _themedPicker(ctx, child),
                  );
                  if (picked != null) {
                    setState(() => _logTime = picked);
                    await _saveLogTime();
                  }
                },
              ),
            ],

            const SizedBox(height: 24),

            // â”€â”€ Citas MÃ©dicas â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _sectionTitle('Citas MÃ©dicas'),
            const SizedBox(height: 10),
            _buildToggleCard(
              icon: Icons.calendar_month_outlined,
              iconColor: const Color(0xFF6B9EC7),
              title: 'Recordatorio de cita mÃ©dica',
              subtitle: 'Configura uno o varios recordatorios semanales',
              value: _recordatorioCitaMedica,
              enabled: _notificacionesApp,
              onChanged: (val) {
                setState(() => _recordatorioCitaMedica = val);
                _saveSetting('notif_cita_medica', val);
              },
            ),
            if (_recordatorioCitaMedica && _notificacionesApp) ...[
              const SizedBox(height: 8),
              _buildAppointmentsPanel(),
            ],

            const SizedBox(height: 32),
            
            // â”€â”€ Probar Notificaciones â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Center(
              child: TextButton.icon(
                onPressed: () => NotificationService.instance.sendTestNotification(),
                icon: Icon(Icons.send_to_mobile_rounded, color: Theme.of(context).bellotaColors.textoMedio),
                label: Text(
                  'Enviar notificaciÃ³n de prueba',
                  style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoMedio, fontWeight: FontWeight.w500),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // â”€â”€ PÃ­ldora panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPillTimesPanel() {
    return _buildExpandableCard(
      child: Column(
        children: [
          ..._pillTimes.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            return _buildTimeRow(
              label: 'PÃ­ldora ${i + 1}',
              time: t,
              iconColor: Theme.of(context).bellotaColors.chiltoma,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: t,
                  builder: (ctx, child) => _themedPicker(ctx, child),
                );
                if (picked != null) {
                  setState(() => _pillTimes[i] = picked);
                  await _savePillTimes();
                }
              },
              onDelete: _pillTimes.length > 1
                  ? () async {
                      setState(() => _pillTimes.removeAt(i));
                      await _savePillTimes();
                    }
                  : null,
            );
          }),
          if (_pillTimes.length < 10) ...[
            const SizedBox(height: 4),
            _buildAddButton(
              label: 'Agregar hora de pÃ­ldora',
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                  builder: (ctx, child) => _themedPicker(ctx, child),
                );
                if (picked != null) {
                  setState(() => _pillTimes.add(picked));
                  await _savePillTimes();
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  // â”€â”€ Appointments panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildAppointmentsPanel() {
    return _buildExpandableCard(
      child: Column(
        children: [
          ..._appointments.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value;
            return _buildApptRow(
              entry: a,
              onTapTime: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: a.time,
                  builder: (ctx, child) => _themedPicker(ctx, child),
                );
                if (picked != null) {
                  setState(() => _appointments[i] = _ApptEntry(weekday: a.weekday, time: picked));
                  await _saveAppointments();
                }
              },
              onTapDay: () async {
                final picked = await _showDayPicker(a.weekday);
                if (picked != null) {
                  setState(() => _appointments[i] = _ApptEntry(weekday: picked, time: a.time));
                  await _saveAppointments();
                }
              },
              onDelete: () async {
                setState(() => _appointments.removeAt(i));
                await _saveAppointments();
              },
            );
          }),
          const SizedBox(height: 4),
          _buildAddButton(
            label: 'Agregar cita mÃ©dica',
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 10, minute: 0),
                builder: (ctx, child) => _themedPicker(ctx, child),
              );
              if (picked != null) {
                setState(() => _appointments.add(_ApptEntry(weekday: DateTime.monday, time: picked)));
                await _saveAppointments();
              }
            },
          ),
        ],
      ),
    );
  }

  // â”€â”€ Day picker dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<int?> _showDayPicker(int current) {
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('DÃ­a de la cita', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (i) {
            final wd = i + 1;
            final isSelected = current == wd;
            return InkWell(
              onTap: () => Navigator.pop(ctx, wd),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? Theme.of(context).bellotaColors.chilero : Theme.of(context).bellotaColors.textoMedio,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(_days[wd], style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Theme.of(context).bellotaColors.chilero : Theme.of(context).bellotaColors.textoDark,
                    )),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // â”€â”€ Reusable widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildExpandableCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTimeRow({
    required String label,
    required TimeOfDay time,
    required Color iconColor,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.access_time_rounded, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).bellotaColors.textoDark)),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _fmtTime(time),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).bellotaColors.chilero,
                ),
              ),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApptRow({
    required _ApptEntry entry,
    required VoidCallback onTapTime,
    required VoidCallback onTapDay,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF6B9EC7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_outlined, color: Color(0xFF6B9EC7), size: 18),
          ),
          const SizedBox(width: 10),
          // Day chip
          GestureDetector(
            onTap: onTapDay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B9EC7).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _days[entry.weekday],
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B9EC7)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Time chip
          GestureDetector(
            onTap: onTapTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _fmtTime(entry.time),
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).bellotaColors.chilero),
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.remove_circle_outline, color: Colors.red.shade300, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleTimeCard({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return _buildExpandableCard(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).bellotaColors.asuncion.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.access_time_rounded, color: Theme.of(context).bellotaColors.asuncion, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Theme.of(context).bellotaColors.textoDark)),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _fmtTime(time),
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).bellotaColors.chilero),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.06),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Theme.of(context).bellotaColors.chilero, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).bellotaColors.chilero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themedPicker(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: ColorScheme.light(
          primary: Theme.of(context).bellotaColors.chilero,
          onPrimary: Colors.white,
          surface: Colors.white,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).bellotaColors.chilero),
        ),
      ),
      child: child!,
    );
  }

  // â”€â”€ Permission banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildPermissionBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_off_outlined, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificaciones desactivadas',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange.shade900),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bellota necesita permiso para enviarte recordatorios. Toca aquÃ­ para activarlos.',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange.shade800),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _requestPermission,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Activar permisos',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).bellotaColors.textoDark),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
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
                  Text(title,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).bellotaColors.textoDark)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: Theme.of(context).bellotaColors.textoMedio)),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: value && enabled,
                onChanged: enabled ? onChanged : null,
                activeThumbColor: Colors.white,
                activeTrackColor: Theme.of(context).bellotaColors.chilero,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD4C4B0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Modelo de cita semanal temporal (solo UI)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ApptEntry {
  final int weekday;
  final TimeOfDay time;

  const _ApptEntry({required this.weekday, required this.time});
}





