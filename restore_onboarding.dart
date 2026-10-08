import 'dart:io';

void main() async {
  // Fix birth_year_screen.dart: missing flutter/material.dart + broken relative imports
  final result = await Process.run('git', ['show', 'HEAD:lib/screens/birth_year_screen.dart']);
  if (result.exitCode != 0) { print('git show failed'); return; }
  
  String c = result.stdout as String;
  
  // Fix all old relative/broken imports
  c = c.replaceAll("import '../theme/bellota_colors.dart';", "import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';");
  c = c.replaceAll("import '../widgets/bellota_top_actions.dart';", "import 'package:bellotadevelopment/presentation/widgets/bellota_top_actions.dart';");
  c = c.replaceAll("import 'onboarding_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/onboarding/onboarding_screen.dart';");
  c = c.replaceAll("import 'privacy_policy_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/onboarding/privacy_policy_screen.dart';");
  c = c.replaceAll("import 'login_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/auth/login_screen.dart';");
  c = c.replaceAll("import '../database/database_helper.dart';", "import 'package:bellotadevelopment/core/di/injection_container.dart';");
  c = c.replaceAll("import '../core/di/injection_container.dart';", "import 'package:bellotadevelopment/core/di/injection_container.dart';");
  
  // Ensure flutter/material.dart is present
  if (!c.contains("package:flutter/material.dart")) {
    c = "import 'package:flutter/material.dart';\n" + c;
  }
  
  File('lib/presentation/screens/onboarding/birth_year_screen.dart').writeAsStringSync(c);
  print('birth_year_screen.dart restored cleanly');
  
  // Also fix language_selection_screen.dart, privacy_policy_screen.dart, account_language_screen.dart
  for (final entry in {
    'lib/screens/language_selection_screen.dart': 'lib/presentation/screens/onboarding/language_selection_screen.dart',
    'lib/screens/privacy_policy_screen.dart': 'lib/presentation/screens/onboarding/privacy_policy_screen.dart',
    'lib/screens/account_language_screen.dart': 'lib/presentation/screens/profile/account_language_screen.dart',
  }.entries) {
    final r2 = await Process.run('git', ['show', 'HEAD:${entry.key}']);
    if (r2.exitCode == 0) {
      String f = r2.stdout as String;
      f = f.replaceAll("import '../theme/bellota_colors.dart';", "import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';");
      f = f.replaceAll("import '../widgets/", "import 'package:bellotadevelopment/presentation/widgets/");
      f = f.replaceAll("import '../database/database_helper.dart';", "import 'package:bellotadevelopment/core/di/injection_container.dart';");
      f = f.replaceAll("import '../core/di/injection_container.dart';", "import 'package:bellotadevelopment/core/di/injection_container.dart';");
      f = f.replaceAll("import 'birth_year_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/onboarding/birth_year_screen.dart';");
      f = f.replaceAll("import 'onboarding_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/onboarding/onboarding_screen.dart';");
      f = f.replaceAll("import 'dashboard_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/home/dashboard_screen.dart';");
      f = f.replaceAll("import 'login_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/auth/login_screen.dart';");
      f = f.replaceAll("import '../l10n/", "import 'package:bellotadevelopment/l10n/");
      f = f.replaceAll("import '../core/", "import 'package:bellotadevelopment/core/");
      f = f.replaceAll("import '../domain/", "import 'package:bellotadevelopment/domain/");
      f = f.replaceAll("import '../navigation/", "import 'package:bellotadevelopment/navigation/");
      if (!f.contains("package:flutter/material.dart")) {
        f = "import 'package:flutter/material.dart';\n" + f;
      }
      File(entry.value).writeAsStringSync(f);
      print('Restored ${entry.value}');
    }
  }
}
