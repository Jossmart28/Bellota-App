import 'dart:io';

void main() {
  final file = File('lib/core/services/cycle_service.dart');
  String content = file.readAsStringSync();

  if (!content.contains('getPhaseForDateV2')) {
    final target = '''  /// Retorna la fase para una fecha dada asumiendo que ya se calculó la duración efectiva.
  CyclePhase getPhaseForDate({''';
    final replace = '''  CyclePhase getPhaseForDateV2({
    required DateTime date,
    required List<DateTime> allPeriodStarts,
    required int defaultCycleDuration,
    required int periodDuration,
  }) {
    if (allPeriodStarts.isEmpty) {
      return CyclePhase.luteal;
    }
    
    final d = _dateOnly(date);
    List<DateTime> sortedStarts = allPeriodStarts.map((dt) => _dateOnly(dt)).toList()..sort();
    
    DateTime? applicableStart;
    DateTime? nextStart;
    
    for (int i = 0; i < sortedStarts.length; i++) {
      if (sortedStarts[i].isBefore(d) || sortedStarts[i].isAtSameMomentAs(d)) {
        applicableStart = sortedStarts[i];
        if (i + 1 < sortedStarts.length) {
          nextStart = sortedStarts[i + 1];
        } else {
          nextStart = null;
        }
      } else {
        break;
      }
    }
    
    int cycleDurationToUse;
    
    if (applicableStart != null) {
      if (nextStart != null) {
        cycleDurationToUse = nextStart.difference(applicableStart).inDays;
      } else {
        cycleDurationToUse = getEffectiveCycleDuration(defaultCycleDuration, allPeriodStarts);
      }
    } else {
      applicableStart = sortedStarts.first;
      cycleDurationToUse = getEffectiveCycleDuration(defaultCycleDuration, allPeriodStarts);
    }
    
    int diffDays = d.difference(applicableStart).inDays;
    
    int cycleDay;
    if (diffDays >= 0) {
      cycleDay = (diffDays % cycleDurationToUse) + 1;
    } else {
      cycleDay = cycleDurationToUse - ((-diffDays) % cycleDurationToUse) + 1;
      if (cycleDay > cycleDurationToUse) cycleDay = 1;
    }

    int ovulationDay = cycleDurationToUse - 14;
    if (ovulationDay < 1) ovulationDay = cycleDurationToUse ~/ 2;

    return _determinePhase(cycleDay, periodDuration, ovulationDay, cycleDurationToUse);
  }

  /// Retorna la fase para una fecha dada asumiendo que ya se calculó la duración efectiva.
  CyclePhase getPhaseForDate({''';
    
    content = content.replaceFirst(target, replace);
    file.writeAsStringSync(content);
  }
}
