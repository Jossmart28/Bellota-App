import 'dart:io';

void main() {
  final result = Process.runSync('dart', ['analyze']);
  final lines = result.stdout.toString().split('\n');
  final exp = RegExp(r'error - (.*?):(\d+):(\d+) - Invalid constant value');
  
  Map<String, List<int>> fileToLines = {};
  for (final line in lines) {
    final match = exp.firstMatch(line);
    if (match != null) {
      final file = match.group(1)!.trim();
      final lineNum = int.parse(match.group(2)!);
      fileToLines.putIfAbsent('lib\\$file', () => []).add(lineNum);
    }
  }

  for (final file in fileToLines.keys) {
    final f = File(file);
    if (!f.existsSync()) continue;
    final content = f.readAsLinesSync();
    
    for (final lineNum in fileToLines[file]!) {
      // Look at the line and a few lines above for 'const' and remove it
      for (int i = lineNum - 1; i >= 0 && i >= lineNum - 5; i--) {
        if (content[i].contains('const ')) {
          content[i] = content[i].replaceAll('const ', '');
          break; // only remove the closest const
        }
      }
    }
    f.writeAsStringSync(content.join('\n'));
  }
}
