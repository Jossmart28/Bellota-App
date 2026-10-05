import 'dart:io';
void main() {
  final file = File('lib/screens/dashboard_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll('âš\u{00A0}ï¸\u{008F}', '⚠️');
  content = content.replaceAll('âš ï¸', '⚠️');
  file.writeAsStringSync(content);
}