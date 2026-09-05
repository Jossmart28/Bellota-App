/// Modelo de un horario de píldora
class PillTime {
  final int hour;
  final int minute;

  const PillTime({required this.hour, required this.minute});

  factory PillTime.fromJson(Map<String, dynamic> j) =>
      PillTime(hour: j['h'] as int, minute: j['m'] as int);

  Map<String, dynamic> toJson() => {'h': hour, 'm': minute};

  String label() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Modelo de una cita médica semanal
class WeeklyAppointment {
  /// 1=Lunes … 7=Domingo (conforme DateTime.weekday)
  final int weekday;
  final int hour;
  final int minute;

  const WeeklyAppointment({
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  factory WeeklyAppointment.fromJson(Map<String, dynamic> j) =>
      WeeklyAppointment(
        weekday: j['wd'] as int,
        hour: j['h'] as int,
        minute: j['m'] as int,
      );

  Map<String, dynamic> toJson() => {
        'wd': weekday,
        'h': hour,
        'm': minute,
      };

  String label() {
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final dayStr = (weekday >= 1 && weekday <= 7) ? days[weekday - 1] : '';
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$dayStr $h:$m';
  }
}
