import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bellotadevelopment/core/constants/app_keys.dart';
import 'package:bellotadevelopment/presentation/screens/home/dashboard_screen.dart';
import 'package:bellotadevelopment/presentation/screens/auth/login_screen.dart';
import 'package:bellotadevelopment/presentation/screens/auth/auth_screen.dart';
import 'package:bellotadevelopment/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:bellotadevelopment/presentation/screens/calendar/calendar_tour_screen.dart';
import 'package:bellotadevelopment/presentation/screens/profile/personal_data_screen.dart';
import 'package:bellotadevelopment/presentation/screens/admin/admin_panel_screen.dart';
import 'package:bellotadevelopment/presentation/screens/admin/audit_dashboard_screen.dart';
import 'package:bellotadevelopment/presentation/screens/onboarding/privacy_policy_screen.dart';
import 'package:bellotadevelopment/presentation/screens/onboarding/birth_year_screen.dart';
import 'package:bellotadevelopment/presentation/screens/profile/account_language_screen.dart';
import 'package:bellotadevelopment/presentation/screens/onboarding/language_selection_screen.dart';

/// Servicio de navegaciÃ³n que centraliza la lÃ³gica de redirecciÃ³n post-login.
///
/// Esta lÃ³gica estaba duplicada en [SplashScreen] y [LoginScreen].
/// Ahora existe en un Ãºnico lugar, eliminando la posibilidad de divergencias.
///
/// Orden de verificaciÃ³n del flujo de incorporaciÃ³n (usuarios estÃ¡ndar):
///
/// Roles especiales omiten el flujo de incorporaciÃ³n:
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

  /// Visor de logs de auditorÃ­a.
  static const String auditLogs = '/audit/logs';


  /// Determina la pantalla correcta para un usuario **autenticado**
  /// segÃºn su rol y progreso en el flujo de incorporaciÃ³n.
  ///
  static Widget resolveHomeScreen(SharedPreferences prefs) {
    final roleStr = prefs.getString(AppKeys.userRole) ?? 'usuario';

    switch (roleStr) {
      case 'admin':
        return AdminPanelScreen();

      case 'auditor':
        return AuditDashboardScreen();

      case 'usuario':
      default:
        final languageSetupDone = prefs.getBool('language_setup_done') ?? false;
        final privacyPolicyAccepted = prefs.getBool('privacy_policy_accepted') ?? false;
        final birthYear = prefs.getInt('birth_year');
        final onboardingDone = prefs.getBool(AppKeys.onboardingDone) ?? false;
        final calendarTourDone = prefs.getBool(AppKeys.calendarTourDone) ?? false;
        final setupCompleted = prefs.getBool(AppKeys.setupCompleted) ?? false;

        if (!languageSetupDone) return LanguageSelectionScreen();
        if (!(prefs.getBool('account_language_done') ?? false)) return AccountLanguageScreen();
        if (!privacyPolicyAccepted) return PrivacyPolicyScreen();
        if (birthYear == null) return BirthYearScreen();
        if (!onboardingDone) return OnboardingScreen();
        if (!calendarTourDone) return CalendarTourScreen();
        if (!setupCompleted) return PersonalDataScreen();
        return DashboardScreen();
    }
  }

  /// Determina la pantalla raÃ­z basÃ¡ndose en si hay sesiÃ³n activa y
  /// configuraciones previas al login.
  ///
  /// Usar en el splash para decidir entre ir a login, idioma o al home del usuario.
  static Widget resolveRootScreen(SharedPreferences prefs) {
    final useBiometrics = prefs.getBool('use_biometrics') ?? false;
    final languageSetupDone = prefs.getBool('language_setup_done') ?? false;
    if (!languageSetupDone) return LanguageSelectionScreen();

    final isLoggedIn = prefs.getBool(AppKeys.isLoggedIn) ?? false;
    if (!isLoggedIn) return LoginScreen();
    
    if (useBiometrics) {
      return AuthScreen(targetScreen: resolveHomeScreen(prefs));
    }
    return resolveHomeScreen(prefs);
  }


  /// Navega a la [screen] reemplazando toda la pila de navegaciÃ³n.
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





