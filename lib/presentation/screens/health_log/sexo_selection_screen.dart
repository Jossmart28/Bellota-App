import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

class SexoSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedSexo;

  const SexoSelectionScreen({super.key, required this.initialSelectedSexo});

  @override
  State<SexoSelectionScreen> createState() => _SexoSelectionScreenState();
}

class _SexoSelectionScreenState extends State<SexoSelectionScreen> {
  late Set<String> _selectedSexoKeys;

  final List<Map<String, dynamic>> _sections = [
    {
      'titleKey': 'Actividad Sexual',
      'options': ['protected', 'unprotected', 'masturbation', 'high_libido']
    },
    {
      'titleKey': 'Anticoncepción / Protección',
      'options': ['no_contraception', 'condom', 'no_ejaculation', 'short_pill']
    },
    {
      'titleKey': 'Complicaciones y Síntomas',
      'options': ['pain_during_sex', 'unprotected_new_partner']
    }
  ];

  @override
  void initState() {
    super.initState();
    _selectedSexoKeys = Set.from(widget.initialSelectedSexo);
  }

  void _toggleSexo(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedSexoKeys.contains(key)) {
        _selectedSexoKeys.remove(key);
      } else {
        // Lógica de exclusión
        if (key == 'no_contraception') {
          _selectedSexoKeys.remove('condom');
          _selectedSexoKeys.remove('protected');
        } else if (key == 'condom' || key == 'protected') {
          _selectedSexoKeys.remove('no_contraception');
          _selectedSexoKeys.remove('unprotected');
          _selectedSexoKeys.remove('unprotected_new_partner');
        } else if (key == 'unprotected' || key == 'unprotected_new_partner') {
          _selectedSexoKeys.remove('condom');
          _selectedSexoKeys.remove('protected');
        }
        _selectedSexoKeys.add(key);
      }
    });
  }

  void _toggleSelection(String key) => _toggleSexo(key);

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
              AppLocalizations.of(context)!.registrationFormSex,
              style: TextStyle(color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, _selectedSexoKeys.toList());
                },
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
                      children: options.asMap().entries.map((entry) {
                        final i = entry.key;
                        final optKey = entry.value;
                        return Column(
                          children: [
                            _buildRow(optKey, lang),
                            if (i < options.length - 1)
                              Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
                          ],
                        );
                      }).toList(),
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

  Widget _buildRow(String key, String lang) {
    final isSelected = _selectedSexoKeys.contains(key);
    return InkWell(
      onTap: () => _toggleSexo(key),
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
                shape: BoxShape.circle,
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


