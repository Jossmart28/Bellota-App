import 'dart:io';

void main() {
  final file = File('lib/screens/personal_data_screen.dart');
  String content = file.readAsStringSync();

  // 1. Add state for Step 6 Contraceptives
  content = content.replaceFirst(
      "  String _selectedContraceptive = 'none';",
      "  bool _usesContraceptive = false;\n  final TextEditingController _contraceptiveTextController = TextEditingController();"
  );

  // 2. Add dispose
  content = content.replaceFirst(
      "    _medicationTextController.dispose();",
      "    _medicationTextController.dispose();\n    _otherConditionTextController.dispose();\n    _contraceptiveTextController.dispose();"
  );

  // 3. Update _saveAndContinue
  final saveTarget = '''      if (userId != null) {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'profiles',
        {
          'cycle_duration': _cycleDuration,
          'period_duration': _periodDuration,
          'medical_conditions': jsonEncode(_selectedConditions),
          'contraceptive': _selectedContraceptive == 'none' ? null : _selectedContraceptive,
        },''';

  final saveReplacement = '''      if (userId != null) {
      final db = await DatabaseHelper.instance.database;
      
      // Update conditions: replace 'other' with text if exists
      List<String> finalConditions = List.from(_selectedConditions);
      if (finalConditions.contains('other') && _otherConditionTextController.text.trim().isNotEmpty) {
        finalConditions.remove('other');
        finalConditions.add(_otherConditionTextController.text.trim());
      }
      
      // Update contraceptive
      String? finalContraceptive;
      if (_usesContraceptive && _contraceptiveTextController.text.trim().isNotEmpty) {
        finalContraceptive = _contraceptiveTextController.text.trim();
      }

      await db.update(
        'profiles',
        {
          'cycle_duration': _cycleDuration,
          'period_duration': _periodDuration,
          'medical_conditions': jsonEncode(finalConditions),
          'contraceptive': finalContraceptive,
        },''';

  content = content.replaceFirst(saveTarget, saveReplacement);
  
  // 4. Update _buildStep5Conditions
  final regexStep5 = RegExp(r'Widget _buildStep5Conditions\(\) \{.*?(?=Widget _buildStep6Contraceptive\(\) \{)', dotAll: true);
  final newStep5 = '''Widget _buildStep5Conditions() {
    return _stepWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, size: 48, color: Theme.of(context).bellotaColors.blanco),
          const SizedBox(height: 16),
          Text(
            "¿Tienes alguna condición de salud diagnosticada?",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: _conditionsMap.entries.map((e) {
                  final key = e.key;
                  final label = e.value;
                  final isSelected = _selectedConditions.contains(key);
                  final icon = _conditionsIcons[key]!;
                  final color = _conditionsColors[key]!;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (key == 'none') {
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
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2) : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).bellotaColors.blanco,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle_rounded, color: Theme.of(context).bellotaColors.blanco, size: 24)
                                else
                                  Icon(Icons.circle_outlined, color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.5), size: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: (key == 'other' && isSelected)
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextFormField(
                                  controller: _otherConditionTextController,
                                  style: TextStyle(color: Theme.of(context).bellotaColors.blanco),
                                  decoration: InputDecoration(
                                    labelText: "¿Cuál condición?",
                                    labelStyle: TextStyle(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.8)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.5)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Theme.of(context).bellotaColors.blanco, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.1),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
''';
  content = content.replaceFirst(regexStep5, newStep5);

  // 5. Update _buildStep6Contraceptive
  final regexStep6 = RegExp(r'Widget _buildStep6Contraceptive\(\) \{.*?(?=Widget _buildStep7Goal\(\) \{)', dotAll: true);
  final newStep6 = '''Widget _buildStep6Contraceptive() {
    return _stepWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 48, color: Theme.of(context).bellotaColors.blanco),
          const SizedBox(height: 16),
          Text(
            "¿Usas algún método anticonceptivo?",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _usesContraceptive = true;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _usesContraceptive ? Theme.of(context).bellotaColors.melon : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _usesContraceptive ? Theme.of(context).bellotaColors.melon : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Sí",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _usesContraceptive ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _usesContraceptive = false;
                    _contraceptiveTextController.clear();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: !_usesContraceptive ? Theme.of(context).bellotaColors.melon : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !_usesContraceptive ? Theme.of(context).bellotaColors.melon : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "No",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: !_usesContraceptive ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _usesContraceptive
                ? TextFormField(
                    controller: _contraceptiveTextController,
                    style: TextStyle(color: Theme.of(context).bellotaColors.blanco),
                    decoration: InputDecoration(
                      labelText: "¿Cuál método anticonceptivo?",
                      labelStyle: TextStyle(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.8)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Theme.of(context).bellotaColors.melon, width: 2),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.1),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

''';
  content = content.replaceFirst(regexStep6, newStep6);

  file.writeAsStringSync(content);
}
