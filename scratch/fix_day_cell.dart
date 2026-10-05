import 'dart:io';

void main() {
  final file = File('lib/screens/calendar_screen.dart');
  String content = file.readAsStringSync();

  final targetDayCell = '''        margin: _currentView == CalendarViewType.weekly ? EdgeInsets.symmetric(horizontal: 3) : EdgeInsets.zero,
        width: _currentView == CalendarViewType.weekly ? 40 : null,
        height: _currentView == CalendarViewType.weekly ? 60 : null,''';

  final replaceDayCell = '''        margin: const EdgeInsets.all(4),''';

  content = content.replaceAll(targetDayCell, replaceDayCell);
  
  // TableCalendar uses `day` exactly at 00:00:00 UTC, so it's clean.
  
  file.writeAsStringSync(content);
}
