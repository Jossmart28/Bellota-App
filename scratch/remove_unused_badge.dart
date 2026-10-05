import 'dart:io';

void main() {
  final file = File('lib/screens/calendar_screen.dart');
  String content = file.readAsStringSync();
  
  // Remove _buildCycleDayBadge entirely
  final regexMethod = RegExp(r'Widget _buildCycleDayBadge\(BellotaColors colors\) \{.*?return SlideTransition\(\s+position: _badgeSlide.*?\}\);.*?\}\s+', dotAll: true);
  content = content.replaceFirst(regexMethod, '');

  file.writeAsStringSync(content);
}
