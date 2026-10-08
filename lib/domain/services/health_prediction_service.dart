import 'dart:convert';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/domain/repositories/profile_repository.dart';

class HealthPredictionService {
  final DailyLogRepository _dailyLogRepository = sl<DailyLogRepository>();
  final ProfileRepository _profileRepository = sl<ProfileRepository>();

  Future<List<String>> getTopSymptomsForPhase(int userId, String phaseName, {int limit = 3}) async {
    final allLogs = await _dailyLogRepository.getDailyLogs(userId);
    final logsWithSymptoms = allLogs.where((log) => log.symptoms != null && log.symptoms != '[]').toList();
    
    if (logsWithSymptoms.isEmpty) {
      return ['mood_swings', 'sensitivity', 'fatigue'];
    }

    final periodStarts = await _dailyLogRepository.getAllPeriodStartDates(userId);
    if (periodStarts.isEmpty) {
      return ['mood_swings', 'sensitivity', 'fatigue'];
    }

    final profile = await _profileRepository.getProfile(userId);
    final cycleStats = await _dailyLogRepository.getCycleStatistics(userId);

    int defaultCycle = profile?.cycleDuration as int? ?? 28;
    int effectiveCycle = (cycleStats['averageCycleLength'] as num?)?.round() ?? defaultCycle;

    Map<String, int> symptomCounts = {};

    for (var log in logsWithSymptoms) {
      final date = DateTime.parse(log.date);

      DateTime? applicablePeriodStart;
      for (var pStart in periodStarts) {
        if (pStart.isBefore(date) || pStart.isAtSameMomentAs(date)) {
          applicablePeriodStart = pStart;
          break;
        }
      }

      if (applicablePeriodStart == null) continue;

      int diffDays = date.difference(applicablePeriodStart).inDays;
      int cycleDay = diffDays + 1;

      String computedPhase = 'menstrual';
      if (cycleDay > 5 && cycleDay <= 12) {
        computedPhase = 'follicular';
      } else if (cycleDay > 12 && cycleDay <= 16) {
        computedPhase = 'ovulatory';
      } else if (cycleDay > 16 && cycleDay <= effectiveCycle) {
        computedPhase = 'luteal';
      }

      if (computedPhase == phaseName) {
        try {
          final symps = log.symptoms!;
          for (var s in symps) {
            final str = s.toString();
            symptomCounts[str] = (symptomCounts[str] ?? 0) + 1;
          }
        } catch (_) {}
      }
    }

    if (symptomCounts.isEmpty) {
      return ['mood_swings', 'sensitivity', 'fatigue'];
    }

    final entries = symptomCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }

  void _addSymptomFrequency(Map<String, int> freq, List<String>? value) {
    if (value == null || value.isEmpty) return;
    for (var item in value) {
      final s = item.toString();
      if (s.isNotEmpty) {
        freq[s] = (freq[s] ?? 0) + 1;
      }
    }
  }

  Future<List<String>> getPredictedSymptomsV2(
    int userId,
    String phaseName,
    List<String> medicalConditions,
    String? contraceptive, {
    int limit = 5,
  }) async {
    final phaseSymptoms = await getTopSymptomsForPhase(userId, phaseName, limit: 10);
    
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    String format(DateTime d) => "\${d.year}-\${d.month.toString().padLeft(2, '0')}-\${d.day.toString().padLeft(2, '0')}";
    
    final recentLogs = await _dailyLogRepository.getLogsInRange(userId, format(sevenDaysAgo), format(now));
    
    Map<String, int> recentFrequency = {};
    for (var log in recentLogs) {
      _addSymptomFrequency(recentFrequency, log.symptoms);
      _addSymptomFrequency(recentFrequency, log.physicalSymptoms);
      _addSymptomFrequency(recentFrequency, log.emotionalSymptoms);
      _addSymptomFrequency(recentFrequency, log.flujo);
      _addSymptomFrequency(recentFrequency, log.sexo);
    }
    
    Map<String, double> scores = {};
    
    for (int i = 0; i < phaseSymptoms.length; i++) {
      final symptom = phaseSymptoms[i];
      scores[symptom] = (scores[symptom] ?? 0) + (10.0 - i);
    }
    
    for (var entry in recentFrequency.entries) {
      final symptom = entry.key;
      final freq = entry.value;
      scores[symptom] = (scores[symptom] ?? 0) + (freq * 3.0);
    }
    
    final Map<String, List<String>> conditionSymptoms = {
      'pcos': ['mood_swings', 'acne', 'bloating', 'spotting', 'water_retention'],
      'endometriosis': ['pelvic_pain', 'lower_back_pain', 'bloating', 'pain_during_sex', 'extreme_fatigue'],
      'hypothyroidism': ['extreme_fatigue', 'water_retention', 'mood_swings', 'constipation', 'insomnia'],
    };
    
    for (var condition in medicalConditions) {
      final expected = conditionSymptoms[condition];
      if (expected != null) {
        for (var symptom in expected) {
          scores[symptom] = (scores[symptom] ?? 0) + 2.0;
        }
      }
    }
    
    if (contraceptive != null && contraceptive != 'none') {
      final hormonalMethods = ['combined_pill', 'mini_pill', 'hormonal_iud', 'implant', 'ring', 'patch', 'injection'];
      if (hormonalMethods.contains(contraceptive)) {
        for (var symptom in ['headache', 'nausea', 'mood_swings', 'breast_tenderness']) {
          scores[symptom] = (scores[symptom] ?? 0) + 1.5;
        }
      }
    }
    
    scores.remove('sensitivity');
    scores.remove('fatigue');
    
    final sorted = (scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
    return sorted.take(limit).map((e) => e.key).toList();
  }
}
