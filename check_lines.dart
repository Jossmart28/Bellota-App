import 'dart:io';

void main() {
  final f = File('lib/presentation/screens/home/dashboard_screen.dart');
  final lines = f.readAsStringSync().split('\n');
  for (int i = 833; i < 843 && i < lines.length; i++) {
    print('${i+1}: ${lines[i]}');
  }
}
