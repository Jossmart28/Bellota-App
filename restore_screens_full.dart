import 'dart:io';

void main() async {
  final filesToRestore = {
    'lib/screens/login_screen.dart': 'lib/presentation/screens/auth/login_screen.dart',
    'lib/screens/dashboard_screen.dart': 'lib/presentation/screens/home/dashboard_screen.dart',
    'lib/screens/language_selection_screen.dart': 'lib/presentation/screens/onboarding/language_selection_screen.dart',
    'lib/screens/birth_year_screen.dart': 'lib/presentation/screens/onboarding/birth_year_screen.dart',
    'lib/screens/privacy_policy_screen.dart': 'lib/presentation/screens/onboarding/privacy_policy_screen.dart',
    'lib/screens/account_language_screen.dart': 'lib/presentation/screens/profile/account_language_screen.dart',
    'lib/screens/admin_panel_screen.dart': 'lib/presentation/screens/admin/admin_panel_screen.dart',
  };

  for (final entry in filesToRestore.entries) {
    final oldPath = entry.key;
    final newPath = entry.value;

    final result = await Process.run('git', ['show', 'HEAD:$oldPath']);
    if (result.exitCode == 0) {
      String content = result.stdout as String;
      
      // Basic import migrations
      content = content.replaceAll(
          'package:bellotadevelopment/database/database_helper.dart',
          'package:bellotadevelopment/core/di/injection_container.dart'
      );
      content = content.replaceAll(
          'package:bellotadevelopment/screens/dashboard_screen.dart',
          'package:bellotadevelopment/presentation/screens/home/dashboard_screen.dart'
      );
      content = content.replaceAll(
          'package:bellotadevelopment/screens/login_screen.dart',
          'package:bellotadevelopment/presentation/screens/auth/login_screen.dart'
      );
      content = content.replaceAll(
          'package:bellotadevelopment/screens/',
          'package:bellotadevelopment/presentation/screens/'
      );
      
      // Update the DatabaseProvider to sl
      content = content.replaceAll('DatabaseProvider.instance.', 'sl<UserRepository>().');

      File(newPath).writeAsStringSync(content);
      print('Restored $newPath');
    } else {
      print('Failed to restore $oldPath');
    }
  }

  // Also fix notification_service.dart syntax
  final notifFile = File('lib/core/services/notification_service.dart');
  if (notifFile.existsSync()) {
    String c = notifFile.readAsStringSync();
    c = c.replaceAll("final notifApp = (profile['notif_app'] as int? ?? 1) == 1;", "final notifApp = profile.notifApp;");
    notifFile.writeAsStringSync(c);
    print('Fixed notification_service.dart syntax');
  }

  // Also fix main.dart init()
  final mainFile = File('lib/main.dart');
  if (mainFile.existsSync()) {
    String c = mainFile.readAsStringSync();
    if (!c.contains("package:bellotadevelopment/core/di/injection_container.dart")) {
      c = "import 'package:bellotadevelopment/core/di/injection_container.dart' as di;\n" + c;
    }
    c = c.replaceAll("await initDependencies();", "await di.init();");
    c = c.replaceAll("await init();", "await di.init();");
    mainFile.writeAsStringSync(c);
    print('Fixed main.dart init');
  }
}
