import 'dart:io';

void main() {
  final file = File('lib/screens/calendar_screen.dart');
  String content = file.readAsStringSync();

  // Remove the badge call and the Spacer/SizedBox next to it
  final regexBadgeCall = RegExp(r'// ── Cycle Day Badge ──.*?if \(_lastPeriodStart != null\) const SizedBox\(width: 12\),', dotAll: true);
  content = content.replaceFirst(regexBadgeCall, '');

  file.writeAsStringSync(content);
}
