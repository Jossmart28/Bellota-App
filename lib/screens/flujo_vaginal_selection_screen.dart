import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

class FlujoVaginalSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedFlujos;

  FlujoVaginalSelectionScreen({super.key, required this.initialSelectedFlujos});

  @override
  State<FlujoVaginalSelectionScreen> createState() => _FlujoVaginalSelectionScreenState();
}

class _FlujoVaginalSelectionScreenState extends State<FlujoVaginalSelectionScreen> {
  late Set<String> _selectedFlujosKeys;

  final List<String> _flujoOptionKeys = [
    'dry',
    'thick',
    'liquid_elastic',
    'watery',
    'egg_white',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFlujosKeys = Set.from(widget.initialSelectedFlujos);
  }

  void _toggleFlujo(String key) {
    setState(() {
      if (_selectedFlujosKeys.contains(key)) {
        _selectedFlujosKeys.remove(key);
      } else {
        _selectedFlujosKeys.add(key);
      }
    });
  }

  Widget _buildFertilityBadge(String key, String lang) {
    String badgeKey;
    Color color;
    Color bgColor;

    switch (key) {
      case 'dry':
      case 'thick':
        badgeKey = 'fertility_low';
        color = Theme.of(context).bellotaColors.chiltoma;
        bgColor = Theme.of(context).bellotaColors.chiltoma.withValues(alpha: 0.2);
        break;
      case 'liquid_elastic':
        badgeKey = 'fertility_medium';
        color = Theme.of(context).bellotaColors.melon;
        bgColor = Theme.of(context).bellotaColors.melon.withValues(alpha: 0.2);
        break;
      case 'watery':
      case 'egg_white':
      default:
        badgeKey = 'fertility_high';
        color = Theme.of(context).bellotaColors.chilero;
        bgColor = Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.15);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        AppTranslations.get('registration_form', badgeKey, lang),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = languageNotifier.currentLang;
    return Scaffold(
      backgroundColor: Theme.of(context).bellotaColors.basilica,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppTranslations.get('registration_form', 'cancel', lang),
            style: TextStyle(color: Theme.of(context).bellotaColors.chilero, fontSize: 16),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          AppTranslations.get('registration_form', 'vaginal_flow', lang),
          style: TextStyle(color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedFlujosKeys.toList());
            },
            child: Text(
              AppTranslations.get('onboarding', 'confirm', lang),
              style: TextStyle(color: Theme.of(context).bellotaColors.chilero, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                for (int i = 0; i < _flujoOptionKeys.length; i++) ...[
                  _buildFlujoRow(_flujoOptionKeys[i], lang),
                  if (i < _flujoOptionKeys.length - 1)
                    Divider(height: 1),
                ],
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlujoRow(String key, String lang) {
    final isSelected = _selectedFlujosKeys.contains(key);
    return InkWell(
      onTap: () => _toggleFlujo(key),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.get('registration_form', key, lang),
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).bellotaColors.textoDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    AppTranslations.get('registration_form', '${key}_info', lang),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).bellotaColors.textoMedio,
                    ),
                  ),
                ],
              ),
            ),
            _buildFertilityBadge(key, lang),
            SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: isSelected ? null : Border.all(
                  color: Theme.of(context).bellotaColors.textoMedio.withValues(alpha: 0.4),
                  width: 2,
                ),
                color: isSelected ? Theme.of(context).bellotaColors.chilero : Colors.transparent,
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
}

