import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

class SexoSelectionScreen extends StatefulWidget {
  final List<String> initialSelectedSexo;

  SexoSelectionScreen({super.key, required this.initialSelectedSexo});

  @override
  State<SexoSelectionScreen> createState() => _SexoSelectionScreenState();
}

class _SexoSelectionScreenState extends State<SexoSelectionScreen> {
  late Set<String> _selectedSexoKeys;

  final List<String> _sexoOptionKeys = [
    'no_contraception',
    'condom',
    'no_ejaculation',
    'short_pill',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSexoKeys = Set.from(widget.initialSelectedSexo);
  }

  void _toggleSexo(String key) {
    setState(() {
      if (key == 'no_contraception') {
        if (_selectedSexoKeys.contains('no_contraception')) {
          _selectedSexoKeys.remove('no_contraception');
        } else {
          _selectedSexoKeys.clear();
          _selectedSexoKeys.add('no_contraception');
        }
      } else {
        if (_selectedSexoKeys.contains(key)) {
          _selectedSexoKeys.remove(key);
        } else {
          _selectedSexoKeys.remove('no_contraception');
          _selectedSexoKeys.add(key);
        }
      }
    });
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
            AppTranslations.get('registration_form', 'cancel', lang),
            style: TextStyle(color: Theme.of(context).bellotaColors.chilero, fontSize: 16),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          AppTranslations.get('registration_form', 'sex', lang),
          style: TextStyle(color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedSexoKeys.toList());
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
                for (int i = 0; i < _sexoOptionKeys.length; i++) ...[
                  _buildSexoRow(_sexoOptionKeys[i], lang),
                  if (i < _sexoOptionKeys.length - 1)
                    Divider(height: 1),
                ],
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
        },
    );
  }

  Widget _buildSexoRow(String key, String lang) {
    final isSelected = _selectedSexoKeys.contains(key);

    IconData iconData;
    Color iconColor;

    switch (key) {
      case 'no_contraception':
        iconData = Icons.do_not_disturb_alt_outlined;
        iconColor = Theme.of(context).bellotaColors.chiltoma;
        break;
      case 'condom':
        iconData = Icons.shield_outlined;
        iconColor = Theme.of(context).bellotaColors.asuncion;
        break;
      case 'no_ejaculation':
        iconData = Icons.block_outlined;
        iconColor = Theme.of(context).bellotaColors.melon;
        break;
      case 'short_pill':
      default:
        iconData = Icons.medication_outlined;
        iconColor = Theme.of(context).bellotaColors.chilero;
        break;
    }

    return InkWell(
      onTap: () => _toggleSexo(key),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            SizedBox(width: 12),
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
                ],
              ),
            ),
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

