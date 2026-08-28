import 'dart:io';

void main() {
  final dir = Directory('lib');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      // Un poco agresivo, pero quita "const" si la linea tiene BellotaColors
      final lines = content.split('\n');
      bool changed = false;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('BellotaColors') && lines[i].contains('const ')) {
          lines[i] = lines[i].replaceAll('const ', '');
          changed = true;
        }
      }
      if (changed) {
        entity.writeAsStringSync(lines.join('\n'));
      }
    }
  }
}
