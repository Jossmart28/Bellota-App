import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

class FlujoVaginalSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedFlujos;

  const FlujoVaginalSelectionScreen({super.key, required this.initialSelectedFlujos});

  @override
  State<FlujoVaginalSelectionScreen> createState() => _FlujoVaginalSelectionScreenState();
}

class _FlujoVaginalSelectionScreenState extends State<FlujoVaginalSelectionScreen> {
  late Set<String> _selectedFlujos;

  final List<String> _flujoOptions = [
    AppTranslations.get('registration_form', 'dry', languageNotifier.currentLang),
    AppTranslations.get('registration_form', 'thick', languageNotifier.currentLang),
    AppTranslations.get('registration_form', 'liquid_elastic', languageNotifier.currentLang),
    AppTranslations.get('registration_form', 'watery', languageNotifier.currentLang),
    AppTranslations.get('registration_form', 'egg_white', languageNotifier.currentLang),
  ];

  @override
  void initState() {
    super.initState();
    _selectedFlujos = Set.from(widget.initialSelectedFlujos);
  }

  void _toggleFlujo(String flujo) {
    setState(() {
      if (_selectedFlujos.contains(flujo)) {
        _selectedFlujos.remove(flujo);
      } else {
        _selectedFlujos.add(flujo);
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
        title: Text(AppTranslations.get('registration_form', 'vaginal_flow', languageNotifier.currentLang), style: TextStyle(color: BellotaColors.textoDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedFlujos.toList());
            },
            child: Text(AppTranslations.get('onboarding', 'confirm', languageNotifier.currentLang), style: TextStyle(color: BellotaColors.chilero, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Container(
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
                SizedBox(height: 8),
                ..._flujoOptions.map((flujo) => _buildFlujoRow(flujo)),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlujoRow(String flujo) {
    final isSelected = _selectedFlujos.contains(flujo);
    return InkWell(
      onTap: () => _toggleFlujo(flujo),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                flujo,
                style: TextStyle(
                  fontSize: 16,
                  color: BellotaColors.textoDark,
                ),
              ),
            ),
            // Círculo seleccionable
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
}
