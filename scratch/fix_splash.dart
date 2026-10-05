import 'dart:io';

void main() {
  final file = File('lib/screens/splash_screen.dart');
  String content = file.readAsStringSync();

  if (!content.contains('database_helper.dart')) {
    content = content.replaceFirst(
      "import '../theme/bellota_colors.dart';",
      "import '../theme/bellota_colors.dart';\nimport '../database/database_helper.dart';\nimport '../core/services/auth_service.dart';\nimport '../core/constants/app_keys.dart';"
    );
  }

  final target = '''    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(''';

  final replace = '''    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      
      final isLoggedIn = prefs.getBool(AppKeys.isLoggedIn) ?? false;
      final setupCompleted = prefs.getBool(AppKeys.setupCompleted) ?? false;
      
      if (isLoggedIn && !setupCompleted) {
        // Interrupted registration! Delete the user and log out.
        final email = prefs.getString(AppKeys.userEmail);
        if (email != null) {
          try {
            final uid = await DatabaseHelper.instance.getUserIdByEmail(email);
            if (uid != null) {
              final db = await DatabaseHelper.instance.database;
              await db.delete('users', where: 'id = ?', whereArgs: [uid]);
              await db.delete('profiles', where: 'user_id = ?', whereArgs: [uid]);
            }
          } catch (_) {}
        }
        await AuthService.instance.logout();
        await prefs.setBool('show_aborted_registration_msg', true);
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(''';

  content = content.replaceFirst(target, replace);
  file.writeAsStringSync(content);
}
