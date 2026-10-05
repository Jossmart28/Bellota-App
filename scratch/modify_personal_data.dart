import 'dart:io';

void main() {
  final file = File('lib/screens/personal_data_screen.dart');
  var content = file.readAsStringSync();

  // 1. State Variables for Medications
  final newMedState = """
  // Step 4: Medicamentos
  bool? _takesMedication;
  final TextEditingController _medicationTextController = TextEditingController();
""";
  content = content.replaceFirst(
    RegExp(r"// Step 4: Medicamentos\s*final List<String> _medications = AppTranslations\.medicationKeys;\s*final Set<String> _selectedMedications = \{'none'\};"),
    newMedState,
  );

  // 2. State Variables for Contraceptives
  final newContraState = """
  // Step 6: Método anticonceptivo
  bool? _usesContraceptive;
  final TextEditingController _contraceptiveTextController = TextEditingController();
""";
  content = content.replaceFirst(
    RegExp(r"// Step 6: MÃ©todo anticonceptivo.*?final Map<String, IconData> _contraceptivesIcons = \{.*?\};", dotAll: true),
    newContraState,
  );
  content = content.replaceFirst(
    RegExp(r"// Step 6: Método anticonceptivo.*?final Map<String, IconData> _contraceptivesIcons = \{.*?\};", dotAll: true),
    newContraState,
  );

  // 3. Save Logic Medications
  content = content.replaceFirst(
    "await prefs.setStringList('user_medications', _selectedMedications.toList());",
    "await prefs.setStringList('user_medications', _takesMedication == true && _medicationTextController.text.trim().isNotEmpty ? [_medicationTextController.text.trim()] : ['none']);",
  );

  // 4. Save Logic Contraceptives
  content = content.replaceFirst(
    "'contraceptive': _selectedContraceptive == 'none' ? null : _selectedContraceptive,",
    "'contraceptive': _usesContraceptive == true && _contraceptiveTextController.text.trim().isNotEmpty ? _contraceptiveTextController.text.trim() : null,",
  );

  // 5. UI for Medications
  final medUi = """
  Widget _buildStep4Medications() {
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _takesMedication = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _takesMedication == true ? Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2) : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _takesMedication == true ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2),
                        width: _takesMedication == true ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Sí",
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).bellotaColors.blanco,
                        fontWeight: _takesMedication == true ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 16,
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
                      color: _takesMedication == false ? Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2) : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _takesMedication == false ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2),
                        width: _takesMedication == false ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "No",
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).bellotaColors.blanco,
                        fontWeight: _takesMedication == false ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 16,
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
            child: _takesMedication == true
                ? TextFormField(
                    controller: _medicationTextController,
                    style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoDark),
                    decoration: InputDecoration(
                      hintText: "¿Cuáles?",
                      hintStyle: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoMedio),
                      filled: true,
                      fillColor: Theme.of(context).bellotaColors.blanco,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
""";
  content = content.replaceFirst(
    RegExp(r"Widget _buildStep4Medications\(\)\s*\{.*?\}(?=\s*Widget _buildStep5Conditions)", dotAll: true),
    medUi,
  );

  // 6. UI for Contraceptives
  final contraUi = """
  Widget _buildStep6Contraceptive() {
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _usesContraceptive = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _usesContraceptive == true ? Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2) : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _usesContraceptive == true ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2),
                        width: _usesContraceptive == true ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Sí",
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).bellotaColors.blanco,
                        fontWeight: _usesContraceptive == true ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 16,
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
                      color: _usesContraceptive == false ? Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2) : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _usesContraceptive == false ? Theme.of(context).bellotaColors.blanco : Theme.of(context).bellotaColors.blanco.withValues(alpha: 0.2),
                        width: _usesContraceptive == false ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "No",
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).bellotaColors.blanco,
                        fontWeight: _usesContraceptive == false ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 16,
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
            child: _usesContraceptive == true
                ? TextFormField(
                    controller: _contraceptiveTextController,
                    style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoDark),
                    decoration: InputDecoration(
                      hintText: "¿Cuál?",
                      hintStyle: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoMedio),
                      filled: true,
                      fillColor: Theme.of(context).bellotaColors.blanco,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
""";
  content = content.replaceFirst(
    RegExp(r"Widget _buildStep6Contraceptive\(\)\s*\{.*?\}(?=\s*Widget _buildStep7Goal)", dotAll: true),
    contraUi,
  );

  file.writeAsStringSync(content);
}
