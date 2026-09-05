/// Claves centralizadas para SharedPreferences.
///
/// Usar siempre estas constantes en lugar de strings literales dispersos
/// para evitar errores tipogrÃƒÂ¡ficos y facilitar futuras refactorizaciones.
abstract final class AppKeys {
  AppKeys._();

  // Ã¢â€â‚¬Ã¢â€â‚¬ SesiÃƒÂ³n Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  /// Indica si el usuario estÃƒÂ¡ autenticado.
  static const String isLoggedIn = 'isLoggedIn';

  /// Nombre de display del usuario activo.
  static const String userName = 'userName';

  /// Correo electrÃ³nico del usuario activo.
  static const String userEmail = 'userEmail';

  /// ID numÃ©rico del usuario activo en la base de datos local.
  static const String userId = 'userId';

  // â”€â”€ Flujo de incorporaciÃ³n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// El usuario ya completÃ³ el onboarding inicial.
  static const String onboardingDone = 'onboarding_done';

  /// El usuario ya completÃ³ el tour del calendario.
  static const String calendarTourDone = 'calendar_tour_done';

  /// El usuario ya completÃ³ la configuraciÃ³n de datos personales.
  static const String setupCompleted = 'setup_completed';

  // â”€â”€ Preferencias de UI â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Modo oscuro activo (`true`) o claro (`false`).
  static const String darkMode = 'dark_mode';

  /// CÃ³digo de idioma seleccionado (ej: `'es'`, `'en'`, `'mi'`).
  static const String appLang = 'app_lang';

  // â”€â”€ Perfil â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Ruta local de la imagen de perfil del usuario.
  static const String profileImagePath = 'profileImagePath';

  // â”€â”€ RBAC (Roles y permisos) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Rol del usuario activo ('admin', 'usuario', 'auditor').
  static const String userRole = 'userRole';

  /// Indica si la cuenta del usuario estÃ¡ activa.
  static const String isActive = 'isActive';

  /// Indica si el usuario aceptÃ³ la polÃ­tica de privacidad.
  static const String privacyPolicyAccepted = 'privacyPolicyAccepted';

  /// DuraciÃ³n del ciclo del usuario.
  static const String cycleDuration = 'cycle_duration';

  /// Departamento del usuario.
  static const String userDepartment = 'user_department';

  /// Municipio del usuario.
  static const String userMunicipality = 'user_municipality';

  /// Edad del usuario.
  static const String userAge = 'user_age';

  /// Ubicación del usuario.
  static const String userLocation = 'user_location';
}


