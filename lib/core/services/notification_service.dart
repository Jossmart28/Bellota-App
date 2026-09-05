import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../database/database_helper.dart';
import '../models/notification_models.dart';
import 'cycle_service.dart';

/// IDs únicos para cada tipo de notificación.
/// Píldoras: 100-149 (máximo 50 horarios)
/// Citas médicas: 200-249 (máximo 50 citas)
/// Registro diario: 4
/// Periodo: 1, Ovulación: 2
class NotifId {
  static const int period = 1;
  static const int ovulation = 2;
  static const int dailyLog = 4;
  static const int pillBase = 100;   // 100, 101, 102 …
  static const int apptBase = 200;   // 200, 201, 202 …
}



/// Servicio singleton que gestiona todas las notificaciones locales de Bellota.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Inicialización
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createAndroidChannels();

    _initialized = true;
  }

  Future<void> _createAndroidChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'bellota_cycle',
        'Recordatorios de Ciclo',
        description: 'Avisos de periodo, ovulación y días fértiles',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        ledColor: Color(0xFFD46A63),
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'bellota_pill',
        'Recordatorio de Píldora',
        description: 'Recordatorio diario para tomar la píldora anticonceptiva',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'bellota_log',
        'Registro Diario',
        description: 'Invitación diaria a registrar síntomas',
        importance: Importance.defaultImportance,
        playSound: false,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'bellota_appt',
        'Citas Médicas',
        description: 'Recordatorios de citas ginecológicas',
        importance: Importance.high,
        playSound: true,
      ),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {}

  // ─────────────────────────────────────────────────────────────────────────
  // Permisos
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Programación principal
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> scheduleAllNotifications(int userId) async {
    await _plugin.cancelAll();

    final profile = await DatabaseHelper.instance.getProfile(userId);
    if (profile == null) return;

    final notifApp = (profile['notif_app'] as int? ?? 1) == 1;
    if (!notifApp) return;

    final notifPeriodo = (profile['notif_periodo'] as int? ?? 1) == 1;
    final notifOvulacion = (profile['notif_ovulacion'] as int? ?? 1) == 1;
    final notifPildora = (profile['notif_pildora'] as int? ?? 0) == 1;
    final notifCita = (profile['notif_cita_medica'] as int? ?? 0) == 1;
    final notifLog = (profile['notif_daily_log'] as int? ?? 1) == 1;
    final notifSonidos = (profile['notif_sonidos'] as int? ?? 1) == 1;

    final cycleDuration = profile['cycle_duration'] as int? ?? 28;
    final periodDuration = profile['period_duration'] as int? ?? 5;

    final lastPeriodStart =
        await DatabaseHelper.instance.getLastPeriodStart(userId);

    if (notifPeriodo && lastPeriodStart != null) {
      await _schedulePeriodReminder(
        lastPeriodStart: lastPeriodStart,
        cycleDuration: cycleDuration,
        periodDuration: periodDuration,
        withSound: notifSonidos,
      );
    }

    if (notifOvulacion && lastPeriodStart != null) {
      await _scheduleOvulationReminder(
        lastPeriodStart: lastPeriodStart,
        cycleDuration: cycleDuration,
        periodDuration: periodDuration,
        withSound: notifSonidos,
      );
    }

    if (notifPildora) {
      final rawTimes = await DatabaseHelper.instance.getPillTimes(userId);
      final times = rawTimes
          .map((r) => PillTime(hour: r['hour'] as int, minute: r['minute'] as int))
          .toList();
      for (int i = 0; i < times.length; i++) {
        await _schedulePillReminder(
          id: NotifId.pillBase + i,
          time: times[i],
          withSound: notifSonidos,
        );
      }
    }

    if (notifCita) {
      final rawAppts = await DatabaseHelper.instance.getWeeklyAppointments(userId);
      final appointments = rawAppts
          .map((r) => WeeklyAppointment(
                weekday: r['weekday'] as int,
                hour: r['hour'] as int,
                minute: r['minute'] as int,
              ))
          .toList();
      for (int i = 0; i < appointments.length; i++) {
        await _scheduleWeeklyAppointment(
          id: NotifId.apptBase + i,
          appointment: appointments[i],
          withSound: notifSonidos,
        );
      }
    }

    if (notifLog) {
      final logHour = profile['notif_log_hour'] as int? ?? 21;
      final logMinute = profile['notif_log_minute'] as int? ?? 0;
      await _scheduleDailyLogReminder(
        hour: logHour,
        minute: logMinute,
        withSound: notifSonidos,
      );
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Envía una notificación de prueba inmediata.
  Future<void> sendTestNotification() async {
    await _plugin.show(
      999,
      '🔔 Notificación de prueba',
      '¡Bellota se está comunicando correctamente contigo!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bellota_cycle',
          'Recordatorios de Ciclo',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Notificaciones individuales
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _schedulePeriodReminder({
    required DateTime lastPeriodStart,
    required int cycleDuration,
    required int periodDuration,
    required bool withSound,
  }) async {
    final cycleInfo = CycleService.instance.calculateCycleInfo(
      referenceDate: DateTime.now(),
      lastPeriodStart: lastPeriodStart,
      cycleDuration: cycleDuration,
      periodDuration: periodDuration,
    );

    final nextPeriod = cycleInfo.nextPeriodDate;
    final reminderDate = nextPeriod.subtract(const Duration(days: 3));
    final scheduledDate = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
      0,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      NotifId.period,
      '🌸 Tu periodo se acerca',
      'En 3 días comienza tu siguiente periodo. ¡Prepárate!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'bellota_cycle',
          'Recordatorios de Ciclo',
          channelDescription: 'Avisos de periodo, ovulación y días fértiles',
          importance: Importance.high,
          priority: Priority.high,
          playSound: withSound,
          color: const Color(0xFFD46A63),
          largeIcon:
              const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: withSound,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _scheduleOvulationReminder({
    required DateTime lastPeriodStart,
    required int cycleDuration,
    required int periodDuration,
    required bool withSound,
  }) async {
    final cycleInfo = CycleService.instance.calculateCycleInfo(
      referenceDate: DateTime.now(),
      lastPeriodStart: lastPeriodStart,
      cycleDuration: cycleDuration,
      periodDuration: periodDuration,
    );

    final fertileStart = cycleInfo.fertileWindowStart;
    if (fertileStart == null) return;

    final reminderDate = fertileStart.subtract(const Duration(days: 1));
    final scheduledDate = tz.TZDateTime(
      tz.local,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
      0,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      NotifId.ovulation,
      '🌿 Tus días fértiles se acercan',
      'Mañana comienza tu ventana fértil. Registra cómo te sientes.',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'bellota_cycle',
          'Recordatorios de Ciclo',
          channelDescription: 'Avisos de periodo, ovulación y días fértiles',
          importance: Importance.high,
          priority: Priority.high,
          playSound: withSound,
          color: const Color(0xFFB5C99A),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: withSound,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _schedulePillReminder({
    required int id,
    required PillTime time,
    required bool withSound,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, time.hour, time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      '💊 Hora de tu píldora',
      '¡No olvides tomar tu píldora anticonceptiva a las ${time.label()}!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'bellota_pill',
          'Recordatorio de Píldora',
          channelDescription:
              'Recordatorio diario para tomar la píldora anticonceptiva',
          importance: Importance.high,
          priority: Priority.high,
          playSound: withSound,
          color: const Color(0xFF97B580),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: withSound,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleDailyLogReminder({
    required int hour,
    required int minute,
    required bool withSound,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      NotifId.dailyLog,
      '📓 ¿Cómo te sentiste hoy?',
      'Registra tus síntomas y flujo del día en Bellota.',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'bellota_log',
          'Registro Diario',
          channelDescription: 'Invitación diaria a registrar síntomas',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: withSound,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: withSound,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeeklyAppointment({
    required int id,
    required WeeklyAppointment appointment,
    required bool withSound,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    int daysUntil = appointment.weekday - now.weekday;
    if (daysUntil < 0) daysUntil += 7;
    if (daysUntil == 0) {
      // If today is appointment day, check if the scheduled time has already passed
      final scheduledTime = DateTime(now.year, now.month, now.day, appointment.hour, appointment.minute);
      if (scheduledTime.isBefore(now)) {
        daysUntil = 7; // Already passed today, schedule for next week
      }
    }

    final target = now.add(Duration(days: daysUntil));
    final scheduledDate = tz.TZDateTime(
      tz.local,
      target.year, target.month, target.day,
      appointment.hour, appointment.minute,
    );

    await _plugin.zonedSchedule(
      id,
      '🏥 Recordatorio de cita médica',
      '¿Tienes alguna cita ginecológica pendiente? Revisa tu agenda.',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'bellota_appt',
          'Citas Médicas',
          channelDescription: 'Recordatorios de citas ginecológicas',
          importance: Importance.high,
          priority: Priority.high,
          playSound: withSound,
          color: const Color(0xFF6B9EC7),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: withSound,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
