/// Modelo tipado para el perfil extendido del usuario.
///
/// Encapsula los datos de la tabla `profiles` con tipos nativos de Dart
/// (ej: `bool` para notificaciones en lugar de `int 0/1` de SQLite).
class ProfileModel {
  final int userId;
  final String username;
  final String gmail;
  final int cycleDuration;
  final int periodDuration;
  final String? profileImagePath;

  // ── Notificaciones ─────────────────────────────────────────────────────────
  final bool notifPeriodo;
  final bool notifOvulacion;
  final bool notifPildora;
  final bool notifHidratacion;
  final bool notifEjercicio;
  final bool notifApp;
  final bool notifSonidos;
  final bool notifCitaMedica;

  const ProfileModel({
    required this.userId,
    required this.username,
    this.gmail = '',
    this.cycleDuration = 28,
    this.periodDuration = 5,
    this.profileImagePath,
    this.notifPeriodo = true,
    this.notifOvulacion = true,
    this.notifPildora = false,
    this.notifHidratacion = false,
    this.notifEjercicio = false,
    this.notifApp = true,
    this.notifSonidos = true,
    this.notifCitaMedica = false,
  });

  // ── Deserialización ────────────────────────────────────────────────────────

  /// Crea un [ProfileModel] a partir de un mapa de SQLite.
  /// Los campos de notificación se convierten de `int` (`0`/`1`) a `bool`.
  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      userId: map['user_id'] as int,
      username: map['username'] as String? ?? 'UsuarioApp',
      gmail: map['gmail'] as String? ?? '',
      cycleDuration: map['cycle_duration'] as int? ?? 28,
      periodDuration: map['period_duration'] as int? ?? 5,
      profileImagePath: map['profile_image_path'] as String?,
      notifPeriodo: (map['notif_periodo'] as int? ?? 1) == 1,
      notifOvulacion: (map['notif_ovulacion'] as int? ?? 1) == 1,
      notifPildora: (map['notif_pildora'] as int? ?? 0) == 1,
      notifHidratacion: (map['notif_hidratacion'] as int? ?? 0) == 1,
      notifEjercicio: (map['notif_ejercicio'] as int? ?? 0) == 1,
      notifApp: (map['notif_app'] as int? ?? 1) == 1,
      notifSonidos: (map['notif_sonidos'] as int? ?? 1) == 1,
      notifCitaMedica: (map['notif_cita_medica'] as int? ?? 0) == 1,
    );
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  /// Convierte el modelo a un mapa compatible con SQLite.
  /// Los `bool` se convierten a `int` (`0`/`1`) para compatibilidad.
  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'username': username,
        'gmail': gmail,
        'cycle_duration': cycleDuration,
        'period_duration': periodDuration,
        'profile_image_path': profileImagePath,
        'notif_periodo': notifPeriodo ? 1 : 0,
        'notif_ovulacion': notifOvulacion ? 1 : 0,
        'notif_pildora': notifPildora ? 1 : 0,
        'notif_hidratacion': notifHidratacion ? 1 : 0,
        'notif_ejercicio': notifEjercicio ? 1 : 0,
        'notif_app': notifApp ? 1 : 0,
        'notif_sonidos': notifSonidos ? 1 : 0,
        'notif_cita_medica': notifCitaMedica ? 1 : 0,
      };

  // ── Copia con modificaciones ───────────────────────────────────────────────

  /// Retorna una copia del perfil con los campos especificados modificados.
  ProfileModel copyWith({
    String? username,
    String? gmail,
    int? cycleDuration,
    int? periodDuration,
    String? profileImagePath,
    bool? notifPeriodo,
    bool? notifOvulacion,
    bool? notifPildora,
    bool? notifHidratacion,
    bool? notifEjercicio,
    bool? notifApp,
    bool? notifSonidos,
    bool? notifCitaMedica,
  }) {
    return ProfileModel(
      userId: userId,
      username: username ?? this.username,
      gmail: gmail ?? this.gmail,
      cycleDuration: cycleDuration ?? this.cycleDuration,
      periodDuration: periodDuration ?? this.periodDuration,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      notifPeriodo: notifPeriodo ?? this.notifPeriodo,
      notifOvulacion: notifOvulacion ?? this.notifOvulacion,
      notifPildora: notifPildora ?? this.notifPildora,
      notifHidratacion: notifHidratacion ?? this.notifHidratacion,
      notifEjercicio: notifEjercicio ?? this.notifEjercicio,
      notifApp: notifApp ?? this.notifApp,
      notifSonidos: notifSonidos ?? this.notifSonidos,
      notifCitaMedica: notifCitaMedica ?? this.notifCitaMedica,
    );
  }

  @override
  String toString() =>
      'ProfileModel(userId: $userId, username: $username, cycle: $cycleDuration d)';
}

