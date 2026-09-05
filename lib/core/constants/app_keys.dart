/// Claves centralizadas para SharedPreferences.
///
/// Usar siempre estas constantes en lugar de strings literales dispersos
/// para evitar errores tipográficos y facilitar futuras refactorizaciones.
abstract final class AppKeys {
  AppKeys._();

  // â”€â”€ Sesión â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Indica si el usuario está autenticado.
  static const String isLoggedIn = 'isLoggedIn';

  /// Nombre de display del usuario activo.
  static const String userName = 'userName';

  /// Correo electrónico del usuario activo.
  static const String userEmail = 'userEmail';

  /// ID numérico del usuario activo en la base de datos local.
  static const String userId = 'userId';

  // ── Flujo de incorporación ─────────────────────────────────────────────────
  /// El usuario ya completó el onboarding inicial.
  static const String onboardingDone = 'onboarding_done';

  /// El usuario ya completó el tour del calendario.
  static const String calendarTourDone = 'calendar_tour_done';

  /// El usuario ya completó la configuración de datos personales.
  static const String setupCompleted = 'setup_completed';

  // ── Preferencias de UI ─────────────────────────────────────────────────────
  /// Modo oscuro activo (`true`) o claro (`false`).
  static const String darkMode = 'dark_mode';

  /// Código de idioma seleccionado (ej: `'es'`, `'en'`, `'mi'`).
  static const String appLang = 'app_lang';

  // ── Perfil ─────────────────────────────────────────────────────────────────
  /// Ruta local de la imagen de perfil del usuario.
  static const String profileImagePath = 'profileImagePath';

  // ── RBAC (Roles y permisos) ────────────────────────────────────────────────
  /// Rol del usuario activo ('admin', 'usuario', 'auditor').
  static const String userRole = 'userRole';

  /// Indica si la cuenta del usuario está activa.
  static const String isActive = 'isActive';

  /// Indica si el usuario aceptó la política de privacidad.
  static const String privacyPolicyAccepted = 'privacyPolicyAccepted';

  /// Duración del ciclo del usuario.
  static const String cycleDuration = 'cycle_duration';

  /// Departamento del usuario.
  static const String userDepartment = 'user_department';

  /// Municipio del usuario.
  static const String userMunicipality = 'user_municipality';

  /// Edad del usuario.
  static const String userAge = 'user_age';

  /// Ubicaci�n del usuario.
  static const String userLocation = 'user_location';
}


