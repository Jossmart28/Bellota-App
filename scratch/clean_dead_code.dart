import 'dart:io';

void main() {
  final file = File('lib/screens/calendar_screen.dart');
  String content = file.readAsStringSync();

  final regexWeekly = RegExp(r'Widget _buildWeeklyView\(\) \{.*?\}\s*Widget _buildMonthlySwipeable\(\)', dotAll: true);
  content = content.replaceFirst(regexWeekly, 'Widget _buildMonthlySwipeable()');

  final regexMonthly = RegExp(r'Widget _buildMonthlySwipeable\(\) \{.*?\}\s*Widget _buildAnnualView\(\)', dotAll: true);
  content = content.replaceFirst(regexMonthly, 'Widget _buildAnnualView()');

  file.writeAsStringSync(content);
}
