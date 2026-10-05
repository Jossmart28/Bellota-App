import 'dart:io';

void main() {
  final file = File('lib/screens/calendar_screen.dart');
  String content = file.readAsStringSync();

  // 1. Remove Cycle Day Badge (Yellow circle)
  // Search for the cycle day badge in _buildHeader
  final regexBadge = RegExp(r'// Cycle day badge\s+if \(_allPeriodStarts\.isNotEmpty\)\s+_buildCycleDayBadge\(\),', dotAll: true);
  content = content.replaceFirst(regexBadge, '');

  // 2. Remove isPeriodStart visual styling (Green circles)
  final regexPeriodStartRing = RegExp(r'// Period start ring\s+if \(isPeriodStart\)\s+Positioned\.fill\(\s+child: Container\(\s+decoration: BoxDecoration\(\s+borderRadius: BorderRadius\.circular\(12\),\s+border: Border\.all\(\s+color: Colors\.white\.withValues\(alpha: 0\.85\), width: 2\),\s+\),\s+\),\s+\),', dotAll: true);
  content = content.replaceFirst(regexPeriodStartRing, '');

  final regexPeriodStartDot = RegExp(r'if \(isPeriodStart\) \.\.\.\[\s+const SizedBox\(height: 2\),\s+Container\(\s+width: 4,\s+height: 4,\s+decoration: const BoxDecoration\(\s+color: Colors\.white,\s+shape: BoxShape\.circle,\s+\),\s+\),\s+\] else if \(hasLog\) \.\.\.\[', dotAll: true);
  content = content.replaceFirst(regexPeriodStartDot, 'if (hasLog) ...[');

  // 3. Remove "No hay registros..." text (Red circle)
  final regexEmptyState = RegExp(r'!hasData\s+\?\s+Row\(\s+children: \[\s+Icon\(Icons\.info_outline_rounded,\s+color: colors\.textoMedio, size: 18\),\s+const SizedBox\(width: 8\),\s+Text\(\s+AppLocalizations\.of\(context\)!\s+\.symptomsAndActionsNoEntriesDay,\s+style: TextStyle\(color: colors\.textoMedio\)\),\s+\],\s+\)\s+:\s+Column\(', dotAll: true);
  content = content.replaceFirst(regexEmptyState, '!hasData\n                      ? const SizedBox.shrink()\n                      : Column(');

  file.writeAsStringSync(content);
}
