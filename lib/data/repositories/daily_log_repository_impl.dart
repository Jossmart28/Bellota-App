import 'dart:convert';
import 'dart:math';
import 'package:bellotadevelopment/core/models/daily_log_model.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/data/datasources/database_provider.dart';

class DailyLogRepositoryImpl implements DailyLogRepository {
  final DatabaseProvider _dbProvider;

  DailyLogRepositoryImpl(this._dbProvider);

  // ── CRUD básico ────────────────────────────────────────────────────────────

  @override
  Future<List<DailyLogModel>> getDailyLogs(int userId) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'daily_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
    return result.map((e) => DailyLogModel.fromMap(e)).toList();
  }

  @override
  Future<DailyLogModel?> getDailyLog(int userId, String date) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
    if (result.isNotEmpty) return DailyLogModel.fromMap(result.first);
    return null;
  }

  @override
  Future<int> saveDailyLog(DailyLogModel log) async {
    final db = await _dbProvider.database;
    final map = log.toMap();
    map.remove('id');
    final existing = await getDailyLog(log.userId, log.date);
    if (existing != null) {
      return await db.update(
        'daily_logs', map,
        where: 'user_id = ? AND date = ?',
        whereArgs: [log.userId, log.date],
      );
    } else {
      return await db.insert('daily_logs', map);
    }
  }

  @override
  Future<int> deleteDailyLog(int userId, String date) async {
    final db = await _dbProvider.database;
    return await db.delete(
      'daily_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
  }

  // ── Consultas especializadas ───────────────────────────────────────────────

  @override
  Future<List<DailyLogModel>> getLogsInRange(
      int userId, String startDate, String endDate) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date ASC',
    );
    return result.map((e) => DailyLogModel.fromMap(e)).toList();
  }

  @override
  Future<List<DateTime>> getAllPeriodStartDates(int userId) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'daily_logs',
      columns: ['date'],
      where: 'user_id = ? AND period_start = 1',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result.map((row) => DateTime.parse(row['date'] as String)).toList();
  }

  @override
  Future<DateTime?> getLastPeriodStart(int userId) async {
    final dates = await getAllPeriodStartDates(userId);
    return dates.isNotEmpty ? dates.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getAllDailyLogsRaw(int userId) async {
    final db = await _dbProvider.database;
    return await db.query(
      'daily_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPillTimes(int userId) async {
    final db = await _dbProvider.database;
    return await db.query(
      'pill_times',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'hour ASC, minute ASC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyAppointments(int userId) async {
    final db = await _dbProvider.database;
    return await db.query(
      'weekly_appointments',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'weekday ASC, hour ASC',
    );
  }

  // ── Estadísticas de ciclo ─────────────────────────────────────────────────

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<Map<String, dynamic>> getCycleStatistics(int userId) async {
    final starts = await getAllPeriodStartDates(userId);
    final empty = {
      'averageCycleLength': null,
      'shortestCycle': null,
      'longestCycle': null,
      'cycleLengths': <int>[],
      'isRegular': true,
      'count': starts.length,
    };

    if (starts.length < 2) return empty;

    final sorted = starts.reversed.toList();
    final List<int> cycleLengths = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final diff =
          _dateOnly(sorted[i + 1]).difference(_dateOnly(sorted[i])).inDays;
      // Solo ciclos razonables (≤ 90 días para evitar datos erróneos)
      if (diff > 0 && diff <= 90) cycleLengths.add(diff);
    }

    if (cycleLengths.isEmpty) return empty;

    final sum = cycleLengths.reduce((a, b) => a + b);
    final avg = sum / cycleLengths.length;
    final minCycle = cycleLengths.reduce(min);
    final maxCycle = cycleLengths.reduce(max);

    return {
      'averageCycleLength': avg,
      'shortestCycle': minCycle,
      'longestCycle': maxCycle,
      'cycleLengths': cycleLengths,
      'isRegular': (maxCycle - minCycle) <= 7,
      'count': starts.length,
    };
  }

  @override
  Future<double?> getRealBleedingAverage(int userId) async {
    final logs = await getDailyLogs(userId);
    if (logs.isEmpty) return null;

    final List<int> bleedingDurations = [];
    int currentDuration = 0;

    for (final log in logs) {
      final isBleeding = log.periodStart == 1 ||
          (log.bleedingIntensity != null && log.bleedingIntensity != 'none');
      if (isBleeding) {
        currentDuration++;
      } else if (currentDuration > 0) {
        bleedingDurations.add(currentDuration);
        currentDuration = 0;
      }
    }
    if (currentDuration > 0) bleedingDurations.add(currentDuration);

    if (bleedingDurations.isEmpty) return null;
    return bleedingDurations.reduce((a, b) => a + b) / bleedingDurations.length;
  }

  @override
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
  }) async {
    final db = await _dbProvider.database;

    bool isEmptyString(String? s) => s == null || s.trim().isEmpty || s == 'null';
    final isEmptyLog = !periodStart && !periodEnd &&
        symptoms.isEmpty && sexo.isEmpty && flujo.isEmpty &&
        isEmptyString(bleedingIntensity) && isEmptyString(clots) && !spotting &&
        isEmptyString(spottingDays) && isEmptyString(sexualSymptoms) &&
        (painLevel == null || painLevel == 0) && isEmptyString(painCharacter) &&
        isEmptyString(painDays) && isEmptyString(treatment) &&
        physicalSymptoms.isEmpty && emotionalSymptoms.isEmpty &&
        isEmptyString(breastExam) && isEmptyString(notes) &&
        basalTemp == null && isEmptyString(lhTestResult) &&
        isEmptyString(cervicalPosition) && isEmptyString(mood);

    final existing = await db.query(
      'daily_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    if (isEmptyLog) {
      if (existing.isNotEmpty) {
        return await db.delete('daily_logs',
            where: 'user_id = ? AND date = ?', whereArgs: [userId, date]);
      }
      return 0;
    }

    final data = {
      'user_id': userId,
      'date': date,
      'period_start': periodStart ? 1 : 0,
      'period_end': periodEnd ? 1 : 0,
      'symptoms': jsonEncode(symptoms),
      'sexo': jsonEncode(sexo),
      'flujo': jsonEncode(flujo),
      'bleeding_intensity': bleedingIntensity,
      'clots': clots,
      'spotting': spotting ? 1 : 0,
      'spotting_days': spottingDays,
      'sexual_symptoms': sexualSymptoms,
      'pain_level': painLevel,
      'pain_character': painCharacter,
      'pain_days': painDays,
      'treatment': treatment,
      'physical_symptoms': jsonEncode(physicalSymptoms),
      'emotional_symptoms': jsonEncode(emotionalSymptoms),
      'breast_exam': breastExam,
      'notes': notes,
      'basal_temp': basalTemp,
      'lh_test_result': lhTestResult,
      'cervical_position': cervicalPosition,
      'mood': mood,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      // Remover created_at en updates para preservar la fecha original
      data.remove('created_at');
      return await db.update('daily_logs', data,
          where: 'user_id = ? AND date = ?', whereArgs: [userId, date]);
    } else {
      return await db.insert('daily_logs', data);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPillTimesRaw(int userId) async {
    final db = await _dbProvider.database;
    return await db.query(
      'pill_times',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'hour ASC, minute ASC',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getWeeklyAppointmentsRaw(int userId) async {
    final db = await _dbProvider.database;
    return await db.query(
      'weekly_appointments',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'weekday ASC, hour ASC',
    );
  }
}

