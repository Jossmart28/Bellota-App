import 'dart:io';

void main() {
  final file = File('lib/core/services/cycle_service.dart');
  String content = file.readAsStringSync();

  // Fix logic in getPhaseForDateV2
  final regex1 = RegExp(r'int ovulationDay = cycleDurationToUse - 14;\s+if \(ovulationDay < 1\) ovulationDay = cycleDurationToUse ~/ 2;');
  final replace1 = '''int ovulationDay = cycleDurationToUse - 14;
    if (ovulationDay <= periodDuration + 1) {
      ovulationDay = periodDuration + 2;
    }
    if (ovulationDay > cycleDurationToUse - 2) {
      ovulationDay = cycleDurationToUse - 2;
    }''';
  content = content.replaceFirst(regex1, replace1);

  // Fix logic in getPhaseForDate
  final regex2 = RegExp(r'int ovulationDay = effectiveCycleDuration - 14;\s+if \(ovulationDay < 1\) ovulationDay = effectiveCycleDuration ~/ 2;');
  final replace2 = '''int ovulationDay = effectiveCycleDuration - 14;
    if (ovulationDay <= periodDuration + 1) {
      ovulationDay = periodDuration + 2;
    }
    if (ovulationDay > effectiveCycleDuration - 2) {
      ovulationDay = effectiveCycleDuration - 2;
    }''';
  content = content.replaceFirst(regex2, replace2);
  
  // Fix logic in getCycleInfo
  final regex3 = RegExp(r'int ovulationDay = effectiveCycleDuration - 14;\s+if \(ovulationDay < 1\) ovulationDay = effectiveCycleDuration ~/ 2; // fallback para ciclos muy cortos');
  final replace3 = '''int ovulationDay = effectiveCycleDuration - 14;
    if (ovulationDay <= periodDuration + 1) {
      ovulationDay = periodDuration + 2;
    }
    if (ovulationDay > effectiveCycleDuration - 2) {
      ovulationDay = effectiveCycleDuration - 2;
    }''';
  content = content.replaceFirst(regex3, replace3);

  file.writeAsStringSync(content);
}
