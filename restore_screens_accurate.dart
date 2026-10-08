import 'dart:io';

void main() async {
  // Restore admin_panel_screen and dashboard_screen without BOM and without squashing lines
  final files = {
    'lib/screens/admin_panel_screen.dart': 'lib/presentation/screens/admin/admin_panel_screen.dart',
    'lib/screens/dashboard_screen.dart': 'lib/presentation/screens/home/dashboard_screen.dart',
  };

  for (final entry in files.entries) {
    final r = await Process.run('git', ['show', 'HEAD:${entry.key}']);
    if (r.exitCode == 0) {
      String content = r.stdout as String;
      
      // Fix imports cleanly
      content = content.replaceAll("import '../core/", "import 'package:bellotadevelopment/core/");
      content = content.replaceAll("import '../domain/", "import 'package:bellotadevelopment/domain/");
      content = content.replaceAll("import '../theme/", "import 'package:bellotadevelopment/presentation/theme/");
      content = content.replaceAll("import '../widgets/bellota_top_actions.dart';", "import 'package:bellotadevelopment/presentation/common/bellota_top_actions.dart';");
      content = content.replaceAll("import '../widgets/cycle_ring_widget.dart';", "import 'package:bellotadevelopment/presentation/widgets/cycle_ring_widget.dart';");
      content = content.replaceAll("import '../widgets/", "import 'package:bellotadevelopment/presentation/widgets/");
      content = content.replaceAll("import '../navigation/", "import 'package:bellotadevelopment/navigation/");
      content = content.replaceAll("import '../database/database_helper.dart';", "import 'package:bellotadevelopment/core/di/injection_container.dart';\nimport 'package:bellotadevelopment/domain/repositories/user_repository.dart';\nimport 'package:bellotadevelopment/domain/repositories/auth_repository.dart';\nimport 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';\nimport 'package:bellotadevelopment/domain/repositories/profile_repository.dart';");
      
      content = content.replaceAll("import 'login_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/auth/login_screen.dart';");
      content = content.replaceAll("import 'audit_dashboard_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/admin/audit_dashboard_screen.dart';");
      content = content.replaceAll("import 'notifications_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/notifications/notifications_screen.dart';");
      content = content.replaceAll("import 'hospital_hub_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/home/hospital_hub_screen.dart';");
      content = content.replaceAll("import 'calendar_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/calendar/calendar_screen.dart';");
      content = content.replaceAll("import 'symptom_log_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/health_log/symptom_log_screen.dart';");
      content = content.replaceAll("import 'profile_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/profile/profile_screen.dart';");
      content = content.replaceAll("import 'resumen_diario_screen.dart';", "import 'package:bellotadevelopment/presentation/screens/health_log/resumen_diario_screen.dart';");

      File(entry.value).writeAsStringSync(content);
      print('Restored \${entry.value} correctly.');
    }
  }
}
