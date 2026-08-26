import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
          child: const Text('Cancelar', style: TextStyle(color: BellotaColors.textoDark, fontSize: 16)),
        ),
        leadingWidth: 80,
        title: const Text('Síntomas', style: TextStyle(color: BellotaColors.textoDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedSymptoms.toList());
            },
            child: const Text('Confirmar', style: TextStyle(color: BellotaColors.chilero, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ..._symptomCategories.map((category) => _buildCategoryCard(category)),
          _buildCustomSymptomCard(),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              category['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BellotaColors.textoDark,
              ),
            ),
          ),
          ...((category['symptoms'] as List<String>).map((symptom) => _buildSymptomRow(symptom))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSymptomRow(String symptom) {
    final isSelected = _selectedSymptoms.contains(symptom);
    return InkWell(
      onTap: () => _toggleSymptom(symptom),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Bellota en vez de ícono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BellotaColors.nancite,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🌰', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                symptom,
                style: const TextStyle(
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
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSymptomCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 32.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalización',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: BellotaColors.textoDark,
            ),
          ),
          const SizedBox(height: 12),
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
                borderSide: const BorderSide(color: BellotaColors.chilero),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pulse la tecla Enter para finalizar la edición',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          // Mostrar síntomas personalizados agregados
          if (_selectedSymptoms.any((s) => !_symptomCategories.any((cat) => (cat['symptoms'] as List).contains(s))))
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
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
