import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_keys.dart';
import '../core/models/user_role.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/calendar_tour_screen.dart';
import '../screens/personal_data_screen.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/audit_dashboard_screen.dart';
import '../screens/privacy_policy_screen.dart';

/// Servicio de navegaciÃƒÂ³n que centraliza la lÃƒÂ³gica de redirecciÃƒÂ³n post-login.
///
/// Esta lÃƒÂ³gica estaba duplicada en [SplashScreen] y [LoginScreen].
/// Ahora existe en un ÃƒÂºnico lugar, eliminando la posibilidad de divergencias.
///
/// Orden de verificaciÃƒÂ³n del flujo de incorporaciÃƒÂ³n (usuarios estÃƒÂ¡ndar):
/// 1. Ã‚Â¿CompletÃƒÂ³ el onboarding? Ã¢â€ â€™ [OnboardingScreen]
/// 2. Ã‚Â¿CompletÃƒÂ³ el tour del calendario? Ã¢â€ â€™ [CalendarTourScreen]
/// 3. Ã‚Â¿CompletÃƒÂ³ los datos personales? Ã¢â€ â€™ [PersonalDataScreen]
/// 4. Todos completados Ã¢â€ â€™ [DashboardScreen]
///
/// Roles especiales omiten el flujo de incorporaciÃƒÂ³n:
/// - [UserRole.admin] Ã¢â€ â€™ [AdminPanelScreen] (panel de gestiÃƒÂ³n)
/// - [UserRole.auditor] Ã¢â€ â€™ [AuditDashboardScreen] (dashboard de auditorÃƒÂ­a)
abstract final class NavigationService {
  NavigationService._();

  // Ã¢â€â‚¬Ã¢â€â‚¬ Rutas con nombre Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String calendarTour = '/calendar-tour';
  static const String personalData = '/personal-data';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String calendar = '/calendar';
  static const String map = '/map';
  static const String symptomLog = '/symptom-log';

  // Ã¢â€â‚¬Ã¢â€â‚¬ Rutas RBAC Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬
  /// Pantalla principal del administrador.
  static const String adminPanel = '/admin';

  /// Dashboard principal del auditor.
  static const String auditDashboard = '/audit';

  /// Visor de logs de auditorÃƒÂ­a.
  static const String auditLogs = '/audit/logs';

  // Ã¢â€â‚¬Ã¢â€â‚¬ ResoluciÃƒÂ³n de pantalla inicial Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  /// Determina la pantalla correcta para un usuario **autenticado**
  /// segÃƒÂºn su rol y progreso en el flujo de incorporaciÃƒÂ³n.
  ///
  /// - Admin Ã¢â€ â€™ [AdminPanelScreen] (omite onboarding)
  /// - Auditor Ã¢â€ â€™ [AuditDashboardScreen] (omite onboarding)
  /// - Usuario Ã¢â€ â€™ flujo de incorporaciÃƒÂ³n Ã¢â€ â€™ [DashboardScreen]
  static Widget resolveHomeScreen(SharedPreferences prefs) {
    final roleStr = prefs.getString(AppKeys.userRole) ?? 'usuario';

    switch (roleStr) {
      case 'admin':
        return const AdminPanelScreen();

      case 'auditor':
        return const AuditDashboardScreen();

      case 'usuario':
      default:
        final onboardingDone = prefs.getBool(AppKeys.onboardingDone) ?? false;
        final calendarTourDone = prefs.getBool(AppKeys.calendarTourDone) ?? false;
        final setupCompleted = prefs.getBool(AppKeys.setupCompleted) ?? false;
        final privacyPolicyAccepted = prefs.getBool('privacy_policy_accepted') ?? false;

        if (!privacyPolicyAccepted) return const PrivacyPolicyScreen();
        if (!onboardingDone) return const OnboardingScreen();
        if (!calendarTourDone) return const CalendarTourScreen();
        if (!setupCompleted) return const PersonalDataScreen();
        return const DashboardScreen();
    }
  }

  /// Determina la pantalla raÃƒÂ­z basÃƒÂ¡ndose en si hay sesiÃƒÂ³n activa.
  ///
  /// Usar en el splash para decidir entre ir a login o al home del usuario.
  static Widget resolveRootScreen(SharedPreferences prefs) {
    final isLoggedIn = prefs.getBool(AppKeys.isLoggedIn) ?? false;
    if (!isLoggedIn) return const LoginScreen();
    return resolveHomeScreen(prefs);
  }

  // Ã¢â€â‚¬Ã¢â€â‚¬ Helpers de navegaciÃƒÂ³n Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  /// Navega a la [screen] reemplazando toda la pila de navegaciÃƒÂ³n.
  static void goAndClearStack(BuildContext context, Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  /// Navega a la [screen] reemplazando solo la pantalla actual.
  static void goReplace(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Navega hacia adelante, apilando sobre la pantalla actual.
  static void goTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}


