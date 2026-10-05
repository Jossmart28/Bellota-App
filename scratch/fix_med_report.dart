import 'dart:io';

void main() {
  final file = File('lib/screens/profile_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceFirst(
      "'anticonceptivos_medicamentos': medications.isNotEmpty ? medications.join(', ') : notSpec,",
      "'anticonceptivos_medicamentos': medications.isEmpty || (medications.length == 1 && medications.first == 'none') ? notSpec : medications.join(', '),"
  );
  file.writeAsStringSync(content);
}
