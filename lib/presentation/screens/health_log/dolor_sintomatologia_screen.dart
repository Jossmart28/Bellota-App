import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bellotadevelopment/presentation/common/breast_exam_guide_overlay.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

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
  late Set<String> _sintomasFisicosKeys; // Kept for backward compatibility in state
  late Set<String> _sintomasEmocionalKeys; // Kept for backward compatibility in state
  late Set<String> _sintomasCicloKeys;
  late String _autoexamenMamaKey;
  
  // Fertility data (Otros)
  double? _basalTemp;
  String? _lhTestResult;
  String? _cervicalPosition;

  final List<String> _caracterDolorOptions = ['incapacitating', 'not_incapacitating'];
  final List<String> _tratamientoOptions = ['medication', 'thermal_remedies', 'none'];
  final List<String> _sintomasCicloOptions = ['severe_cramps', 'menstrual_migraine', 'mastalgia'];
  
  final List<String> _autoexamenMamaOptions = [
    'breast_normal', 'breast_lump', 'breast_localized_pain', 
    'breast_skin_change', 'breast_discharge', 'breast_pending'
  ];
  
  final List<String> _lhTestOptions = ['negative', 'positive', 'peak'];
  final List<String> _cervicalPositionOptions = ['low_firm', 'mid', 'high_soft'];

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Solo inicializamos valores que NO requieren context/localizations
    _nivelDolor = widget.initialData['nivelDolor']?.toDouble() ?? 0.0;
    _diasDolorController = TextEditingController(text: widget.initialData['diasDolor'] ?? '');
    _basalTemp = widget.initialData['basalTemp'];
    _lhTestResult = widget.initialData['lhTestResult'];
    _cervicalPosition = widget.initialData['cervicalPosition'];

    _sintomasFisicosKeys = {};
    if (widget.initialData['sintomasFisicosKeys'] != null) {
      _sintomasFisicosKeys = Set<String>.from(widget.initialData['sintomasFisicosKeys']);
    }
    _sintomasEmocionalKeys = {};
    if (widget.initialData['sintomasEmocionalKeys'] != null) {
      _sintomasEmocionalKeys = Set<String>.from(widget.initialData['sintomasEmocionalKeys']);
    }
    _sintomasCicloKeys = {};
    if (widget.initialData['sintomasCicloKeys'] != null) {
      _sintomasCicloKeys = Set<String>.from(widget.initialData['sintomasCicloKeys']);
    } else {
      for (var k in _sintomasFisicosKeys) {
        if (_sintomasCicloOptions.contains(k)) _sintomasCicloKeys.add(k);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    // AquÃ­ sÃ­ podemos usar context (AppLocalizations, AppTranslations)
    final lang = languageNotifier.currentLang;
    _caracterDolorKey = widget.initialData['caracterDolorKey'] ??
        _mapCaracterDolor(widget.initialData['caracterDolor'], lang);
    _tratamientoKey = widget.initialData['tratamientoKey'] ??
        _mapTratamiento(widget.initialData['tratamiento'], lang);
    _autoexamenMamaKey = widget.initialData['autoexamenMamaKey'] ??
        _mapAutoexamenMama(widget.initialData['autoexamenMama'], lang);
  }

  String _mapCaracterDolor(String? val, String lang) {
    if (val == null) return 'not_incapacitating';
    if (_caracterDolorOptions.contains(val)) return val;
    for (var k in _caracterDolorOptions) {
      if (AppTranslations.get('registration_form', k, lang, context: context) == val) return k;
    }
    return 'not_incapacitating';
  }

  String _mapTratamiento(String? val, String lang) {
    if (val == null) return 'none';
    if (_tratamientoOptions.contains(val)) return val;
    for (var k in _tratamientoOptions) {
      if (AppTranslations.get('registration_form', k, lang, context: context) == val) return k;
    }
    if (val.toLowerCase() == 'ninguno') return 'none';
    return 'none';
  }

  String _mapAutoexamenMama(String? val, String lang) {
    if (val == null) return 'breast_pending';
    if (_autoexamenMamaOptions.contains(val)) return val;
    if (val == AppLocalizations.of(context)!.registrationFormDone || val.toLowerCase() == 'realizado') return 'breast_normal';
    if (val == AppLocalizations.of(context)!.registrationFormPending || val.toLowerCase() == 'pendiente') return 'breast_pending';
    return 'breast_pending';
  }

  @override
  void dispose() {
    _diasDolorController.dispose();
    super.dispose();
  }

  void _save() {
    final lang = languageNotifier.currentLang;
    
    // Ensure legacy sets have the new cycle keys updated
    final updatedFisicos = Set<String>.from(_sintomasFisicosKeys);
    for (var opt in _sintomasCicloOptions) {
      if (_sintomasCicloKeys.contains(opt)) {
        updatedFisicos.add(opt);
      } else {
        updatedFisicos.remove(opt);
      }
    }

    Navigator.pop(context, {
      'nivelDolor': _nivelDolor,
      'caracterDolorKey': _caracterDolorKey,
      'diasDolor': _diasDolorController.text.trim(),
      'tratamientoKey': _tratamientoKey,
      'sintomasFisicosKeys': updatedFisicos.toList(),
      'sintomasEmocionalKeys': _sintomasEmocionalKeys.toList(),
      'sintomasCicloKeys': _sintomasCicloKeys.toList(),
      'autoexamenMamaKey': _autoexamenMamaKey,
      
      'basalTemp': _basalTemp,
      'lhTestResult': _lhTestResult,
      'cervicalPosition': _cervicalPosition,
      
      // Backward compatibility keys
      'caracterDolor': AppTranslations.get('registration_form', _caracterDolorKey, lang, context: context),
      'tratamiento': AppTranslations.get('registration_form', _tratamientoKey, lang, context: context),
      'autoexamenMama': AppTranslations.get('registration_form', _autoexamenMamaKey, lang, context: context),
      'sintomasFisicos': updatedFisicos.map((k) => AppTranslations.get('registration_form', k, lang, context: context)).toList(),
      'sintomasEmocionales': _sintomasEmocionalKeys.map((k) => AppTranslations.get('registration_form', k, lang, context: context)).toList(),
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
    if (value <= 3) return 'ðŸ˜•';
    if (value <= 6) return 'ðŸ˜£';
    if (value <= 8) return 'ðŸ˜–';
    return 'ðŸ˜­';
  }

  Widget _buildSectionBadge(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).bellotaColors.blanco,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTreatmentPills(String lang) {
    return Row(
      children: _tratamientoOptions.map((opt) {
        final isSelected = _tratamientoKey == opt;
        final color = isSelected ? Theme.of(context).bellotaColors.asuncion : Theme.of(context).bellotaColors.nancite;
        final textColor = isSelected ? Colors.white : Theme.of(context).bellotaColors.textoMedio;
        
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tratamientoKey = opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                AppTranslations.get('registration_form', opt, lang, context: context),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiChoiceChips({required List<String> options, required Set<String> selected, required Function(String) onToggle, required String lang}) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return FilterChip(
          showCheckmark: false,
          label: Text(AppTranslations.get('registration_form', opt, lang, context: context)),
          selected: isSelected,
          onSelected: (_) => onToggle(opt),
          selectedColor: Theme.of(context).bellotaColors.chilero,
          backgroundColor: Theme.of(context).bellotaColors.nancite,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Theme.of(context).bellotaColors.textoDark,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBreastExamGrid(String lang) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: _autoexamenMamaOptions.map((opt) {
        final isSelected = _autoexamenMamaKey == opt;
        
        IconData icon;
        Color activeColor;
        switch (opt) {
          case 'breast_normal':
            icon = Icons.check_circle_outline;
            activeColor = Colors.green;
            break;
          case 'breast_lump':
            icon = Icons.warning_amber_rounded;
            activeColor = Colors.orange;
            break;
          case 'breast_localized_pain':
            icon = Icons.pin_drop_outlined;
            activeColor = Colors.red;
            break;
          case 'breast_skin_change':
            icon = Icons.texture_outlined;
            activeColor = Colors.purple;
            break;
          case 'breast_discharge':
            icon = Icons.water_drop_outlined;
            activeColor = Colors.blue;
            break;
          case 'breast_pending':
          default:
            icon = Icons.schedule_outlined;
            activeColor = Colors.grey;
            break;
        }

        final bgColor = isSelected ? activeColor.withValues(alpha: 0.15) : Theme.of(context).bellotaColors.nancite;
        final iconColor = isSelected ? activeColor : Theme.of(context).bellotaColors.textoMedio;
        final textColor = isSelected ? activeColor : Theme.of(context).bellotaColors.textoMedio;

        return GestureDetector(
          onTap: () => setState(() => _autoexamenMamaKey = opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? Border.all(color: activeColor.withValues(alpha: 0.5), width: 1.5) : Border.all(color: Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppTranslations.get('registration_form', opt, lang, context: context),
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
        final colors = Theme.of(context).bellotaColors;
        return Scaffold(
          backgroundColor: colors.basilica,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(colors),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      // Pain Card
                      _buildPainCard(colors),
                      const SizedBox(height: 12),
                      
                      // Tratamiento Card
                      _buildTratamientoCard(colors, lang),
                      const SizedBox(height: 12),
                      
                      // Otros datos Card
                      _buildOtrosDatosCard(colors, lang),
                      const SizedBox(height: 12),
                      
                      // Autoexamen Card
                      _buildAutoexamenCard(colors, lang),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BellotaColors colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.chilero,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.chilero.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          Text(
            'Dolor y síntomas',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          GestureDetector(
            onTap: _save,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Confirmar',
                style: GoogleFonts.poppins(color: colors.chilero, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainCard(BellotaColors colors) {
    // Determine color based on pain level
    Color headerColor = colors.textoMedio;
    String textDesc = 'Sin dolor';
    if (_nivelDolor > 0 && _nivelDolor <= 3) { headerColor = Colors.orange; textDesc = 'Leve'; }
    else if (_nivelDolor > 3 && _nivelDolor <= 6) { headerColor = colors.melon; textDesc = 'Moderado'; }
    else if (_nivelDolor > 6) { headerColor = colors.chilero; textDesc = 'Fuerte'; }
    if (_nivelDolor == 0) headerColor = Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.textoMedio.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ¿Cuánto duele?
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('¿Cuánto duele?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: colors.textoDark)),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: '$textDesc • ', style: GoogleFonts.poppins(color: headerColor, fontWeight: FontWeight.w600, fontSize: 13)),
                    TextSpan(text: '${_nivelDolor.toInt()}', style: GoogleFonts.poppins(color: headerColor, fontWeight: FontWeight.bold, fontSize: 18)),
                    TextSpan(text: '/10', style: GoogleFonts.poppins(color: headerColor.withOpacity(0.6), fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Acorn slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (index) {
              final val = index + 1;
              final isSelected = val <= _nivelDolor;
              // Staggered bounce: selected bellotas animate with delay per index
              final delay = isSelected ? Duration(milliseconds: index * 35) : Duration.zero;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _nivelDolor = val.toDouble());
                },
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('acorn_$val${isSelected}'),
                  tween: Tween(begin: isSelected ? 0.6 : 1.0, end: isSelected ? 1.0 : 1.0),
                  duration: Duration(milliseconds: 350) + delay,
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/bellota_outline_white.png',
                        width: 22,
                        height: 22,
                        color: isSelected ? const Color(0xFFDAB398) : colors.textoMedio.withOpacity(0.2),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$val',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFFDAB398) : colors.textoMedio.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          
          // Carácter
          Text('CARÁCTER', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: colors.textoDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _caracterDolorKey = 'incapacitating'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _caracterDolorKey == 'incapacitating' ? colors.nancite : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _caracterDolorKey == 'incapacitating' ? const Color(0xFFDAB398) : colors.nancite),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block_rounded, color: _caracterDolorKey == 'incapacitating' ? const Color(0xFF6B3A22) : colors.textoMedio, size: 18),
                        const SizedBox(width: 8),
                        Text('Incapacitante', style: GoogleFonts.poppins(color: _caracterDolorKey == 'incapacitating' ? const Color(0xFF6B3A22) : colors.textoMedio, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _caracterDolorKey = 'not_incapacitating'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _caracterDolorKey == 'not_incapacitating' ? colors.nancite : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _caracterDolorKey == 'not_incapacitating' ? const Color(0xFFDAB398) : colors.nancite),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_walk_rounded, color: _caracterDolorKey == 'not_incapacitating' ? const Color(0xFF6B3A22) : colors.textoMedio, size: 18),
                        const SizedBox(width: 8),
                        Text('No incapacitante', style: GoogleFonts.poppins(color: _caracterDolorKey == 'not_incapacitating' ? const Color(0xFF6B3A22) : colors.textoMedio, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionCard({
    required BellotaColors colors,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    Widget? trailingTitleWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.textoMedio.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          iconColor: colors.textoDark,
          collapsedIconColor: colors.textoDark,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: colors.textoDark),
                ),
              ),
              if (trailingTitleWidget != null) trailingTitleWidget,
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTratamientoCard(BellotaColors colors, String lang) {
    return _buildAccordionCard(
      colors: colors,
      title: 'Tratamiento',
      icon: Icons.medication_rounded,
      iconColor: colors.chilero.withOpacity(0.8),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _tratamientoOptions.map((opt) {
            final isSelected = _tratamientoKey == opt;
            return GestureDetector(
              onTap: () => setState(() => _tratamientoKey = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? colors.nancite : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFFDAB398) : colors.nancite),
                ),
                child: Text(
                  AppTranslations.get('registration_form', opt, lang, context: context),
                  style: GoogleFonts.poppins(
                    color: isSelected ? const Color(0xFF6B3A22) : colors.textoDark,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOtrosDatosCard(BellotaColors colors, String lang) {
    return _buildAccordionCard(
      colors: colors,
      title: 'Otros datos',
      icon: Icons.science_rounded,
      iconColor: colors.melon,
      children: [
        Text('Temperatura basal', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textoDark)),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: _basalTemp?.toString() ?? ''),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Ej: 36.5',
            suffixText: '°C',
            filled: true,
            fillColor: colors.nancite,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (val) {
            final numVal = double.tryParse(val.replaceAll(',', '.'));
            if (numVal != null && numVal >= 35.0 && numVal <= 42.0) _basalTemp = numVal;
            else if (val.isEmpty) _basalTemp = null;
          },
        ),
        const SizedBox(height: 16),
        Text('Test LH', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: colors.textoDark)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _lhTestOptions.map((opt) {
            final isSelected = _lhTestResult == opt;
            String label = opt == 'negative' ? 'Negativo' : opt == 'positive' ? 'Positivo' : 'Pico';
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _lhTestResult = isSelected ? null : opt),
              selectedColor: colors.melon.withOpacity(0.2),
              backgroundColor: colors.nancite,
              side: BorderSide.none,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAutoexamenCard(BellotaColors colors, String lang) {
    return _buildAccordionCard(
      colors: colors,
      title: 'Autoexamen de mama',
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFFDE8B90),
      trailingTitleWidget: IconButton(
        icon: const Icon(Icons.help_outline, color: Color(0xFFB45A61)),
        onPressed: () {
          showDialog(
            context: context,
            barrierColor: Colors.transparent,
            builder: (context) => Material(
              color: Colors.transparent,
              child: BreastExamGuideOverlay(
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
          );
        },
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDE8B90).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFB45A61), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cada mes, 7 a 10 días después del inicio del período.',
                  style: GoogleFonts.poppins(color: const Color(0xFFB45A61), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _autoexamenMamaOptions.map((opt) {
            final isSelected = _autoexamenMamaKey == opt;
            IconData iconData = Icons.circle_outlined;
            String label = '';
            if (opt == 'breast_normal') { iconData = Icons.check_circle_rounded; label = 'Normal'; }
            else if (opt == 'breast_lump') { iconData = Icons.warning_amber_rounded; label = 'Bulto palpado'; }
            else if (opt == 'breast_localized_pain') { iconData = Icons.location_on_rounded; label = 'Dolor localizado'; }
            else if (opt == 'breast_skin_change') { iconData = Icons.layers_rounded; label = 'Cambio en piel'; }
            else if (opt == 'breast_discharge') { iconData = Icons.water_drop_rounded; label = 'Secreción inusual'; }
            else if (opt == 'breast_pending') { iconData = Icons.schedule_rounded; label = 'Pendiente'; }

            return GestureDetector(
              onTap: () => setState(() => _autoexamenMamaKey = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? (opt == 'breast_normal' ? Colors.green.withOpacity(0.1) : const Color(0xFFDE8B90).withOpacity(0.1)) : colors.nancite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? (opt == 'breast_normal' ? Colors.green.withOpacity(0.3) : const Color(0xFFB45A61).withOpacity(0.3)) : colors.nancite),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconData, 
                      color: isSelected ? (opt == 'breast_normal' ? Colors.green : const Color(0xFFB45A61)) : colors.textoMedio, 
                      size: 16
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: isSelected ? (opt == 'breast_normal' ? Colors.green.shade800 : const Color(0xFFB45A61)) : colors.textoDark,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
