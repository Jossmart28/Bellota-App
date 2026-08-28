/// Claves centralizadas para SharedPreferences.
///
/// Usar siempre estas constantes en lugar de strings literales dispersos
/// para evitar errores tipográficos y facilitar futuras refactorizaciones.
abstract final class AppKeys {
  AppKeys._();

  // ── Sesión ─────────────────────────────────────────────────────────────────
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
}
