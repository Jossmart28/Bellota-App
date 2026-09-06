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

/// Servicio de navegación que centraliza la lógica de redirección post-login.
///
/// Esta lógica estaba duplicada en [SplashScreen] y [LoginScreen].
/// Ahora existe en un único lugar, eliminando la posibilidad de divergencias.
///
/// Orden de verificación del flujo de incorporación (usuarios estándar):
///
/// Roles especiales omiten el flujo de incorporación:
abstract final class NavigationService {
  NavigationService._();

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

  /// Pantalla principal del administrador.
  static const String adminPanel = '/admin';

  /// Dashboard principal del auditor.
  static const String auditDashboard = '/audit';

  /// Visor de logs de auditoría.
  static const String auditLogs = '/audit/logs';


  /// Determina la pantalla correcta para un usuario **autenticado**
  /// según su rol y progreso en el flujo de incorporación.
  ///
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

  /// Determina la pantalla raíz basándose en si hay sesión activa.
  ///
  /// Usar en el splash para decidir entre ir a login o al home del usuario.
  static Widget resolveRootScreen(SharedPreferences prefs) {
    final isLoggedIn = prefs.getBool(AppKeys.isLoggedIn) ?? false;
    if (!isLoggedIn) return const LoginScreen();
    return resolveHomeScreen(prefs);
  }


  /// Navega a la [screen] reemplazando toda la pila de navegación.
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


