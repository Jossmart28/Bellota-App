import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

class SymptomsSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedSymptoms;

  SymptomsSelectionScreen({super.key, required this.initialSelectedSymptoms});

  @override
  State<SymptomsSelectionScreen> createState() => _SymptomsSelectionScreenState();
}

class _SymptomsSelectionScreenState extends State<SymptomsSelectionScreen> {
  late Set<String> _selectedSymptoms;
  final TextEditingController _customSymptomController = TextEditingController();
  final List<String> _customSymptomsList = [];

  List<Map<String, dynamic>> get _symptomCategories => [
    {
      'key': 'whole_body',
      'icon': Icons.accessibility_new_rounded,
      'color': Theme.of(context).bellotaColors.chiltoma,
      'symptoms': [
        {'key': 'fever', 'icon': Icons.thermostat_rounded},
        {'key': 'body_ache', 'icon': Icons.sick_outlined},
        {'key': 'general_distension', 'icon': Icons.circle_outlined},
        {'key': 'extreme_fatigue', 'icon': Icons.battery_0_bar_rounded},
        {'key': 'water_retention', 'icon': Icons.water_drop_outlined},
        {'key': 'night_sweats', 'icon': Icons.nightlight_round},
        {'key': 'hot_flashes', 'icon': Icons.local_fire_department_outlined},
        {'key': 'palpitations', 'icon': Icons.favorite_border_rounded},
        {'key': 'dizziness', 'icon': Icons.rotate_90_degrees_ccw_rounded},
        {'key': 'joint_pain', 'icon': Icons.sports_gymnastics_outlined},
      ]
    },
    {
      'key': 'head',
      'icon': Icons.face_rounded,
      'color': Theme.of(context).bellotaColors.asuncion,
      'symptoms': [
        {'key': 'headache', 'icon': Icons.psychology_outlined},
        {'key': 'vertigo', 'icon': Icons.swap_horiz_rounded},
        {'key': 'insomnia', 'icon': Icons.bedtime_outlined},
        {'key': 'vomiting', 'icon': Icons.sick_outlined},
        {'key': 'acne', 'icon': Icons.face_retouching_natural_outlined},
        {'key': 'concentration_difficulty', 'icon': Icons.blur_on_rounded},
      ]
    },
    {
      'key': 'abdomen',
      'icon': Icons.favorite_border_rounded,
      'color': Theme.of(context).bellotaColors.chilero,
      'symptoms': [
        {'key': 'abdominal_pain', 'icon': Icons.spa_outlined},
        {'key': 'abdominal_distension', 'icon': Icons.circle_outlined},
        {'key': 'bloating', 'icon': Icons.radio_button_unchecked_rounded},
        {'key': 'diarrhea', 'icon': Icons.run_circle_outlined},
        {'key': 'constipation', 'icon': Icons.block_outlined},
        {'key': 'nausea', 'icon': Icons.sick_outlined},
        {'key': 'pelvic_pain', 'icon': Icons.location_on_outlined},
        {'key': 'lower_back_pain', 'icon': Icons.accessibility_new_rounded},
        {'key': 'leg_cramps', 'icon': Icons.directions_run_rounded},
      ]
    },
    {
      'key': 'other',
      'icon': Icons.more_horiz_rounded,
      'color': Theme.of(context).bellotaColors.melon,
      'symptoms': [
        {'key': 'breast_tenderness', 'icon': Icons.favorite_rounded},
        {'key': 'abnormal_discharge', 'icon': Icons.opacity_rounded},
        {'key': 'spotting', 'icon': Icons.water_drop_rounded},
        {'key': 'appetite_changes', 'icon': Icons.restaurant_outlined},
        {'key': 'cravings', 'icon': Icons.cake_outlined},
      ]
    },
    {
      'key': 'emotional',
      'icon': Icons.psychology_rounded,
      'color': Color(0xFF9C6FB3),
      'symptoms': [
        {'key': 'irritability', 'icon': Icons.mood_bad_outlined},
        {'key': 'sadness', 'icon': Icons.sentiment_dissatisfied_outlined},
        {'key': 'crying_easily', 'icon': Icons.water_drop_outlined},
        {'key': 'mood_swings', 'icon': Icons.swap_vert_rounded},
        {'key': 'anxiety', 'icon': Icons.warning_amber_rounded},
        {'key': 'low_self_esteem', 'icon': Icons.trending_down_rounded},
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    _selectedSymptoms = Set.from(widget.initialSelectedSymptoms);
    
    // Extract custom symptoms (those not present in the predefined categories)
    final allPredefinedKeys = _symptomCategories
        .expand((cat) => (cat['symptoms'] as List).map((s) => s['key'] as String))
        .toSet();
    
    for (var symptom in widget.initialSelectedSymptoms) {
      if (!allPredefinedKeys.contains(symptom)) {
        _customSymptomsList.add(symptom);
      }
    }
  }

  @override
  void dispose() {
    _customSymptomController.dispose();
    super.dispose();
  }

  void _toggleSymptom(String symptomKey) {
    setState(() {
      if (_selectedSymptoms.contains(symptomKey)) {
        _selectedSymptoms.remove(symptomKey);
      } else {
        _selectedSymptoms.add(symptomKey);
      }
    });
  }

  void _saveCustomSymptom() {
    final text = _customSymptomController.text.trim();
    if (text.isNotEmpty && !_customSymptomsList.contains(text)) {
      setState(() {
        _customSymptomsList.add(text);
        _selectedSymptoms.add(text);
        _customSymptomController.clear();
      });
    } else if (text.isNotEmpty && _customSymptomsList.contains(text) && !_selectedSymptoms.contains(text)) {
      // Re-select if it already exists in custom list
      setState(() {
        _selectedSymptoms.add(text);
        _customSymptomController.clear();
      });
    }
  }

  void _deleteCustomSymptom(String text) {
    setState(() {
      _customSymptomsList.remove(text);
      _selectedSymptoms.remove(text);
    });
  }

  String _getTranslated(String key) {
    return AppTranslations.get('registration_form', key, languageNotifier.currentLang);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
    return Scaffold(
      backgroundColor: Theme.of(context).bellotaColors.basilica,
      appBar: AppBar(
        backgroundColor: Theme.of(context).bellotaColors.blanco,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            _getTranslated('cancel'),
            style: TextStyle(color: Theme.of(context).bellotaColors.textoDark, fontSize: 16),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getTranslated('symptoms'),
              style: TextStyle(
                color: Theme.of(context).bellotaColors.textoDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (_selectedSymptoms.isNotEmpty)
              Text(
                '${_selectedSymptoms.length} ${_getTranslated('selected_count')}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).bellotaColors.textoMedio,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_selectedSymptoms.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).bellotaColors.chilero,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedSymptoms.length}',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedSymptoms.toList());
            },
            child: Text(
              _getTranslated('confirm'),
              style: TextStyle(
                color: Theme.of(context).bellotaColors.chilero,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          ..._symptomCategories.map((category) => _buildCategoryCard(category)),
          _buildCustomSymptomCard(),
        ],
      ),
    );
        },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final catColor = category['color'] as Color;
    final catKey = category['key'] as String;
    final catIcon = category['icon'] as IconData;
    final symptoms = category['symptoms'] as List;

    int selectedCount = symptoms.where((s) => _selectedSymptoms.contains(s['key'])).length;
    int totalCount = symptoms.length;

    return Container(
      margin: EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).bellotaColors.blanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getTranslated(catKey),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).bellotaColors.textoDark,
                    ),
                  ),
                ),
                Text(
                  '$selectedCount/$totalCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).bellotaColors.textoMedio,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).bellotaColors.nancite, height: 1, thickness: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: symptoms.length,
            separatorBuilder: (context, index) => Divider(
              color: Theme.of(context).bellotaColors.nancite,
              height: 1,
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final symptom = symptoms[index];
              return _buildSymptomRow(
                symptomKey: symptom['key'],
                label: _getTranslated(symptom['key']),
                icon: symptom['icon'],
                catColor: catColor,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomRow({
    required String symptomKey,
    required String label,
    IconData? icon,
    Color? catColor,
  }) {
    final isSelected = _selectedSymptoms.contains(symptomKey);

    return InkWell(
      onTap: () => _toggleSymptom(symptomKey),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
        child: Row(
          children: [
            if (icon != null && catColor != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: catColor, size: 18),
              ),
              SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).bellotaColors.textoDark,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).bellotaColors.chilero : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).bellotaColors.chilero
                      : Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: Colors.white)
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
        color: Theme.of(context).bellotaColors.blanco,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Theme.of(context).bellotaColors.chilero, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getTranslated('personalization'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).bellotaColors.textoDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).bellotaColors.nancite, height: 1, thickness: 1),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _customSymptomController,
                  onSubmitted: (_) => _saveCustomSymptom(),
                  decoration: InputDecoration(
                    hintText: _getTranslated('custom_symptoms'),
                    hintStyle: TextStyle(color: Theme.of(context).bellotaColors.textoMedio),
                    filled: true,
                    fillColor: Theme.of(context).bellotaColors.nancite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add_rounded, color: Theme.of(context).bellotaColors.chilero),
                      onPressed: _saveCustomSymptom,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _getTranslated('press_enter'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).bellotaColors.textoMedio,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (_customSymptomsList.isNotEmpty) ...[
                  SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _customSymptomsList.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Theme.of(context).bellotaColors.nancite,
                      height: 1,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) {
                      final text = _customSymptomsList[index];
                      final isSelected = _selectedSymptoms.contains(text);
                      return InkWell(
                        onTap: () => _toggleSymptom(text),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 11.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).bellotaColors.textoDark,
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.close_rounded, size: 16, color: Theme.of(context).bellotaColors.textoMedio),
                                onPressed: () => _deleteCustomSymptom(text),
                              ),
                              SizedBox(width: 12),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isSelected ? Theme.of(context).bellotaColors.chilero : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).bellotaColors.chilero
                                        : Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(Icons.check, size: 14, color: Colors.white)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

