import 'dart:convert';
import 'package:bellotadevelopment/core/models/daily_log_model.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/core/errors/app_logger.dart';

class HealthReportService {
  final DailyLogRepository _dailyLogRepository = sl<DailyLogRepository>();

  /// Procesa los datos médicos para el reporte
  Future<Map<String, dynamic>> computeMedicalReportData(int userId) async {
    try {
      final allLogs = await _dailyLogRepository.getDailyLogs(userId);
      final lastPeriod = await _dailyLogRepository.getLastPeriodStart(userId);
      final cycleStats = await _dailyLogRepository.getCycleStatistics(userId);
      
      final promCiclo = cycleStats['averageCycleLength'] as double? ?? 28.0;

      Map<String, int> flujoCount = {};
      final endOfCycle = lastPeriod?.add(Duration(days: promCiclo.toInt()));
      
      for (final log in allLogs) {
        if (lastPeriod != null && endOfCycle != null) {
          try {
            final d = DateTime.parse(log.date);
            if (d.isAfter(lastPeriod.subtract(Duration(days: 1))) && d.isBefore(endOfCycle.add(Duration(days: 1)))) {
              final flujoStr = log.flujo;
              if (flujoStr != null) {
              final flujos = log.flujo ?? [];
                for (final f in flujos) {
                  flujoCount[f.toString()] = (flujoCount[f.toString()] ?? 0) + 1;
                }
              }
            }
          } catch (e) { AppLogger.w('Error parsing log date in computeMedicalReportData', e); }
        }
      }
      
      final flujoMasFrecuente = flujoCount.isNotEmpty
          ? flujoCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key
          : null;

      Map<String, int> sympCount = {};
      for (final log in allLogs) {
        if (log.symptoms != null) {
          final symps = log.symptoms!;
          for (final s in symps) {
            sympCount[s.toString()] = (sympCount[s.toString()] ?? 0) + 1;
          }
        }
      }
      final topSyms = (sympCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).map((e) => e.key).toList();

      Map<String, dynamic> patron = {};
      Map<String, dynamic> dolor = {};

      for (final log in allLogs.reversed) {
        if (patron.isEmpty && log.bleedingIntensity != null) {
          patron = {
            'intensidadFlujo': log.bleedingIntensity,
            'coagulos': log.clots,
            'manchado': log.spotting == true,
            'manchadoDias': log.spottingDays,
            'sintomasSexuales': log.sexualSymptoms,
          };
        }
        if (dolor.isEmpty && log.painLevel != null) {
          List phys = log.physicalSymptoms ?? [];
          List emo = log.emotionalSymptoms ?? [];

          dolor = {
            'nivelDolor': log.painLevel,
            'caracterDolor': log.painCharacter,
            'diasDolor': log.painDays,
            'tratamiento': log.treatment,
            'autoexamenMama': log.breastExam,
            'sintomasFisicos': phys,
            'sintomasEmocionales': emo,
          };
        }
        if (patron.isNotEmpty && dolor.isNotEmpty) break;
      }

      return {
        'flujoMasFrecuente': flujoMasFrecuente,
        'sintomasFrecuentes': topSyms,
        'patronSangrado': patron,
        'sintomatologia': dolor,
      };
    } catch (e) {
      AppLogger.e('Error en HealthReportService: $e');
      return {};
    }
  }
}
