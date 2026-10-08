import 'package:bellotadevelopment/core/errors/app_logger.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bellotadevelopment/core/constants/app_keys.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/domain/repositories/auth_repository.dart';
import 'package:bellotadevelopment/domain/repositories/user_repository.dart';
import 'package:bellotadevelopment/domain/repositories/profile_repository.dart';
import 'package:bellotadevelopment/domain/repositories/audit_repository.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/data/datasources/database_provider.dart';


class UserHealthData {
  final int userId;
  final List<String> recentSymptoms;
  final List<String> medicalConditions;
  final String? contraceptive;
  final List<String> medications;
  
  UserHealthData({
    required this.userId,
    required this.recentSymptoms,
    required this.medicalConditions,
    this.contraceptive,
    required this.medications,
  });
}

class UserHealthProfileService {
  static final UserHealthProfileService instance = UserHealthProfileService._();

  UserHealthProfileService._();

  /// Construye un perfil de salud consolidado del usuario activo.
  /// Lee de SQLite y SharedPreferences para combinar condiciones médicas,
  /// anticonceptivos, síntomas recientes y medicamentos.
  Future<UserHealthData?> getConsolidatedHealthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Obtener userId
    int? userId = prefs.getInt(AppKeys.userId);
    if (userId == null) {
      final email = prefs.getString(AppKeys.userEmail);
      if (email != null) {
        userId = await sl<AuthRepository>().getUserIdByEmail(email);
      }
    }
    
    if (userId == null) return null;

    // 1. Obtener perfil para condiciones médicas y anticonceptivo
    final profile = await sl<ProfileRepository>().getProfile(userId);
    List<String> medicalConditions = [];
    String? contraceptive;
    
    if (profile != null) {
      if (profile.medicalConditions != null) {
        try {
          medicalConditions = profile.medicalConditions ?? [];
        } catch (e) { AppLogger.w('Error ignorado', e); }
      }
      contraceptive = profile.toMap()['contraceptive'] as String?;
    }

    // 2. Obtener síntomas recientes (últimos 14 días)
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    final startDate = '${twoWeeksAgo.year}-${twoWeeksAgo.month.toString().padLeft(2, '0')}-${twoWeeksAgo.day.toString().padLeft(2, '0')}';
    final endDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final recentLogs = await sl<DailyLogRepository>().getLogsInRange(userId, startDate, endDate);
    
    final Set<String> uniqueSymptoms = {};
    for (final log in recentLogs) {
      // Síntomas generales
      if (log.symptoms != null) {
        try {
          final symps = log.symptoms;
          uniqueSymptoms.addAll(symps);
        } catch (e) { AppLogger.w('Error ignorado', e); }
      }
      // Síntomas físicos
      if (log.physicalSymptoms != null) {
        try {
          final phys = log.physicalSymptoms ?? [];
          uniqueSymptoms.addAll(phys);
        } catch (e) { AppLogger.w('Error ignorado', e); }
      }
      // Síntomas emocionales
      if (log.emotionalSymptoms != null) {
        try {
          final emo = log.emotionalSymptoms ?? [];
          uniqueSymptoms.addAll(emo);
        } catch (e) { AppLogger.w('Error ignorado', e); }
      }
      // Anomalías mamarias
      if (log.breastExam != null) {
        final exam = log.breastExam.toString();
        if (exam != 'breast_normal' && exam != 'breast_pending') {
          uniqueSymptoms.add(exam);
        }
      }
    }

    // 3. Obtener medicamentos de SharedPreferences
    final medications = prefs.getStringList('user_medications') ?? [];

    return UserHealthData(
      userId: userId,
      recentSymptoms: uniqueSymptoms.toList(),
      medicalConditions: medicalConditions,
      contraceptive: contraceptive,
      medications: medications,
    );
  }
}
