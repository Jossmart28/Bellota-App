import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

class SymptomsSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedSymptoms;

  const SymptomsSelectionScreen({super.key, required this.initialSelectedSymptoms});

  @override
  State<SymptomsSelectionScreen> createState() => _SymptomsSelectionScreenState();
}

class _SymptomsSelectionScreenState extends State<SymptomsSelectionScreen> {
  late Set<String> _selectedSymptoms;
  final TextEditingController _customSymptomController = TextEditingController();

  final List<Map<String, dynamic>> _symptomCategories = [
    {
      'title': 'Todo el cuerpo',
      'symptoms': [
        'Fiebre',
        'Dolor de cuerpo',
        'Distensión general',
      ]
    },
    {
      'title': 'Cabeza',
      'symptoms': [
        'Dolor de cabeza',
        'Vértigo',
        'Insomnio',
        'Vómitos',
        'Acné',
      ]
    },
    {
      'title': 'Abdomen',
      'symptoms': [
        'Dolor abdominal',
        'Distensión abdominal y vientre hinchado',
        'Diarrea',
        'Estreñimiento',
      ]
    },
    {
      'title': 'Otro',
      'symptoms': [
        'Sensibilidad en los senos',
        'Secreción vaginal anormal',
        'Manchado menstrual',
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _selectedSymptoms = Set.from(widget.initialSelectedSymptoms);
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  void _saveCustomSymptom() {
    final text = _customSymptomController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _selectedSymptoms.add(text);
        _customSymptomController.clear();
      });
    }
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
          child: Text('Cancelar', style: TextStyle(color: BellotaColors.textoDark, fontSize: 16)),
        ),
        leadingWidth: 80,
        title: Text('Síntomas', style: TextStyle(color: BellotaColors.textoDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedSymptoms.toList());
            },
            child: Text(AppTranslations.get('onboarding', 'confirm', languageNotifier.currentLang), style: TextStyle(color: BellotaColors.chilero, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ..._symptomCategories.map((category) => _buildCategoryCard(category)),
          _buildCustomSymptomCard(),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              category['title'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BellotaColors.textoDark,
              ),
            ),
          ),
          ...((category['symptoms'] as List<String>).map((symptom) => _buildSymptomRow(symptom))),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSymptomRow(String symptom) {
    final isSelected = _selectedSymptoms.contains(symptom);
    return InkWell(
      onTap: () => _toggleSymptom(symptom),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                symptom,
                style: TextStyle(
                  fontSize: 16,
                  color: BellotaColors.textoDark,
                ),
              ),
            ),
            // Círculo seleccionable (radio button visual)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? BellotaColors.chilero : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? BellotaColors.chilero : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSymptomCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personalización',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: BellotaColors.textoDark,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _customSymptomController,
            onSubmitted: (_) => _saveCustomSymptom(),
            decoration: InputDecoration(
              hintText: 'Síntomas personalizados',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: BellotaColors.chilero),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pulse la tecla Enter para finalizar la edición',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          // Mostrar síntomas personalizados agregados
          if (_selectedSymptoms.any((s) => !_symptomCategories.any((cat) => (cat['symptoms'] as List).contains(s))))
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _selectedSymptoms
                    .where((s) => !_symptomCategories.any((cat) => (cat['symptoms'] as List).contains(s)))
                    .map((s) => _buildSymptomRow(s))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
