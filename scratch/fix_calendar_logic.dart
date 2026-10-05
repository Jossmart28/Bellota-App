import 'dart:io';

void main() {
  final file = File('lib/screens/calendar_screen.dart');
  String content = file.readAsStringSync();

  final targetPhase = '''    final phase = CycleService.instance.getPhaseForDate(
      date: date,
      lastPeriodStart: _lastPeriodStart!,
      effectiveCycleDuration: _effectiveCycleDuration,
      periodDuration: _periodDuration,
    );''';

  final replacePhase = '''    final phase = CycleService.instance.getPhaseForDateV2(
      date: date,
      allPeriodStarts: _allPeriodStarts,
      defaultCycleDuration: _cycleDuration, // Fallback si no hay data suficiente
      periodDuration: _periodDuration,
    );''';

  content = content.replaceFirst(targetPhase, replacePhase);
  file.writeAsStringSync(content);
}
