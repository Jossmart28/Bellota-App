import 'dart:io';

void main() {
  final dir = Directory('lib');
  final regex = RegExp(r'(?<!static\s)(?<!static\s+)const\s+');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      // Also protect `const BellotaApp` in main? Not strictly needed, runApp(BellotaApp()) works.
      content = content.replaceAll(regex, '');
      entity.writeAsStringSync(content);
    }
  }
}
