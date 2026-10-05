import 'dart:io';

void main() {
  final file = File('lib/screens/personal_data_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceFirst(
      "  String? _selectedContraceptive = 'none';",
      "  bool _usesContraceptive = false;\n  final TextEditingController _contraceptiveTextController = TextEditingController();"
  );
  
  // The first time the replace failed for _saveAndContinue, let's fix it properly using a simpler regex.
  final regexSave = RegExp(r"          'medical_conditions': jsonEncode\(_selectedConditions\),\s*'contraceptive': _selectedContraceptive == 'none' \? null : _selectedContraceptive,");
  final replaceSave = '''
          // The old structure is broken here. Let's fix it by updating the save logic cleanly.
          'medical_conditions': jsonEncode(_selectedConditions),
          'contraceptive': _usesContraceptive && _contraceptiveTextController.text.trim().isNotEmpty ? _contraceptiveTextController.text.trim() : null,''';
  content = content.replaceFirst(regexSave, replaceSave);

  file.writeAsStringSync(content);
}
