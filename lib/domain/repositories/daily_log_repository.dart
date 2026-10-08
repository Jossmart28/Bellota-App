import 'package:bellotadevelopment/core/models/daily_log_model.dart';

/// Contrato para el acceso a datos de logs diarios y estadísticas de ciclo.
abstract class DailyLogRepository {
  /// Obtiene todos los logs de un usuario ordenados por fecha ASC
  Future<List<DailyLogModel>> getDailyLogs(int userId);

  /// Obtiene un log específico por fecha (formato 'YYYY-MM-DD')
  Future<DailyLogModel?> getDailyLog(int userId, String date);

  /// Inserta o actualiza un log diario (upsert por user_id + date)
  Future<int> saveDailyLog(DailyLogModel log);

  /// Elimina el log de una fecha específica
  Future<int> deleteDailyLog(int userId, String date);

  /// Obtiene todos los logs en un rango de fechas
  Future<List<DailyLogModel>> getLogsInRange(int userId, String startDate, String endDate);

  /// Obtiene todas las fechas en que el periodo empezó, ordenadas DESC
  Future<List<DateTime>> getAllPeriodStartDates(int userId);

  /// Obtiene la fecha del último inicio de periodo
  Future<DateTime?> getLastPeriodStart(int userId);

  /// Obtiene todos los logs como maps crudos (para compatibilidad con servicios legacy)
  Future<List<Map<String, dynamic>>> getAllDailyLogsRaw(int userId);

  /// Obtiene los horarios de pastilla de un usuario
  Future<List<Map<String, dynamic>>> getPillTimes(int userId);

  /// Obtiene las citas semanales de un usuario
  Future<List<Map<String, dynamic>>> getWeeklyAppointments(int userId);

  /// Calcula estadísticas de ciclo: promedio, mínimo, máximo, regularidad
  Future<Map<String, dynamic>> getCycleStatistics(int userId);

  /// Calcula el promedio de días de sangrado real basado en los logs
  Future<double?> getRealBleedingAverage(int userId);

  /// Guarda un log diario completo con todos sus campos (upsert inteligente)
  Future<int> saveDailyLogV2({
    required int userId,
    required String date,
    required bool periodStart,
    bool periodEnd = false,
    required List<String> symptoms,
    required List<String> sexo,
    required List<String> flujo,
    String? bleedingIntensity,
    String? clots,
    bool spotting = false,
    String? spottingDays,
    String? sexualSymptoms,
    double? painLevel,
    String? painCharacter,
    String? painDays,
    String? treatment,
    List<String> physicalSymptoms = const [],
    List<String> emotionalSymptoms = const [],
    String? breastExam,
    String? notes,
    double? basalTemp,
    String? lhTestResult,
    String? cervicalPosition,
    String? mood,
  });

  /// Obtiene horarios de pastilla como maps crudos (para notificaciones)
  Future<List<Map<String, dynamic>>> getPillTimesRaw(int userId);

  /// Obtiene citas semanales como maps crudos (para notificaciones)
  Future<List<Map<String, dynamic>>> getWeeklyAppointmentsRaw(int userId);
}
