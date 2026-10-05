import 'dart:io';

void main() {
  final file = File('lib/core/services/cycle_service.dart');
  String content = file.readAsStringSync();
  
  final regexFallback = RegExp(r'if \(ovulationDay < 1\) ovulationDay = effectiveCycleDuration ~/ 2; // fallback para ciclos muy cortos');
  final replaceFallback = '''if (ovulationDay <= periodDuration + 1) {
      ovulationDay = periodDuration + 2;
    }
    if (ovulationDay > effectiveCycleDuration - 2) {
      ovulationDay = effectiveCycleDuration - 2;
    }''';
  content = content.replaceFirst(regexFallback, replaceFallback);

  file.writeAsStringSync(content);
}
