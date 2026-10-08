import 'dart:io';

void main() {
  final files = [
    'lib/presentation/screens/auth/login_screen.dart',
    'lib/presentation/screens/admin/admin_panel_screen.dart',
    'lib/presentation/screens/onboarding/birth_year_screen.dart',
    'lib/presentation/screens/onboarding/language_selection_screen.dart',
    'lib/presentation/screens/profile/account_language_screen.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    String c = file.readAsStringSync();
    
    // Fix imports
    c = c.replaceAll('package:bellotadevelopment/screens/', 'package:bellotadevelopment/presentation/screens/');
    c = c.replaceAll('package:bellotadevelopment/widgets/', 'package:bellotadevelopment/presentation/common/');
    c = c.replaceAll('package:bellotadevelopment/theme/', 'package:bellotadevelopment/presentation/theme/');
    
    // Remove old DB helper import
    c = c.replaceAll("import 'package:bellotadevelopment/database/database_helper.dart';", "");
    
    // Add common new imports
    c = "import 'package:bellotadevelopment/core/di/injection_container.dart';\n" + c;
    c = "import 'package:bellotadevelopment/domain/repositories/user_repository.dart';\n" + c;
    c = "import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';\n" + c;
    
    // Specific fixes per file
    if (path.contains('login_screen')) {
      c = "import 'package:bellotadevelopment/core/services/auth_service.dart';\n" + c;
      c = c.replaceAll('DatabaseHelper.instance.login', 'AuthService().login');
      c = c.replaceAll('DatabaseProvider.instance.login', 'AuthService().login');
    }
    
    if (path.contains('admin_panel_screen')) {
      c = c.replaceAll('List<Map<String, dynamic>> _users = [];', 'List<dynamic> _users = [];');
      c = c.replaceAll('DatabaseHelper.instance.getAllUsers()', 'sl<UserRepository>().getAllUsers()');
    }
    
    if (path.contains('account_language_screen')) {
      c = "import 'package:bellotadevelopment/navigation/navigation_service.dart';\n" + c;
      c = "import 'package:bellotadevelopment/core/constants/app_keys.dart';\n" + c;
      c = "import 'package:bellotadevelopment/l10n/language_notifier.dart';\n" + c;
      c = c.replaceAll('DatabaseHelper.instance.updateLanguagePref(userId, lang)', 'sl<UserRepository>().updateUserLanguage(userId!, lang)');
    }
    
    if (path.contains('language_selection_screen')) {
      c = "import 'package:bellotadevelopment/navigation/navigation_service.dart';\n" + c;
      c = "import 'package:bellotadevelopment/l10n/language_notifier.dart';\n" + c;
    }

    if (path.contains('birth_year_screen')) {
      c = "import 'package:bellotadevelopment/presentation/common/bellota_top_actions.dart';\n" + c;
    }
    
    file.writeAsStringSync(c);
  }

  // Also fix audit_dashboard_screen.dart LoginScreen const issue
  final auditPath = 'lib/presentation/screens/admin/audit_dashboard_screen.dart';
  final auditFile = File(auditPath);
  if (auditFile.existsSync()) {
    String c = auditFile.readAsStringSync();
    c = c.replaceAll('const LoginScreen()', 'LoginScreen()');
    auditFile.writeAsStringSync(c);
  }

  print('Master fix applied.');
}
