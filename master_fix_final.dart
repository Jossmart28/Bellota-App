import 'dart:io';

void main() {
  // 1. Navigation Service
  final navPath = 'lib/navigation/navigation_service.dart';
  final navFile = File(navPath);
  if (navFile.existsSync()) {
    String c = navFile.readAsStringSync();
    if (!c.contains('privacy_policy_screen.dart')) {
      c = "import 'package:bellotadevelopment/presentation/screens/onboarding/privacy_policy_screen.dart';\n" + c;
      c = "import 'package:bellotadevelopment/presentation/screens/onboarding/birth_year_screen.dart';\n" + c;
      c = "import 'package:bellotadevelopment/presentation/screens/onboarding/language_selection_screen.dart';\n" + c;
    }
    navFile.writeAsStringSync(c);
  }

  // 2. Personal Data Screen
  final pdPath = 'lib/presentation/screens/profile/personal_data_screen.dart';
  final pdFile = File(pdPath);
  if (pdFile.existsSync()) {
    String c = pdFile.readAsStringSync();
    if (!c.contains('dashboard_screen.dart')) {
      c = "import 'package:bellotadevelopment/presentation/screens/home/dashboard_screen.dart';\n" + c;
    }
    pdFile.writeAsStringSync(c);
  }

  // 3. Audit Dashboard Screen
  final adPath = 'lib/presentation/screens/admin/audit_dashboard_screen.dart';
  final adFile = File(adPath);
  if (adFile.existsSync()) {
    String c = adFile.readAsStringSync();
    if (!c.contains('login_screen.dart')) {
      c = "import 'package:bellotadevelopment/presentation/screens/auth/login_screen.dart';\n" + c;
    }
    adFile.writeAsStringSync(c);
  }

  // 4. Symptom Log Screen (Imports & Syntax)
  final symPath = 'lib/presentation/screens/health_log/symptom_log_screen.dart';
  final symFile = File(symPath);
  if (symFile.existsSync()) {
    String c = symFile.readAsStringSync();
    if (!c.contains('flujo_vaginal_selection_screen.dart')) {
      c = "import 'package:bellotadevelopment/presentation/screens/health_log/forms/flujo_vaginal_selection_screen.dart';\n" + c;
      c = "import 'package:bellotadevelopment/presentation/screens/health_log/forms/sexo_selection_screen.dart';\n" + c;
      c = "import 'package:bellotadevelopment/presentation/screens/health_log/forms/patron_sangrado_screen.dart';\n" + c;
      c = "import 'package:bellotadevelopment/presentation/screens/health_log/forms/dolor_sintomatologia_screen.dart';\n" + c;
    }
    // Hard string replace for the syntax error
    c = c.replaceAll("        const SizedBox(width: 8),\n        ),\n      ],\n    );", "        const SizedBox(width: 8),\n      ],\n    );");
    c = c.replaceAll("        ),\n      ],\n    );\n  }\n\n  // DATE HEADER", "      ],\n    );\n  }\n\n  // DATE HEADER");
    symFile.writeAsStringSync(c);
  }

  // 5. Calendar Screen
  final calPath = 'lib/presentation/screens/calendar/calendar_screen.dart';
  final calFile = File(calPath);
  if (calFile.existsSync()) {
    String c = calFile.readAsStringSync();
    c = c.replaceAll(
      '(await sl<DailyLogRepository>().getLogsInRange(userId, startRange, endRange)).map((l) => DateTime.parse(l.date)).toList();',
      '(await sl<DailyLogRepository>().getLogsInRange(userId, startRange, endRange)).map((l) => l.date).toSet();'
    );
    calFile.writeAsStringSync(c);
  }

  // 6. Clinical Analysis Service
  final clinPath = 'lib/core/services/clinical_analysis_service.dart';
  final clinFile = File(clinPath);
  if (clinFile.existsSync()) {
    String c = clinFile.readAsStringSync();
    c = c.replaceAll('profile?.contraceptiveMethod', "profile?.contraceptive");
    c = c.replaceAll('await db.getCycleStatistics', 'await sl<DailyLogRepository>().getCycleStatistics');
    c = c.replaceAll('await db.getTopSymptomsForPhase', 'await sl<HealthPredictionService>().getTopSymptomsForPhase');
    clinFile.writeAsStringSync(c);
  }

  print('Master fix applied successfully.');
}
