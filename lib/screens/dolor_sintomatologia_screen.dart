import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

class DolorSintomatologiaScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const DolorSintomatologiaScreen({super.key, required this.initialData});

  @override
  State<DolorSintomatologiaScreen> createState() => _DolorSintomatologiaScreenState();
}

class _DolorSintomatologiaScreenState extends State<DolorSintomatologiaScreen> {
  late double _nivelDolor;
  late String _caracterDolor;
  late TextEditingController _diasDolorController;
  late String _tratamiento;
  late Set<String> _sintomasFisicos;
  late Set<String> _sintomasEmocionales;
  late String _autoexamenMama;

  @override
  void initState() {
    super.initState();
    _nivelDolor = widget.initialData['nivelDolor']?.toDouble() ?? 0.0;
    _caracterDolor = widget.initialData['caracterDolor'] ?? 'No incapacitante';
    _diasDolorController = TextEditingController(text: widget.initialData['diasDolor'] ?? '');
    _tratamiento = widget.initialData['tratamiento'] ?? 'Ninguno';
    
    _sintomasFisicos = {};
    if (widget.initialData['sintomasFisicos'] != null) {
      _sintomasFisicos = Set<String>.from(widget.initialData['sintomasFisicos']);
    }
    
    _sintomasEmocionales = {};
    if (widget.initialData['sintomasEmocionales'] != null) {
      _sintomasEmocionales = Set<String>.from(widget.initialData['sintomasEmocionales']);
    }
    
    _autoexamenMama = widget.initialData['autoexamenMama'] ?? 'Pendiente';
  }

  @override
  void dispose() {
    _diasDolorController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, {
      'nivelDolor': _nivelDolor,
      'caracterDolor': _caracterDolor,
      'diasDolor': _diasDolorController.text.trim(),
      'tratamiento': _tratamiento,
      'sintomasFisicos': _sintomasFisicos.toList(),
      'sintomasEmocionales': _sintomasEmocionales.toList(),
      'autoexamenMama': _autoexamenMama,
    });
  }

  void _toggleSetItem(Set<String> set, String item) {
    setState(() {
      if (set.contains(item)) {
        set.remove(item);
      } else {
        set.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BellotaColors.basilica,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppTranslations.get('registration_form', 'cancel', languageNotifier.currentLang), style: TextStyle(color: BellotaColors.textoDark, fontSize: 16)),
        ),
        leadingWidth: 80,
        title: Text(AppTranslations.get('registration_form', 'pain_and_symptoms', languageNotifier.currentLang), style: TextStyle(color: BellotaColors.textoDark, fontWeight: FontWeight.bold, fontSize: 15)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(AppTranslations.get('onboarding', 'confirm', languageNotifier.currentLang), style: TextStyle(color: BellotaColors.chilero, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('${AppTranslations.get('registration_form', 'pain_level', languageNotifier.currentLang)} (${_nivelDolor.toInt()}/10 EVA)'),
                Slider(
                  value: _nivelDolor,
                  min: 0, max: 10, divisions: 10,
                  activeColor: BellotaColors.chilero,
                  onChanged: (val) => setState(() => _nivelDolor = val),
                ),
                SizedBox(height: 16),

                _buildLabel(AppTranslations.get('registration_form', 'character', languageNotifier.currentLang)),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  options: [
                    AppTranslations.get('registration_form', 'incapacitating', languageNotifier.currentLang),
                    AppTranslations.get('registration_form', 'not_incapacitating', languageNotifier.currentLang),
                  ],
                  selected: _caracterDolor,
                  onSelected: (val) => setState(() => _caracterDolor = val),
                ),
                SizedBox(height: 24),

                _buildLabel(AppTranslations.get('registration_form', 'critical_pain_days', languageNotifier.currentLang)),
                SizedBox(height: 8),
                TextFormField(
                  controller: _diasDolorController,
                  decoration: InputDecoration(
                    hintText: AppTranslations.get('registration_form', 'phase_days', languageNotifier.currentLang),
                    filled: true,
                    fillColor: BellotaColors.basilica,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                SizedBox(height: 24),

                _buildLabel(AppTranslations.get('registration_form', 'treatment', languageNotifier.currentLang)),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  options: [
                    AppTranslations.get('registration_form', 'medication', languageNotifier.currentLang),
                    AppTranslations.get('registration_form', 'thermal_remedies', languageNotifier.currentLang),
                    AppTranslations.get('registration_form', 'none', languageNotifier.currentLang),
                  ],
                  selected: _tratamiento,
                  onSelected: (val) => setState(() => _tratamiento = val),
                ),
                SizedBox(height: 24),

                _buildLabel(AppTranslations.get('registration_form', 'physical_symptoms', languageNotifier.currentLang)),
                SizedBox(height: 8),
                _buildMultiChoiceChips(
                  options: [
                    AppTranslations.get('registration_form', 'severe_cramps', languageNotifier.currentLang),
                    AppTranslations.get('registration_form', 'menstrual_migraine', languageNotifier.currentLang),
                    AppTranslations.get('registration_form', 'mastalgia', languageNotifier.currentLang),
                  ],
                  selected: _sintomasFisicos,
                  onToggle: (val) => _toggleSetItem(_sintomasFisicos, val),
                ),
                SizedBox(height: 24),

                _buildLabel(AppTranslations.get('registration_form', 'emotional_symptoms', languageNotifier.currentLang)),
                SizedBox(height: 8),
                _buildMultiChoiceChips(
                  options: [
                    AppTranslations.get('registration_form', 'anxiety', languageNotifier.currentLang),
                    AppTranslations.get('symptoms', 'mood_swings', languageNotifier.currentLang),
                    AppTranslations.get('registration_form', 'extreme_fatigue', languageNotifier.currentLang),
                    AppTranslations.get('registration_form', 'pmdd_suspicion', languageNotifier.currentLang),
                  ],
                  selected: _sintomasEmocionales,
                  onToggle: (val) => _toggleSetItem(_sintomasEmocionales, val),
                ),
                SizedBox(height: 24),

                _buildLabel(AppTranslations.get('registration_form', 'breast_exam', languageNotifier.currentLang)),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  options: [
                    AppTranslations.get('registration_form', 'done', languageNotifier.currentLang),
                    AppTranslations.get('registration_form', 'pending', languageNotifier.currentLang),
                  ],
                  selected: _autoexamenMama,
                  onSelected: (val) => setState(() => _autoexamenMama = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(color: BellotaColors.textoDark, fontSize: 15, fontWeight: FontWeight.bold));
  }

  Widget _buildSingleChoiceChips({required List<String> options, required String selected, required Function(String) onSelected}) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onSelected(opt),
          selectedColor: BellotaColors.chilero,
          backgroundColor: BellotaColors.basilica,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : BellotaColors.textoDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiChoiceChips({required List<String> options, required Set<String> selected, required Function(String) onToggle}) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onToggle(opt),
          selectedColor: BellotaColors.chilero,
          backgroundColor: BellotaColors.basilica,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : BellotaColors.textoDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
