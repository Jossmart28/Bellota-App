import 'dart:io';
void main() {
  final content = File('lib/screens/dashboard_screen.dart').readAsStringSync();
  final index = content.indexOf('Predicciones pueden variar por PCOS');
  if (index != -1) {
    print(content.substring(index - 20, index + 40));
  }
}