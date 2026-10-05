import 'dart:io';

void main() {
  final file = File('lib/screens/personal_data_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceFirst(
      "    _pageController.dispose();",
      "    _pageController.dispose();\n    _medicationTextController.dispose();"
  );
  file.writeAsStringSync(content);
}
