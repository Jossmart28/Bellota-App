import 'dart:io';

void main() {
  final file = File('lib/screens/calendar_screen.dart');
  String content = file.readAsStringSync();
  
  if (!content.contains("package:table_calendar/table_calendar.dart")) {
      content = content.replaceFirst(
        "import 'package:bellotadevelopment/l10n/app_localizations.dart';",
        "import 'package:bellotadevelopment/l10n/app_localizations.dart';\nimport 'package:table_calendar/table_calendar.dart';"
      );
      file.writeAsStringSync(content);
  }
}
