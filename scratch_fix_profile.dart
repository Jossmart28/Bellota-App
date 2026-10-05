import 'dart:io';

void main() {
  final file = File('lib/screens/profile_screen.dart');
  final lines = file.readAsLinesSync();
  
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('class _CustomThumbShape')) {
      lines.insert(i, '}');
      break;
    }
  }
  
  file.writeAsStringSync(lines.join('\r\n'));
  print('Added missing closing bracket.');
}
