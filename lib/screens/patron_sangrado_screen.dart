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

  final List<Map<String, dynamic>> _sections = [
    {
      'titleKey': 'Intensidad del Flujo Menstrual',
      'options': ['light_flow', 'moderate_flow', 'heavy_flow'],
      'isSingleChoice': true,
      'field': 'intensidadFlujoKey',
    },
    {
      'titleKey': 'Color del Sangrado',
      'options': ['bright_red', 'dark_red', 'brown', 'pink'],
      'isSingleChoice': true,
      'field': 'colorSangradoKey',
    },
    {
      'titleKey': 'Coágulos',
      'options': ['never', 'occasional', 'frequent'],
      'isSingleChoice': true,
      'field': 'coagulosKey',
    },
    {
      'titleKey': 'Manchado Intermenstrual',
      'options': ['no', 'yes'],
      'isSingleChoice': true,
      'field': 'manchadoKey',
    },
    {
      'titleKey': 'Complicaciones y Síntomas (Menstruación)',
      'options': ['pain', 'bleeding', 'unusual_flow', 'none'],
      'isSingleChoice': false,
      'field': 'sintomasSexualesKeys',
    }
  ];

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
      // Backwards compatibility if still needed somewhere
      'intensidadFlujo': AppTranslations.get('registration_form', _intensidadFlujoKey, lang, context: context),
      'coagulos': AppTranslations.get('registration_form', _coagulosKey, lang, context: context),
      'manchado': AppTranslations.get('registration_form', _manchadoKey, lang, context: context),
      'sintomasSexuales': _sintomasSexualesKeys.map((k) => AppTranslations.get('registration_form', k, lang, context: context)).join(', '),
    });
  }

  void _toggleOption(String field, String key, bool isSingleChoice) {
    setState(() {
      if (isSingleChoice) {
        switch (field) {
          case 'intensidadFlujoKey': _intensidadFlujoKey = key; break;
          case 'colorSangradoKey': _colorSangradoKey = key; break;
          case 'coagulosKey': _coagulosKey = key; break;
          case 'manchadoKey': _manchadoKey = key; break;
        }
      } else {
        if (key == 'none') {
          _sintomasSexualesKeys.clear();
          _sintomasSexualesKeys.add('none');
        } else {
          _sintomasSexualesKeys.remove('none');
          if (_sintomasSexualesKeys.contains(key)) {
            _sintomasSexualesKeys.remove(key);
            if (_sintomasSexualesKeys.isEmpty) _sintomasSexualesKeys.add('none');
          } else {
            _sintomasSexualesKeys.add(key);
          }
        }
      }
    });
  }

  bool _isSelected(String field, String key, bool isSingleChoice) {
    if (isSingleChoice) {
      switch (field) {
        case 'intensidadFlujoKey': return _intensidadFlujoKey == key;
        case 'colorSangradoKey': return _colorSangradoKey == key;
        case 'coagulosKey': return _coagulosKey == key;
        case 'manchadoKey': return _manchadoKey == key;
        default: return false;
      }
    } else {
      return _sintomasSexualesKeys.contains(key);
    }
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
                style: TextStyle(color: Theme.of(context).bellotaColors.textoMedio, fontSize: 16),
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
                  style: TextStyle(color: Theme.of(context).bellotaColors.chilero, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          body: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 12),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final section = _sections[index];
              final options = section['options'] as List<String>;
              final isSingleChoice = section['isSingleChoice'] as bool;
              final field = section['field'] as String;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
                    child: Text(
                      section['titleKey'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).bellotaColors.textoMedio,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ...options.asMap().entries.map((entry) {
                          final i = entry.key;
                          final optKey = entry.value;
                          return Column(
                            children: [
                              _buildRow(optKey, field, isSingleChoice, lang),
                              if (i < options.length - 1)
                                Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
                            ],
                          );
                        }).toList(),
                        if (field == 'manchadoKey' && _manchadoKey == 'yes') ...[
                          Divider(height: 1, color: Colors.grey.shade100),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: TextField(
                              controller: _manchadoDiasController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Días de manchado',
                                hintText: 'Ej. 3',
                                filled: true,
                                fillColor: Theme.of(context).bellotaColors.nancite,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRow(String key, String field, bool isSingleChoice, String lang) {
    final isSelected = _isSelected(field, key, isSingleChoice);
    return InkWell(
      onTap: () => _toggleOption(field, key, isSingleChoice),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppTranslations.get('registration_form', key, lang, context: context),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).bellotaColors.textoDark,
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: isSingleChoice ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isSingleChoice ? null : BorderRadius.circular(6),
                color: isSelected ? Theme.of(context).bellotaColors.chilero : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Theme.of(context).bellotaColors.chilero : Colors.grey.shade300,
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
}

