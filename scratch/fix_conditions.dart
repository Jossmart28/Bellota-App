import 'dart:io';

void main() {
  final file = File('lib/screens/personal_data_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceFirst(
    "final List<String> _selectedConditions = ['none'];",
    "final List<String> _selectedConditions = ['none'];\n  final TextEditingController _otherConditionTextController = TextEditingController();"
  );

  final saveTarget = '''      int? userId = prefs.getInt(AppKeys.userId);
      if (userId != null) {
        final db = await DatabaseHelper.instance.database;
        await db.update(
          'profiles',
          {
            'cycle_duration': _cycleDuration,
            'period_duration': _periodDuration,
            'medical_conditions': jsonEncode(_selectedConditions),''';

  final saveReplace = '''      int? userId = prefs.getInt(AppKeys.userId);
      if (userId != null) {
        final db = await DatabaseHelper.instance.database;
        List<String> finalConditions = List.from(_selectedConditions);
        if (finalConditions.contains('other') && _otherConditionTextController.text.trim().isNotEmpty) {
          finalConditions.remove('other');
          finalConditions.add(_otherConditionTextController.text.trim());
        } else if (finalConditions.contains('other')) {
          finalConditions.remove('other');
          if (finalConditions.isEmpty) finalConditions.add('none');
        }

        await db.update(
          'profiles',
          {
            'cycle_duration': _cycleDuration,
            'period_duration': _periodDuration,
            'medical_conditions': jsonEncode(finalConditions),''';

  content = content.replaceFirst(saveTarget, saveReplace);

  final step5Target = '''                          if (key == 'none') {
                            _selectedConditions.clear();
                            _selectedConditions.add('none');
                          } else {
                            _selectedConditions.remove('none');
                            if (isSelected) {
                              _selectedConditions.remove(key);
                              if (_selectedConditions.isEmpty) _selectedConditions.add('none');
                            } else {
                              _selectedConditions.add(key);
                            }
                          }''';

  final step5Replace = '''                          if (key == 'none') {
                            _selectedConditions.clear();
                            _selectedConditions.add('none');
                            _otherConditionTextController.clear();
                          } else {
                            _selectedConditions.remove('none');
                            if (isSelected) {
                              _selectedConditions.remove(key);
                              if (key == 'other') _otherConditionTextController.clear();
                              if (_selectedConditions.isEmpty) _selectedConditions.add('none');
                            } else {
                              _selectedConditions.add(key);
                            }
                          }''';

  content = content.replaceFirst(step5Target, step5Replace);

  final buildStep5EndTarget = '''                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }''';

  final buildStep5EndReplace = '''                }).toList(),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _selectedConditions.contains('other')
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextFormField(
                      controller: _otherConditionTextController,
                      style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoDark),
                      decoration: InputDecoration(
                        hintText: "¿Cuál condición?",
                        hintStyle: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoMedio),
                        filled: true,
                        fillColor: Theme.of(context).bellotaColors.blanco,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }''';

  int index = content.indexOf('Widget _buildStep5Conditions()');
  String before = content.substring(0, index);
  String after = content.substring(index);
  
  after = after.replaceFirst(buildStep5EndTarget, buildStep5EndReplace);
  
  file.writeAsStringSync(before + after);
}
