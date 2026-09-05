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
  late String _caracterDolorKey;
  late TextEditingController _diasDolorController;
  late String _tratamientoKey;
  late Set<String> _sintomasFisicosKeys;
  late Set<String> _sintomasEmocionalKeys;
  late String _autoexamenMamaKey;

  final List<String> _caracterDolorOptions = ['incapacitating', 'not_incapacitating'];
  final List<String> _tratamientoOptions = ['medication', 'thermal_remedies', 'none'];
  final List<String> _sintomasFisicosOptions = [
    'severe_cramps', 'menstrual_migraine', 'mastalgia', 'lower_back_pain', 
    'leg_cramps', 'pelvic_pain', 'bloating', 'nausea', 'dizziness', 'palpitations'
  ];
  final List<String> _sintomasEmocionalesOptions = [
    'anxiety', 'mood_swings', 'extreme_fatigue', 'irritability', 
    'sadness', 'crying_easily', 'concentration_difficulty', 'low_self_esteem', 'pmdd_suspicion'
  ];
  final List<String> _autoexamenMamaOptions = [
    'breast_normal', 'breast_lump', 'breast_localized_pain', 
    'breast_skin_change', 'breast_discharge', 'breast_pending'
  ];

  @override
  void initState() {
    super.initState();
    final lang = languageNotifier.currentLang;
    
    _nivelDolor = widget.initialData['nivelDolor']?.toDouble() ?? 0.0;
    
    _caracterDolorKey = widget.initialData['caracterDolorKey'] ?? 
        _mapCaracterDolor(widget.initialData['caracterDolor'], lang);
        
    _diasDolorController = TextEditingController(text: widget.initialData['diasDolor'] ?? '');
    
    _tratamientoKey = widget.initialData['tratamientoKey'] ?? 
        _mapTratamiento(widget.initialData['tratamiento'], lang);
    
    _sintomasFisicosKeys = {};
    if (widget.initialData['sintomasFisicosKeys'] != null) {
      _sintomasFisicosKeys = Set<String>.from(widget.initialData['sintomasFisicosKeys']);
    } else if (widget.initialData['sintomasFisicos'] != null) {
      _sintomasFisicosKeys = _mapSintomas(widget.initialData['sintomasFisicos'], _sintomasFisicosOptions, lang);
    }
    
    _sintomasEmocionalKeys = {};
    if (widget.initialData['sintomasEmocionalKeys'] != null) {
      _sintomasEmocionalKeys = Set<String>.from(widget.initialData['sintomasEmocionalKeys']);
    } else if (widget.initialData['sintomasEmocionales'] != null) {
      _sintomasEmocionalKeys = _mapSintomas(widget.initialData['sintomasEmocionales'], _sintomasEmocionalesOptions, lang);
    }
    
    _autoexamenMamaKey = widget.initialData['autoexamenMamaKey'] ?? 
        _mapAutoexamenMama(widget.initialData['autoexamenMama'], lang);
  }

  String _mapCaracterDolor(String? val, String lang) {
    if (val == null) return 'not_incapacitating';
    if (_caracterDolorOptions.contains(val)) return val;
    for (var k in _caracterDolorOptions) {
      if (AppTranslations.get('registration_form', k, lang) == val) return k;
    }
    return 'not_incapacitating';
  }

  String _mapTratamiento(String? val, String lang) {
    if (val == null) return 'none';
    if (_tratamientoOptions.contains(val)) return val;
    for (var k in _tratamientoOptions) {
      if (AppTranslations.get('registration_form', k, lang) == val) return k;
    }
    if (val.toLowerCase() == 'ninguno') return 'none';
    return 'none';
  }

  String _mapAutoexamenMama(String? val, String lang) {
    if (val == null) return 'breast_pending';
    if (_autoexamenMamaOptions.contains(val)) return val;
    if (val == AppTranslations.get('registration_form', 'done', lang) || val.toLowerCase() == 'realizado') return 'breast_normal';
    if (val == AppTranslations.get('registration_form', 'pending', lang) || val.toLowerCase() == 'pendiente') return 'breast_pending';
    return 'breast_pending';
  }

  Set<String> _mapSintomas(List<dynamic>? vals, List<String> validKeys, String lang) {
    if (vals == null) return {};
    Set<String> result = {};
    for (var v in vals) {
      if (validKeys.contains(v)) {
        result.add(v);
      } else {
        for (var k in validKeys) {
          if (AppTranslations.get('registration_form', k, lang) == v) {
            result.add(k);
            break;
          }
        }
      }
    }
    return result;
  }

  @override
  void dispose() {
    _diasDolorController.dispose();
    super.dispose();
  }

  void _save() {
    final lang = languageNotifier.currentLang;
    Navigator.pop(context, {
      'nivelDolor': _nivelDolor,
      'caracterDolorKey': _caracterDolorKey,
      'diasDolor': _diasDolorController.text.trim(),
      'tratamientoKey': _tratamientoKey,
      'sintomasFisicosKeys': _sintomasFisicosKeys.toList(),
      'sintomasEmocionalKeys': _sintomasEmocionalKeys.toList(),
      'autoexamenMamaKey': _autoexamenMamaKey,
      
      // Backward compatibility keys
      'caracterDolor': AppTranslations.get('registration_form', _caracterDolorKey, lang),
      'tratamiento': AppTranslations.get('registration_form', _tratamientoKey, lang),
      'autoexamenMama': AppTranslations.get('registration_form', _autoexamenMamaKey, lang),
      'sintomasFisicos': _sintomasFisicosKeys.map((k) => AppTranslations.get('registration_form', k, lang)).toList(),
      'sintomasEmocionales': _sintomasEmocionalKeys.map((k) => AppTranslations.get('registration_form', k, lang)).toList(),
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

  String _getPainEmoji(double value) {
    if (value == 0) return 'ðŸ˜Œ';
    if (value <= 3) return 'ðŸ˜';
    if (value <= 6) return 'ðŸ˜£';
    if (value <= 8) return 'ðŸ˜–';
    return 'ðŸ˜­';
  }

  Widget _buildSectionLabel(String text, IconData iconData) {
    return Row(
      children: [
        Icon(iconData, color: Theme.of(context).bellotaColors.chilero, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(color: Theme.of(context).bellotaColors.textoDark, fontSize: 14, fontWeight: FontWeight.bold)
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(color: Theme.of(context).bellotaColors.nancite, thickness: 1),
    );
  }

  Widget _buildChoiceChips({required List<String> options, required String selected, required Function(String) onSelected}) {
    final lang = languageNotifier.currentLang;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return FilterChip(
          showCheckmark: false,
          label: Text(AppTranslations.get('registration_form', opt, lang)),
          selected: isSelected,
          onSelected: (_) => onSelected(opt),
          selectedColor: Theme.of(context).bellotaColors.chilero,
          backgroundColor: Theme.of(context).bellotaColors.nancite,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).bellotaColors.textoDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiChoiceChips({required List<String> options, required Set<String> selected, required Function(String) onToggle}) {
    final lang = languageNotifier.currentLang;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return FilterChip(
          showCheckmark: false,
          label: Text(AppTranslations.get('registration_form', opt, lang)),
          selected: isSelected,
          onSelected: (_) => onToggle(opt),
          selectedColor: Theme.of(context).bellotaColors.chilero,
          backgroundColor: Theme.of(context).bellotaColors.nancite,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).bellotaColors.textoDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
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
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppTranslations.get('registration_form', 'cancel', lang), style: TextStyle(color: Theme.of(context).bellotaColors.textoDark)),
        ),
        leadingWidth: 80,
        title: Text(
          AppTranslations.get('registration_form', 'pain_and_symptoms', lang), 
          style: TextStyle(color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(AppTranslations.get('onboarding', 'confirm', lang), style: TextStyle(color: Theme.of(context).bellotaColors.chilero)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).bellotaColors.blanco,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.07), 
                  blurRadius: 16, 
                  offset: Offset(0, 4)
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel(AppTranslations.get('registration_form', 'pain_level', lang), Icons.thermostat_rounded),
                SizedBox(height: 16),
                
                // EVA Slider labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppTranslations.get('registration_form', 'pain_none', lang), style: TextStyle(fontSize: 10, color: Theme.of(context).bellotaColors.textoMedio)),
                    Text(AppTranslations.get('registration_form', 'pain_mild', lang), style: TextStyle(fontSize: 10, color: Theme.of(context).bellotaColors.textoMedio)),
                    Text(AppTranslations.get('registration_form', 'pain_moderate', lang), style: TextStyle(fontSize: 10, color: Theme.of(context).bellotaColors.textoMedio)),
                    Text(AppTranslations.get('registration_form', 'pain_severe', lang), style: TextStyle(fontSize: 10, color: Theme.of(context).bellotaColors.textoMedio)),
                    Text(AppTranslations.get('registration_form', 'pain_incapacitating', lang), style: TextStyle(fontSize: 10, color: Theme.of(context).bellotaColors.textoMedio)),
                  ],
                ),
                
                // EVA Slider
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 8,
                    activeTrackColor: Theme.of(context).bellotaColors.chilero,
                    inactiveTrackColor: Theme.of(context).bellotaColors.nancite,
                    thumbColor: Theme.of(context).bellotaColors.chilero,
                    overlayColor: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.2),
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                  ),
                  child: Slider(
                    value: _nivelDolor,
                    min: 0, 
                    max: 10, 
                    divisions: 10,
                    onChanged: (val) => setState(() => _nivelDolor = val),
                  ),
                ),
                
                // EVA Emoji and Value
                Center(
                  child: Text(
                    '${_getPainEmoji(_nivelDolor)} ${_nivelDolor.toInt()}/10',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Theme.of(context).bellotaColors.chilero
                    ),
                  ),
                ),
                
                // Clinical Alert Banner
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: _nivelDolor >= 8 ? null : 0,
                  child: _nivelDolor >= 8 ? Container(
                    margin: EdgeInsets.symmetric(vertical: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Theme.of(context).bellotaColors.chilero, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppTranslations.get('registration_form', 'pain_alert_msg', lang), 
                            style: TextStyle(fontSize: 12, color: Theme.of(context).bellotaColors.chilero, height: 1.4)
                          ),
                        ),
                      ],
                    ),
                  ) : SizedBox.shrink(),
                ),

                _buildDivider(),

                _buildSectionLabel(AppTranslations.get('registration_form', 'character', lang), Icons.category_outlined),
                SizedBox(height: 8),
                _buildChoiceChips(
                  options: _caracterDolorOptions,
                  selected: _caracterDolorKey,
                  onSelected: (val) => setState(() => _caracterDolorKey = val),
                ),
                
                _buildDivider(),

                _buildSectionLabel(AppTranslations.get('registration_form', 'critical_pain_days', lang), Icons.calendar_today_rounded),
                SizedBox(height: 8),
                TextFormField(
                  controller: _diasDolorController,
                  decoration: InputDecoration(
                    hintText: AppTranslations.get('registration_form', 'phase_days', lang),
                    filled: true,
                    fillColor: Theme.of(context).bellotaColors.basilica,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                
                _buildDivider(),

                _buildSectionLabel(AppTranslations.get('registration_form', 'treatment', lang), Icons.medical_services_outlined),
                SizedBox(height: 8),
                _buildChoiceChips(
                  options: _tratamientoOptions,
                  selected: _tratamientoKey,
                  onSelected: (val) => setState(() => _tratamientoKey = val),
                ),
                
                _buildDivider(),

                _buildSectionLabel(AppTranslations.get('registration_form', 'physical_symptoms', lang), Icons.accessibility_new_rounded),
                SizedBox(height: 8),
                _buildMultiChoiceChips(
                  options: _sintomasFisicosOptions,
                  selected: _sintomasFisicosKeys,
                  onToggle: (val) => _toggleSetItem(_sintomasFisicosKeys, val),
                ),
                
                _buildDivider(),

                _buildSectionLabel(AppTranslations.get('registration_form', 'emotional_symptoms', lang), Icons.psychology_outlined),
                SizedBox(height: 8),
                _buildMultiChoiceChips(
                  options: _sintomasEmocionalesOptions,
                  selected: _sintomasEmocionalKeys,
                  onToggle: (val) => _toggleSetItem(_sintomasEmocionalKeys, val),
                ),
                
                _buildDivider(),

                _buildSectionLabel(AppTranslations.get('registration_form', 'breast_exam', lang), Icons.favorite_border_rounded),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).bellotaColors.asuncion.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).bellotaColors.asuncion, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppTranslations.get('registration_form', 'breast_exam_info', lang), 
                          style: TextStyle(fontSize: 11, color: Theme.of(context).bellotaColors.asuncion)
                        ),
                      ),
                    ],
                  ),
                ),
                _buildChoiceChips(
                  options: _autoexamenMamaOptions,
                  selected: _autoexamenMamaKey,
                  onSelected: (val) => setState(() => _autoexamenMamaKey = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
        },
    );
  }
}

