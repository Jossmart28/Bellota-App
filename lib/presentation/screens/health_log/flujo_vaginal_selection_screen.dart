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
  // Fisiológico: solo una a la vez (radio)
  String? _selectedFisiologico;
  // Anormal: múltiple selección (checkbox)
  final Set<String> _selectedAnormal = {};

  static const List<String> _fisiologicoOptions = ['dry', 'sticky', 'creamy', 'watery', 'egg_white'];
  static const List<String> _anormalOptions = ['yellow_green', 'cottage_cheese', 'foul_odor'];

  final List<Map<String, dynamic>> _sections = [
    {
      'titleKey': 'Fisiológico (Normal)',
      'subtitle': 'Elige cómo lo notaste hoy',
      'icon': Icons.water_drop_rounded,
      'isBlue': true,
      'options': _fisiologicoOptions,
    },
    {
      'titleKey': 'Anormal (Posible Infección)',
      'subtitle': 'Puedes elegir varias',
      'icon': Icons.warning_amber_rounded,
      'isBlue': false,
      'options': _anormalOptions,
    },
  ];

  @override
  void initState() {
    super.initState();
    for (final key in widget.initialSelectedFlujos) {
      if (_fisiologicoOptions.contains(key)) {
        _selectedFisiologico = key;
      } else if (_anormalOptions.contains(key)) {
        _selectedAnormal.add(key);
      }
    }
  }

  List<String> get _allSelected {
    final result = <String>[];
    if (_selectedFisiologico != null) result.add(_selectedFisiologico!);
    result.addAll(_selectedAnormal);
    return result;
  }

  void _toggleFisiologico(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedFisiologico == key) {
        _selectedFisiologico = null;
      } else {
        _selectedFisiologico = key;
      }
    });
  }

  void _toggleAnormal(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedAnormal.contains(key)) {
        _selectedAnormal.remove(key);
      } else {
        _selectedAnormal.add(key);
      }
    });
  }

  int _getFertilityLevel(String key) {
    switch (key) {
      case 'dry': return 1;
      case 'sticky': return 1;
      case 'creamy': return 2;
      case 'watery': return 3;
      case 'egg_white': return 4;
      default: return 0;
    }
  }

  Widget _buildFertilityBadge(String key, bool isSelected) {
    final level = _getFertilityLevel(key);
    if (level == 0) return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final isActive = i < level;
        return Padding(
          padding: const EdgeInsets.only(right: 2.0),
          child: AnimatedScale(
            scale: isSelected && isActive ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Image.asset(
              'assets/images/bellota_outline.png',
              width: 18,
              height: 18,
              color: isActive ? null : Colors.grey.shade300,
              colorBlendMode: isActive ? null : BlendMode.srcIn,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFisiologicoRow(String key, String lang) {
    final isSelected = _selectedFisiologico == key;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 1.0, end: isSelected ? 1.015 : 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: () => _toggleFisiologico(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              color: isSelected
                  ? Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.05)
                  : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppTranslations.get('registration_form', key, lang, context: context),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).bellotaColors.textoDark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  _buildFertilityBadge(key, isSelected),
                  const SizedBox(width: 12),
                  // Radio circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
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
                        ? const Icon(Icons.circle, size: 10, color: Colors.white)
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

  Widget _buildAnormalRow(String key, String lang) {
    final isSelected = _selectedAnormal.contains(key);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 1.0, end: isSelected ? 1.015 : 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: InkWell(
            onTap: () => _toggleAnormal(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              color: isSelected
                  ? Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.05)
                  : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppTranslations.get('registration_form', key, lang, context: context),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).bellotaColors.textoDark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Square checkbox
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
                // Header pill
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
                        // Cancelar
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
                        // Título centro
                        Expanded(
                          child: Text(
                            loc.registrationFormVaginalFlow,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        // Confirmar
                        TextButton(
                          onPressed: () => Navigator.pop(context, _allSelected),
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
                // Content
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _sections.length,
                    itemBuilder: (context, sIndex) {
                      final section = _sections[sIndex];
                      final options = section['options'] as List<String>;
                      final isBlue = section['isBlue'] as bool;
                      final isFisiologico = sIndex == 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
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
                                    color: isBlue
                                        ? Theme.of(context).bellotaColors.asuncion
                                        : Theme.of(context).bellotaColors.melon,
                                  ),
                                  child: Icon(
                                    section['icon'] as IconData,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        section['titleKey'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).bellotaColors.textoDark,
                                        ),
                                      ),
                                      Text(
                                        section['subtitle'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).bellotaColors.textoMedio,
                                        ),
                                      ),
                                    ],
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
                                    isFisiologico
                                        ? _buildFisiologicoRow(optKey, lang)
                                        : _buildAnormalRow(optKey, lang),
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
                          // Footer hint for fisiologico
                          if (isFisiologico)
                            Padding(
                              padding: const EdgeInsets.only(left: 20, top: 6),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/bellota_outline.png',
                                    width: 14,
                                    height: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Más bellotas, más fértil.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).bellotaColors.textoMedio,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
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
