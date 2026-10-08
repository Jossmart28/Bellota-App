import 'dart:io';
import 'dart:convert';

void main() async {
  final files = [
    'lib/screens/login_screen.dart',
    'lib/screens/admin_panel_screen.dart',
    'lib/screens/birth_year_screen.dart',
    'lib/screens/language_selection_screen.dart',
    'lib/screens/account_language_screen.dart',
  ];
  
  final targets = [
    'lib/presentation/screens/auth/login_screen.dart',
    'lib/presentation/screens/admin/admin_panel_screen.dart',
    'lib/presentation/screens/onboarding/birth_year_screen.dart',
    'lib/presentation/screens/onboarding/language_selection_screen.dart',
    'lib/presentation/screens/profile/account_language_screen.dart',
  ];

  for (int i = 0; i < files.length; i++) {
    final result = await Process.run('git', ['show', 'HEAD:\${files[i]}']);
    if (result.exitCode == 0) {
      final text = result.stdout as String;
      File(targets[i]).writeAsStringSync(text, encoding: utf8);
    }
  }

  print('Restored flawlessly.');
}
