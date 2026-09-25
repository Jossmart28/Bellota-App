import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import '../theme/bellota_colors.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

class PatronSangradoScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const PatronSangradoScreen({super.key, required this.initialData});

  @override
  State<PatronSangradoScreen> createState() => _PatronSangradoScreenState();
}

class _PatronSangradoScreenState extends State<PatronSangradoScreen> {
  late String _intensidadFlujoKey;
  late String _coagulosKey;
  late String _manchadoKey;
  late TextEditingController _manchadoDiasController;
  late Set<String> _sintomasSexualesKeys;
  late String _colorSangradoKey;

  @override
  void initState() {
    super.initState();
    _intensidadFlujoKey = widget.initialData['intensidadFlujoKey'] ?? 'moderate_flow';
    _coagulosKey = widget.initialData['coagulosKey'] ?? 'never';
    _manchadoKey = widget.initialData['manchadoKey'] ?? 'no';
    _manchadoDiasController = TextEditingController(text: widget.initialData['manchadoDias'] ?? '');
    
    if (widget.initialData['sintomasSexualesKeys'] != null) {
      _sintomasSexualesKeys = Set<String>.from(widget.initialData['sintomasSexualesKeys']);
    } else {
      _sintomasSexualesKeys = {'none'};
    }
    _colorSangradoKey = widget.initialData['colorSangradoKey'] ?? 'bright_red';
  }

  @override
  void dispose() {
    _manchadoDiasController.dispose();
    super.dispose();
  }

  void _save() {
    final lang = languageNotifier.currentLang;
    Navigator.pop(context, {
      'intensidadFlujoKey': _intensidadFlujoKey,
      'coagulosKey': _coagulosKey,
      'manchadoKey': _manchadoKey,
      'manchadoDias': _manchadoDiasController.text.trim(),
      'sintomasSexualesKeys': _sintomasSexualesKeys.toList(),
      'colorSangradoKey': _colorSangradoKey,
      // Backwards compatibility
      'intensidadFlujo': AppTranslations.get('registration_form', _intensidadFlujoKey, lang, context: context),
      'coagulos': AppTranslations.get('registration_form', _coagulosKey, lang, context: context),
      'manchado': AppTranslations.get('registration_form', _manchadoKey, lang, context: context),
      'sintomasSexuales': _sintomasSexualesKeys.map((k) => AppTranslations.get('registration_form', k, lang, context: context)).join(', '),
    });
  }

  Widget _buildLabel(String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).bellotaColors.chilero,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).bellotaColors.textoDark,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleChoiceChips({
    required List<String> optionKeys,
    required String selectedKey,
    required Function(String) onSelected,
    Map<String, String>? prefixes,
  }) {
    final lang = languageNotifier.currentLang;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: optionKeys.map((key) {
        final isSelected = selectedKey == key;
        final label = AppTranslations.get('registration_form', key, lang, context: context);
        return ChoiceChip(
          label: prefixes != null && prefixes.containsKey(key)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(prefixes[key]!),
                    SizedBox(width: 4),
                    Text(label),
                  ],
                )
              : Text(label),
          selected: isSelected,
          onSelected: (_) => onSelected(key),
          selectedColor: Theme.of(context).bellotaColors.chilero,
          backgroundColor: Theme.of(context).bellotaColors.nancite,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide.none,
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).bellotaColors.textoDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiChoiceChips({
    required List<String> optionKeys,
    required Set<String> selectedKeys,
    required Function(String) onSelected,
  }) {
    final lang = languageNotifier.currentLang;
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: optionKeys.map((key) {
        final isSelected = selectedKeys.contains(key);
        final label = AppTranslations.get('registration_form', key, lang, context: context);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onSelected(key),
          selectedColor: Theme.of(context).bellotaColors.chilero,
          backgroundColor: Theme.of(context).bellotaColors.nancite,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide.none,
          ),
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.registrationFormCancel,
            style: TextStyle(color: Theme.of(context).bellotaColors.chilero, fontSize: 16),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          AppLocalizations.of(context)!.registrationFormBleedingPattern,
          style: TextStyle(color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              AppLocalizations.of(context)!.onboardingConfirm,
              style: TextStyle(color: Theme.of(context).bellotaColors.chilero, fontSize: 16),
            ),
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(AppLocalizations.of(context)!.registrationFormFlowIntensity),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  optionKeys: ['light_flow', 'moderate_flow', 'heavy_flow'],
                  selectedKey: _intensidadFlujoKey,
                  onSelected: (val) => setState(() => _intensidadFlujoKey = val),
                  prefixes: {
                    'light_flow': '💧',
                    'moderate_flow': '💧💧',
                    'heavy_flow': '💧💧💧',
                  },
                ),
                SizedBox(height: 24),

                _buildLabel(AppLocalizations.of(context)!.registrationFormBloodColor),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  optionKeys: ['bright_red', 'dark_red', 'brown', 'pink'],
                  selectedKey: _colorSangradoKey,
                  onSelected: (val) => setState(() => _colorSangradoKey = val),
                ),
                SizedBox(height: 24),

                _buildLabel(AppLocalizations.of(context)!.registrationFormClots),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  optionKeys: ['never', 'occasional', 'frequent'],
                  selectedKey: _coagulosKey,
                  onSelected: (val) => setState(() => _coagulosKey = val),
                ),
                SizedBox(height: 24),

                _buildLabel(AppLocalizations.of(context)!.registrationFormIntermenstrualSpotting),
                SizedBox(height: 8),
                _buildSingleChoiceChips(
                  optionKeys: ['no', 'yes'],
                  selectedKey: _manchadoKey,
                  onSelected: (val) => setState(() => _manchadoKey = val),
                ),
                if (_manchadoKey == 'yes') ...[
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _manchadoDiasController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.registrationFormCycleDays,
                      filled: true,
                      fillColor: Theme.of(context).bellotaColors.nancite,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
                SizedBox(height: 24),

                _buildLabel(AppLocalizations.of(context)!.registrationFormSexSymptoms),
                SizedBox(height: 8),
                _buildMultiChoiceChips(
                  optionKeys: ['pain', 'bleeding', 'unusual_flow', 'none'],
                  selectedKeys: _sintomasSexualesKeys,
                  onSelected: (val) {
                    setState(() {
                      if (val == 'none') {
                        _sintomasSexualesKeys = {'none'};
                      } else {
                        _sintomasSexualesKeys.remove('none');
                        if (_sintomasSexualesKeys.contains(val)) {
                          _sintomasSexualesKeys.remove(val);
                        } else {
                          _sintomasSexualesKeys.add(val);
                        }
                        if (_sintomasSexualesKeys.isEmpty) {
                          _sintomasSexualesKeys.add('none');
                        }
                      }
                    });
                  },
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

