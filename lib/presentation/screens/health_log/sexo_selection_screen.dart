import 'package:flutter/material.dart';
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
      'icon': Icons.favorite_rounded,
      'color': 'chilero',
      'options': ['protected', 'unprotected', 'masturbation', 'high_libido'],
    },
    {
      'titleKey': 'Anticoncepción / Protección',
      'icon': Icons.shield_rounded,
      'color': 'melon',
      'options': ['no_contraception', 'condom', 'no_ejaculation', 'short_pill'],
    },
    {
      'titleKey': 'Complicaciones y Síntomas',
      'icon': Icons.healing_rounded,
      'color': 'chilero',
      'options': ['pain_during_sex', 'unprotected_new_partner'],
    },
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

  IconData _getIconFor(String key) {
    switch (key) {
      case 'protected': return Icons.shield_rounded;
      case 'unprotected': return Icons.warning_amber_rounded;
      case 'masturbation': return Icons.spa_rounded;
      case 'high_libido': return Icons.local_fire_department_rounded;
      case 'no_contraception': return Icons.block_rounded;
      case 'condom': return Icons.security_rounded;
      case 'no_ejaculation': return Icons.bolt_rounded;
      case 'short_pill': return Icons.medication_rounded;
      case 'pain_during_sex': return Icons.healing_rounded;
      case 'unprotected_new_partner': return Icons.person_add_alt_1_rounded;
      default: return Icons.favorite_rounded;
    }
  }

  Color _sectionColor(BuildContext context, String colorKey) {
    if (colorKey == 'melon') return Theme.of(context).bellotaColors.melon;
    return Theme.of(context).bellotaColors.chilero;
  }

  Widget _buildRow(String key, String lang) {
    final isSelected = _selectedSexoKeys.contains(key);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 1.0, end: isSelected ? 1.015 : 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: () => _toggleSexo(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              color: isSelected
                  ? Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.05)
                  : Colors.transparent,
              child: Row(
                children: [
                  // Icon circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      _getIconFor(key),
                      size: 20,
                      color: Theme.of(context).bellotaColors.chilero,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Label
                  Expanded(
                    child: Text(
                      AppTranslations.get('registration_form', key, lang, context: context),
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).bellotaColors.textoDark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: isSelected
                          ? Theme.of(context).bellotaColors.chilero
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).bellotaColors.chilero
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        final loc = AppLocalizations.of(context)!;
        return Scaffold(
          backgroundColor: Theme.of(context).bellotaColors.basilica,
          body: SafeArea(
            child: Column(
              children: [
                // Header pill — same style as flujo vaginal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: Theme.of(context).bellotaColors.buttonGradient,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            loc.registrationFormCancel,
                            style: TextStyle(
                              color: Theme.of(context).bellotaColors.chilero,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            loc.registrationFormSex,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, _selectedSexoKeys.toList()),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            loc.onboardingConfirm,
                            style: TextStyle(
                              color: Theme.of(context).bellotaColors.chilero,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _sections.length,
                    itemBuilder: (context, sIndex) {
                      final section = _sections[sIndex];
                      final options = section['options'] as List<String>;
                      final sectionColor = _sectionColor(context, section['color'] as String);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header (icon + title only, NO subtitle)
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8, right: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: sectionColor,
                                  ),
                                  child: Icon(
                                    section['icon'] as IconData,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  section['titleKey'] as String,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).bellotaColors.textoDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Options card
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).bellotaColors.melon.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
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
                                      Divider(
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                        color: Colors.grey.shade100,
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
