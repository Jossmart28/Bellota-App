import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

class FlujoVaginalSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedFlujos;

  const FlujoVaginalSelectionScreen({super.key, required this.initialSelectedFlujos});

  @override
  State<FlujoVaginalSelectionScreen> createState() => _FlujoVaginalSelectionScreenState();
}

class _FlujoVaginalSelectionScreenState extends State<FlujoVaginalSelectionScreen> {
  late Set<String> _selectedFlujosKeys;

  final List<Map<String, dynamic>> _sections = [
    {
      'titleKey': 'FisiolÃ³gico (Normal)',
      'options': ['dry', 'sticky', 'creamy', 'watery', 'egg_white']
    },
    {
      'titleKey': 'Anormal (Posible InfecciÃ³n)',
      'options': ['yellow_green', 'cottage_cheese', 'foul_odor']
    }
  ];

  @override
  void initState() {
    super.initState();
    _selectedFlujosKeys = Set.from(widget.initialSelectedFlujos);
  }

  void _toggleFlujo(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedFlujosKeys.contains(key)) {
        _selectedFlujosKeys.remove(key);
      } else {
        _selectedFlujosKeys.add(key);
      }
    });
  }

    Widget _buildFertilityBadge(String key, String lang) {
    return const SizedBox();
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
              AppLocalizations.of(context)!.registrationFormVaginalFlow,
              style: TextStyle(color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, _selectedFlujosKeys.toList());
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
    final isSelected = _selectedFlujosKeys.contains(key);
    return InkWell(
      onTap: () => _toggleFlujo(key),
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
            _buildFertilityBadge(key, lang),
            SizedBox(width: 12),
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




