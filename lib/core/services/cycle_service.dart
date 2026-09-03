import 'package:flutter/material.dart';
import '../../theme/bellota_colors.dart';
import '../../l10n/app_translations.dart';

/// Fase del ciclo menstrual.
enum CyclePhase {
  menstrual,    // Días de sangrado
  follicular,   // Post-sangrado hasta pre-ovulación
  ovulatory,    // Ventana de ovulación (~3 días)
  luteal,       // Post-ovulación hasta el siguiente periodo
}

/// Información del ciclo calculada.
class CycleInfo {
  final int cycleDay;
  final CyclePhase phase;
  final DateTime nextPeriodDate;
  final DateTime? ovulationDate;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final int daysUntilNextPeriod;
  final double? averageCycleLength;
  final bool isIrregular;
  final bool hasData;

  CycleInfo({
    required this.cycleDay,
    required this.phase,
    required this.nextPeriodDate,
    this.ovulationDate,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    required this.daysUntilNextPeriod,
    this.averageCycleLength,
    required this.isIrregular,
    required this.hasData,
  });
}

/// Estadísticas del ciclo calculadas a partir del historial.
class CycleStatistics {
  final double averageCycleLength;
  final double? averagePeriodLength;
  final int shortestCycle;
  final int longestCycle;
  final bool isRegular;
  final List<int> cycleLengths;

  CycleStatistics({
    required this.averageCycleLength,
    this.averagePeriodLength,
    required this.shortestCycle,
    required this.longestCycle,
    required this.isRegular,
    required this.cycleLengths,
  });
}

/// Servicio central para el cálculo de fases y estimaciones del ciclo menstrual.
class CycleService {
  CycleService._();
  static final CycleService instance = CycleService._();

  /// Normaliza una fecha a la medianoche para evitar problemas con la zona horaria.
  DateTime _dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Calcula la información del ciclo actual.
  CycleInfo calculateCycleInfo({
    required DateTime referenceDate,
    required DateTime? lastPeriodStart,
    required int cycleDuration,
    required int periodDuration,
    List<DateTime>? allPeriodStarts,
  }) {
    if (lastPeriodStart == null) {
      return CycleInfo(
        cycleDay: 1,
        phase: CyclePhase.menstrual,
        nextPeriodDate: _dateOnly(referenceDate),
        daysUntilNextPeriod: 0,
        isIrregular: false,
        hasData: false,
      );
    }

    final ref = _dateOnly(referenceDate);
    final start = _dateOnly(lastPeriodStart);

    double? avgLength;
    bool irregular = false;
    int effectiveCycleDuration = cycleDuration;

    if (allPeriodStarts != null && allPeriodStarts.length >= 2) {
      // Calcular promedio si hay datos
      List<int> lengths = [];
      List<DateTime> sorted = allPeriodStarts.map((d) => _dateOnly(d)).toList()..sort();
      for (int i = 1; i < sorted.length; i++) {
        lengths.add(sorted[i].difference(sorted[i - 1]).inDays);
      }
      
      avgLength = lengths.map((e) => e.toDouble()).reduce((a, b) => a + b) / lengths.length;
      effectiveCycleDuration = avgLength.round();
      if (effectiveCycleDuration < 15) {
        effectiveCycleDuration = cycleDuration;
      }

      for (int len in lengths) {
        if ((len - avgLength).abs() > 7) {
          irregular = true;
          break;
        }
      }
    }

    // Calcular días pasados desde el último periodo
    int diffDays = ref.difference(start).inDays;
    
    int cycleDay;
    if (diffDays >= 0) {
      cycleDay = (diffDays % effectiveCycleDuration) + 1;
    } else {
      cycleDay = effectiveCycleDuration - ((-diffDays) % effectiveCycleDuration) + 1;
      if (cycleDay > effectiveCycleDuration) cycleDay = 1;
    }

    // Día de ovulación = duración del ciclo - 14
    int ovulationDay = effectiveCycleDuration - 14;
    if (ovulationDay < 1) ovulationDay = effectiveCycleDuration ~/ 2; // fallback para ciclos muy cortos

    // Determinar fase
    CyclePhase phase = _determinePhase(cycleDay, periodDuration, ovulationDay, effectiveCycleDuration);

    // Calcular fechas futuras
    int cyclesPassed = diffDays >= 0 ? diffDays ~/ effectiveCycleDuration : (diffDays - effectiveCycleDuration + 1) ~/ effectiveCycleDuration;
    DateTime currentCycleStart = start.add(Duration(days: cyclesPassed * effectiveCycleDuration));
    
    DateTime nextPeriod = currentCycleStart.add(Duration(days: effectiveCycleDuration));
    DateTime ovulationDate = currentCycleStart.add(Duration(days: ovulationDay - 1));
    
    // Fertile window (6-day window: ovulationDay - 5 to ovulationDay + 1)
    DateTime fertileWindowStart = currentCycleStart.add(Duration(days: ovulationDay - 6));
    DateTime fertileWindowEnd = currentCycleStart.add(Duration(days: ovulationDay));

    int daysUntilNext = nextPeriod.difference(ref).inDays;
    if (daysUntilNext < 0) daysUntilNext = 0;

    return CycleInfo(
      cycleDay: cycleDay,
      phase: phase,
      nextPeriodDate: nextPeriod,
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
      daysUntilNextPeriod: daysUntilNext,
      averageCycleLength: avgLength,
      isIrregular: irregular,
      hasData: true,
    );
  }

  CyclePhase _determinePhase(int cycleDay, int periodDuration, int ovulationDay, int cycleDuration) {
    if (cycleDay >= 1 && cycleDay <= periodDuration) {
      return CyclePhase.menstrual;
    } else if (cycleDay >= ovulationDay - 1 && cycleDay <= ovulationDay + 1) {
      return CyclePhase.ovulatory;
    } else if (cycleDay > periodDuration && cycleDay < ovulationDay - 1) {
      return CyclePhase.follicular;
    } else {
      return CyclePhase.luteal;
    }
  }

  /// Retorna la fase para una fecha dada.
  CyclePhase getPhaseForDate({
    required DateTime date,
    required DateTime lastPeriodStart,
    required int cycleDuration,
    required int periodDuration,
    List<DateTime>? allPeriodStarts,
  }) {
    int effectiveCycleDuration = cycleDuration;

    if (allPeriodStarts != null && allPeriodStarts.length >= 2) {
      List<int> lengths = [];
      List<DateTime> sorted = allPeriodStarts.map((d) => _dateOnly(d)).toList()..sort();
      for (int i = 1; i < sorted.length; i++) {
        lengths.add(sorted[i].difference(sorted[i - 1]).inDays);
      }
      
      double avgLength = lengths.map((e) => e.toDouble()).reduce((a, b) => a + b) / lengths.length;
      effectiveCycleDuration = avgLength.round();
      if (effectiveCycleDuration < 15) {
        effectiveCycleDuration = cycleDuration;
      }
    }

    final d = _dateOnly(date);
    final start = _dateOnly(lastPeriodStart);
    int diffDays = d.difference(start).inDays;
    
    int cycleDay;
    if (diffDays >= 0) {
      cycleDay = (diffDays % effectiveCycleDuration) + 1;
    } else {
      cycleDay = effectiveCycleDuration - ((-diffDays) % effectiveCycleDuration) + 1;
      if (cycleDay > effectiveCycleDuration) cycleDay = 1;
    }

    int ovulationDay = effectiveCycleDuration - 14;
    if (ovulationDay < 1) ovulationDay = effectiveCycleDuration ~/ 2;

    return _determinePhase(cycleDay, periodDuration, ovulationDay, effectiveCycleDuration);
  }

  /// Obtiene el color correspondiente a la fase del ciclo.
  Color getPhaseColor(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return BellotaColors.chilero;
      case CyclePhase.follicular:
        return BellotaColors.chiltoma;
      case CyclePhase.ovulatory:
        return BellotaColors.melon;
      case CyclePhase.luteal:
        return BellotaColors.asuncion;
    }
  }

  /// Retorna el nombre traducido de la fase del ciclo.
  String getPhaseName(CyclePhase phase, String lang) {
    switch (phase) {
      case CyclePhase.menstrual:
        return AppTranslations.get('cycle', 'phase_menstrual', lang);
      case CyclePhase.follicular:
        return AppTranslations.get('cycle', 'phase_follicular', lang);
      case CyclePhase.ovulatory:
        return AppTranslations.get('cycle', 'phase_ovulatory', lang);
      case CyclePhase.luteal:
        return AppTranslations.get('cycle', 'phase_luteal', lang);
    }
  }

  /// Calcula estadísticas históricas del ciclo en base a periodos registrados (ordenados de forma descendente).
  CycleStatistics calculateStatistics(List<DateTime> periodStarts, int configuredCycleDuration) {
    if (periodStarts.isEmpty || periodStarts.length == 1) {
      return CycleStatistics(
        averageCycleLength: configuredCycleDuration.toDouble(),
        shortestCycle: configuredCycleDuration,
        longestCycle: configuredCycleDuration,
        isRegular: true,
        cycleLengths: [],
      );
    }

    // Ordenar de manera ascendente para calcular intervalos correctamente
    List<DateTime> sorted = periodStarts.map((d) => _dateOnly(d)).toList()..sort();
    
    List<int> lengths = [];
    for (int i = 1; i < sorted.length; i++) {
      lengths.add(sorted[i].difference(sorted[i - 1]).inDays);
    }

    int minLen = lengths[0];
    int maxLen = lengths[0];
    double sum = 0;

    for (int len in lengths) {
      if (len < minLen) minLen = len;
      if (len > maxLen) maxLen = len;
      sum += len;
    }

    double avg = sum / lengths.length;
    bool isReg = true;

    for (int len in lengths) {
      if ((len - avg).abs() > 7) {
        isReg = false;
        break;
      }
    }

    // Retorna las duraciones de los ciclos, el más reciente primero para seguir el orden descendente de los periodos
    return CycleStatistics(
      averageCycleLength: avg,
      shortestCycle: minLen,
      longestCycle: maxLen,
      isRegular: isReg,
      cycleLengths: lengths.reversed.toList(), 
    );
  }
}
