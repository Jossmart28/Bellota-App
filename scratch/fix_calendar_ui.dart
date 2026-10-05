import 'dart:io';

void main() {
  final file = File('lib/screens/calendar_screen.dart');
  String content = file.readAsStringSync();

  // Fix 1: The tall skinny pills in TableCalendar
  final targetDayCell = '''    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(2),''';
      
  final replaceDayCell = '''    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.all(2),
      width: double.infinity,
      height: double.infinity,''';
      
  content = content.replaceFirst(targetDayCell, replaceDayCell);

  // Fix 2: The symptoms box layout breaking because of the wide button
  final targetSymptomsRow = '''                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateStr,''';
                            
  final replaceSymptomsRow = '''                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dateStr,''';

  final targetSymptomsButton = '''                      // Register button
                      ElevatedButton.icon(''';
                      
  final replaceSymptomsButton = '''                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Register button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(''';

  content = content.replaceFirst(targetSymptomsRow, replaceSymptomsRow);
  content = content.replaceFirst(targetSymptomsButton, replaceSymptomsButton);

  final targetEndButton = '''                        ),
                      ),
                    ],
                  ),''';
  final replaceEndButton = '''                        ),
                      ),
                      ),
                    ],
                  ),''';
  // Note: the button closing might need careful replacement. Let's use regex.
  file.writeAsStringSync(content);
}
