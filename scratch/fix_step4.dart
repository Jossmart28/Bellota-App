import 'dart:io';

void main() {
  final file = File('lib/screens/personal_data_screen.dart');
  String content = file.readAsStringSync();

  // 1. Add state for the new Step 4
  final targetState = "  final Set<String> _selectedMedications = {'none'};";
  final replaceState = '''  bool _takesMedication = false;
  final TextEditingController _medicationTextController = TextEditingController();''';
  content = content.replaceFirst(targetState, replaceState);

  // 2. Change how it's saved
  final targetSave = "await prefs.setStringList('user_medications', _selectedMedications.toList());";
  final replaceSave = '''
      List<String> medicationsToSave = [];
      if (_takesMedication && _medicationTextController.text.trim().isNotEmpty) {
        medicationsToSave.add(_medicationTextController.text.trim());
      } else {
        medicationsToSave.add('none');
      }
      await prefs.setStringList('user_medications', medicationsToSave);
  ''';
  content = content.replaceFirst(targetSave, replaceSave);

  // 3. Replace the build method for step 4
  final regexStep4 = RegExp(r'Widget _buildStep4Medications\(\) \{.*?(?=Widget _buildStep5Conditions\(\) \{)', dotAll: true);
  
  final newStep4 = '''Widget _buildStep4Medications() {
    return _stepWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medication_outlined, size: 48, color: Theme.of(context).bellotaColors.blanco),
          const SizedBox(height: 16),
          Text(
            "¿Tomas algún medicamento regularmente?",
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).bellotaColors.blanco),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _takesMedication = true;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _takesMedication ? Theme.of(context).bellotaColors.melon : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _takesMedication ? Theme.of(context).bellotaColors.melon : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Sí",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _takesMedication ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _takesMedication = false;
                    _medicationTextController.clear();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: !_takesMedication ? Theme.of(context).bellotaColors.melon : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !_takesMedication ? Theme.of(context).bellotaColors.melon : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "No",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: !_takesMedication ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.7),
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
            child: _takesMedication
                ? TextFormField(
                    controller: _medicationTextController,
                    style: TextStyle(color: Theme.of(context).bellotaColors.blanco),
                    decoration: InputDecoration(
                      labelText: "¿Cuál(es) medicamento(s)?",
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

  content = content.replaceFirst(regexStep4, newStep4);
  file.writeAsStringSync(content);
}
