import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database_helper.dart';
import '../constants/app_keys.dart';

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
        userId = await DatabaseHelper.instance.getUserIdByEmail(email);
      }
    }
    
    if (userId == null) return null;

    // 1. Obtener perfil para condiciones médicas y anticonceptivo
    final profile = await DatabaseHelper.instance.getProfile(userId);
    List<String> medicalConditions = [];
    String? contraceptive;
    
    if (profile != null) {
      if (profile['medical_conditions'] != null) {
        try {
          medicalConditions = List<String>.from(jsonDecode(profile['medical_conditions'].toString()));
        } catch (_) {}
      }
      contraceptive = profile['contraceptive'] as String?;
    }

    // 2. Obtener síntomas recientes (últimos 14 días)
    final now = DateTime.now();
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    final startDate = '${twoWeeksAgo.year}-${twoWeeksAgo.month.toString().padLeft(2, '0')}-${twoWeeksAgo.day.toString().padLeft(2, '0')}';
    final endDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final recentLogs = await DatabaseHelper.instance.getLogsInRange(userId, startDate, endDate);
    
    final Set<String> uniqueSymptoms = {};
    for (final log in recentLogs) {
      // Síntomas generales
      if (log['symptoms'] != null) {
        try {
          final symps = List<String>.from(jsonDecode(log['symptoms'].toString()));
          uniqueSymptoms.addAll(symps);
        } catch (_) {}
      }
      // Síntomas físicos
      if (log['physical_symptoms'] != null) {
        try {
          final phys = List<String>.from(jsonDecode(log['physical_symptoms'].toString()));
          uniqueSymptoms.addAll(phys);
        } catch (_) {}
      }
      // Síntomas emocionales
      if (log['emotional_symptoms'] != null) {
        try {
          final emo = List<String>.from(jsonDecode(log['emotional_symptoms'].toString()));
          uniqueSymptoms.addAll(emo);
        } catch (_) {}
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
