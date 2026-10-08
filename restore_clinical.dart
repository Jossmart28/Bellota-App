import 'dart:io';
import 'dart:convert';

void main() async {
  // Restore ClinicalAnalysisService from git (it was designed for Map<String,dynamic>)
  final result = await Process.run('git', ['show', 'HEAD:lib/core/services/clinical_analysis_service.dart']);
  if (result.exitCode != 0) {
    print('Git show failed: ${result.stderr}');
    return;
  }
  
  String c = result.stdout as String;
  
  // Add DI imports
  c = "import 'package:bellotadevelopment/core/di/injection_container.dart';\nimport 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';\nimport 'package:bellotadevelopment/domain/repositories/profile_repository.dart';\n" + c;
  
  // Remove old database import
  c = c.replaceAll("import 'package:bellotadevelopment/database/database_helper.dart';", '');
  
  // Replace ALL DatabaseProvider/DatabaseHelper calls with repository
  // This service uses raw logs (Map), so we use getAllDailyLogsRaw
  c = c.replaceAll('DatabaseProvider.instance.getAllDailyLogsRaw(', 'sl<DailyLogRepository>().getAllDailyLogsRaw(');
  c = c.replaceAll('DatabaseHelper.instance.getAllDailyLogsRaw(', 'sl<DailyLogRepository>().getAllDailyLogsRaw(');
  c = c.replaceAll('DatabaseProvider.instance.getLogsInRange(', 'sl<DailyLogRepository>().getAllDailyLogsRaw('); // fallback to raw
  c = c.replaceAll('DatabaseHelper.instance.getLogsInRange(', 'sl<DailyLogRepository>().getAllDailyLogsRaw(');
  c = c.replaceAll('DatabaseProvider.instance.getProfile(', 'sl<ProfileRepository>().getProfile(');
  c = c.replaceAll('DatabaseHelper.instance.getProfile(', 'sl<ProfileRepository>().getProfile(');
  
  // Handle db variable patterns
  c = c.replaceAll('final db = DatabaseProvider.instance;', '');
  c = c.replaceAll('final db = DatabaseHelper.instance;', '');
  c = c.replaceAll('await db.getAllDailyLogsRaw(', 'await sl<DailyLogRepository>().getAllDailyLogsRaw(');
  c = c.replaceAll('await db.getLogsInRange(', 'await sl<DailyLogRepository>().getAllDailyLogsRaw(');
  c = c.replaceAll('await db.getProfile(', 'await sl<ProfileRepository>().getProfile(');
  
  File('lib/core/services/clinical_analysis_service.dart').writeAsStringSync(c, encoding: utf8);
  print('ClinicalAnalysisService restored and wired to repositories (raw mode).');
}
