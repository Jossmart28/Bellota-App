import 'dart:io';
import 'dart:convert';

void main() async {
  // Fix ALL screens with BOM + relative imports
  final screens = {
    'lib/screens/birth_year_screen.dart': 'lib/presentation/screens/onboarding/birth_year_screen.dart',
    'lib/screens/privacy_policy_screen.dart': 'lib/presentation/screens/onboarding/privacy_policy_screen.dart',
    'lib/screens/language_selection_screen.dart': 'lib/presentation/screens/onboarding/language_selection_screen.dart',
    'lib/screens/account_language_screen.dart': 'lib/presentation/screens/profile/account_language_screen.dart',
    'lib/screens/login_screen.dart': 'lib/presentation/screens/auth/login_screen.dart',
    'lib/screens/dashboard_screen.dart': 'lib/presentation/screens/home/dashboard_screen.dart',
    'lib/screens/flujo_vaginal_selection_screen.dart': 'lib/presentation/screens/health_log/flujo_vaginal_selection_screen.dart',
    'lib/screens/sexo_selection_screen.dart': 'lib/presentation/screens/health_log/sexo_selection_screen.dart',
    'lib/screens/patron_sangrado_screen.dart': 'lib/presentation/screens/health_log/patron_sangrado_screen.dart',
    'lib/screens/dolor_sintomatologia_screen.dart': 'lib/presentation/screens/health_log/dolor_sintomatologia_screen.dart',
  };

  for (final e in screens.entries) {
    final r = await Process.run('git', ['show', 'HEAD:${e.key}']);
    if (r.exitCode != 0) { print('Cannot restore ${e.key}'); continue; }

    // Decode stdout bytes directly to remove BOM
    List<int> bytes;
    if (r.stdout is String) {
      bytes = utf8.encode(r.stdout as String);
    } else {
      bytes = r.stdout as List<int>;
    }
    // Remove UTF-8 BOM if present
    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      bytes = bytes.sublist(3);
    }
    String c = utf8.decode(bytes, allowMalformed: true);

    // Fix all relative imports
    c = c.replaceAll("import '../theme/bellota_colors.dart';", "import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';");
    c = c.replaceAll("import '../l10n/language_notifier.dart';", "import 'package:bellotadevelopment/l10n/language_notifier.dart';");
    c = c.replaceAll("import '../l10n/app_localizations.dart';", "import 'package:bellotadevelopment/l10n/app_localizations.dart';");
    c = c.replaceAll("import '../widgets/bellota_top_actions.dart';", "import 'package:bellotadevelopment/presentation/widgets/bellota_top_actions.dart';");
    c = c.replaceAll("import '../widgets/", "import 'package:bellotadevelopment/presentation/widgets/");
    c = c.replaceAll("import '../database/database_helper.dart';", "import 'package:bellotadevelopment/core/di/injection_container.dart';");
    c = c.replaceAll("import '../core/di/injection_container.dart';", "import 'package:bellotadevelopment/core/di/injection_container.dart';");
    c = c.replaceAll("import '../core/", "import 'package:bellotadevelopment/core/");
    c = c.replaceAll("import '../domain/", "import 'package:bellotadevelopment/domain/");
    c = c.replaceAll("import '../navigation/", "import 'package:bellotadevelopment/navigation/");
    c = c.replaceAll("import '../services/", "import 'package:bellotadevelopment/core/services/");
    c = c.replaceAll("import 'login_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/auth/login_screen.dart';");
    c = c.replaceAll("import 'dashboard_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/home/dashboard_screen.dart';");
    c = c.replaceAll("import 'onboarding_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/onboarding/onboarding_screen.dart';");
    c = c.replaceAll("import 'birth_year_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/onboarding/birth_year_screen.dart';");
    c = c.replaceAll("import 'privacy_policy_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/onboarding/privacy_policy_screen.dart';");
    c = c.replaceAll("import 'flujo_vaginal_selection_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/health_log/flujo_vaginal_selection_screen.dart';");
    c = c.replaceAll("import 'sexo_selection_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/health_log/sexo_selection_screen.dart';");
    c = c.replaceAll("import 'patron_sangrado_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/health_log/patron_sangrado_screen.dart';");
    c = c.replaceAll("import 'dolor_sintomatologia_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/health_log/dolor_sintomatologia_screen.dart';");
    c = c.replaceAll("import 'symptom_log_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/health_log/symptom_log_screen.dart';");
    c = c.replaceAll("import 'audit_dashboard_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/admin/audit_dashboard_screen.dart';");
    
    // Ensure flutter/material.dart (write clean, no BOM)
    if (!c.contains("package:flutter/material.dart")) {
      c = "import 'package:flutter/material.dart';\n" + c;
    }

    // Write WITHOUT BOM
    File(e.value).writeAsStringSync(c, encoding: utf8);
    print('Restored (no BOM): ${e.value}');
  }
}
