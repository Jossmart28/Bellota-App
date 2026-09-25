import 'package:bellotadevelopment/l10n/language_notifier.dart';
import 'package:flutter/material.dart';
import 'package:bellotadevelopment/l10n/app_translations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/bellota_colors.dart';
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

  @override
  void initState() {
    super.initState();
    final lang = languageNotifier.currentLang;
    
    _nivelDolor = widget.initialData['nivelDolor']?.toDouble() ?? 0.0;
    
    _caracterDolorKey = widget.initialData['caracterDolorKey'] ?? 
        _mapCaracterDolor(widget.initialData['caracterDolor'], lang);
        
    _diasDolorController = TextEditingController(text: widget.initialData['diasDolor'] ?? '');
    
    _tratamientoKey = widget.initialData['tratamientoKey'] ?? 
        _mapTratamiento(widget.initialData['tratamiento'], lang);
    
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
      // Migrate from old physical symptoms if available
      for (var k in _sintomasFisicosKeys) {
        if (_sintomasCicloOptions.contains(k)) {
          _sintomasCicloKeys.add(k);
        }
      }
    }
    
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
    if (value == 0) return '😌';
    if (value <= 3) return '😕';
    if (value <= 6) return '😣';
    if (value <= 8) return '😖';
    return '😭';
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
        return Scaffold(
          backgroundColor: Theme.of(context).bellotaColors.basilica,
          appBar: AppBar(
            backgroundColor: Theme.of(context).bellotaColors.blanco,
            elevation: 0,
            leading: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.registrationFormCancel,
                style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoDark),
              ),
            ),
            leadingWidth: 80,
            title: Text(
              AppLocalizations.of(context)!.registrationFormPainAndSymptoms,
              style: GoogleFonts.poppins(
                color: Theme.of(context).bellotaColors.textoDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: _save,
                child: Text(
                  AppLocalizations.of(context)!.onboardingConfirm,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).bellotaColors.chilero,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            children: [
              // Nivel de dolor
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionBadge(AppLocalizations.of(context)!.registrationFormPainLevel, Icons.thermostat_rounded, Theme.of(context).bellotaColors.chilero),
                    const SizedBox(height: 24),
                    
                    // Emoji central grande
                    Center(
                      child: Column(
                        children: [
                          Text(
                            _getPainEmoji(_nivelDolor),
                            style: const TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_nivelDolor.toInt()} / 10',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).bellotaColors.chilero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 12,
                        activeTrackColor: Theme.of(context).bellotaColors.chilero,
                        inactiveTrackColor: Theme.of(context).bellotaColors.nancite,
                        thumbColor: Theme.of(context).bellotaColors.blanco,
                        overlayColor: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4),
                      ),
                      child: Slider(
                        value: _nivelDolor,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        onChanged: (val) => setState(() => _nivelDolor = val),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context)!.registrationFormPainNone, style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).bellotaColors.textoMedio)),
                        Text(AppLocalizations.of(context)!.registrationFormPainIncapacitating, style: GoogleFonts.poppins(fontSize: 11, color: Theme.of(context).bellotaColors.textoMedio)),
                      ],
                    ),

                    // Alerta clínica
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _nivelDolor >= 8 ? null : 0,
                      child: _nivelDolor >= 8
                          ? Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Theme.of(context).bellotaColors.chilero.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).bellotaColors.chilero, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)!.registrationFormPainAlertMsg,
                                      style: GoogleFonts.poppins(fontSize: 13, color: Theme.of(context).bellotaColors.chilero, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Carácter del dolor
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionBadge(AppLocalizations.of(context)!.registrationFormCharacter, Icons.category_outlined, Theme.of(context).bellotaColors.asuncion),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _caracterDolorKey = 'incapacitating'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _caracterDolorKey == 'incapacitating' ? Colors.red.shade50 : Theme.of(context).bellotaColors.nancite,
                                borderRadius: BorderRadius.circular(16),
                                border: _caracterDolorKey == 'incapacitating' ? Border.all(color: Colors.red.shade200) : Border.all(color: Colors.transparent),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.personal_injury_rounded, color: _caracterDolorKey == 'incapacitating' ? Colors.red : Theme.of(context).bellotaColors.textoMedio, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!.registrationFormIncapacitating,
                                    style: GoogleFonts.poppins(
                                      color: _caracterDolorKey == 'incapacitating' ? Colors.red.shade700 : Theme.of(context).bellotaColors.textoMedio,
                                      fontWeight: _caracterDolorKey == 'incapacitating' ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _caracterDolorKey == 'not_incapacitating' ? Colors.green.shade50 : Theme.of(context).bellotaColors.nancite,
                                borderRadius: BorderRadius.circular(16),
                                border: _caracterDolorKey == 'not_incapacitating' ? Border.all(color: Colors.green.shade200) : Border.all(color: Colors.transparent),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.directions_walk_rounded, color: _caracterDolorKey == 'not_incapacitating' ? Colors.green : Theme.of(context).bellotaColors.textoMedio, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!.registrationFormNotIncapacitating,
                                    style: GoogleFonts.poppins(
                                      color: _caracterDolorKey == 'not_incapacitating' ? Colors.green.shade700 : Theme.of(context).bellotaColors.textoMedio,
                                      fontWeight: _caracterDolorKey == 'not_incapacitating' ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _diasDolorController,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.registrationFormCriticalPainDays,
                        hintStyle: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoMedio),
                        filled: true,
                        fillColor: Theme.of(context).bellotaColors.basilica,
                        prefixIcon: Icon(Icons.calendar_today_rounded, color: Theme.of(context).bellotaColors.textoMedio),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),

              // Tratamiento
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionBadge(AppLocalizations.of(context)!.registrationFormTreatment, Icons.medical_services_outlined, Theme.of(context).bellotaColors.asuncion),
                    const SizedBox(height: 16),
                    _buildTreatmentPills(lang),
                  ],
                ),
              ),

              // Síntomas específicos del ciclo
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionBadge('🩺 Síntomas específicos del ciclo', Icons.accessibility_new_rounded, Theme.of(context).bellotaColors.chiltoma),
                    const SizedBox(height: 16),
                    _buildMultiChoiceChips(
                      options: _sintomasCicloOptions,
                      selected: _sintomasCicloKeys,
                      onToggle: (val) => _toggleSetItem(_sintomasCicloKeys, val),
                      lang: lang,
                    ),
                  ],
                ),
              ),

              // Otros (Fertilidad)
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionBadge('Otros', Icons.science_outlined, Theme.of(context).bellotaColors.melon),
                    const SizedBox(height: 16),
                    
                    // Temperatura Basal
                    Text(
                      'Temperatura Basal',
                      style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _basalTemp?.toString(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Ej: 36.5',
                              hintStyle: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoMedio, fontSize: 13),
                              suffixText: '°C',
                              filled: true,
                              fillColor: Theme.of(context).bellotaColors.nancite,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                            onChanged: (val) {
                              final numVal = double.tryParse(val.replaceAll(',', '.'));
                              if (numVal != null && numVal >= 35.0 && numVal <= 42.0) {
                                _basalTemp = numVal;
                              } else if (val.isEmpty) {
                                _basalTemp = null;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Test de LH
                    Text(
                      'Test de LH (Ovulación)',
                      style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _lhTestOptions.map((opt) {
                        final isSelected = _lhTestResult == opt;
                        String label = '';
                        switch (opt) {
                          case 'negative': label = 'Negativo'; break;
                          case 'positive': label = 'Positivo'; break;
                          case 'peak': label = 'Pico'; break;
                        }
                        return FilterChip(
                          showCheckmark: false,
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _lhTestResult = isSelected ? null : opt),
                          selectedColor: Theme.of(context).bellotaColors.melon,
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
                    ),
                    const SizedBox(height: 16),
                    
                    // Posición Cervical
                    Text(
                      'Posición Cervical',
                      style: GoogleFonts.poppins(color: Theme.of(context).bellotaColors.textoDark, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _cervicalPositionOptions.map((opt) {
                        final isSelected = _cervicalPosition == opt;
                        String label = '';
                        switch (opt) {
                          case 'low_firm': label = 'Bajo'; break;
                          case 'mid': label = 'Medio'; break;
                          case 'high_soft': label = 'Alto'; break;
                        }
                        return FilterChip(
                          showCheckmark: false,
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _cervicalPosition = isSelected ? null : opt),
                          selectedColor: Theme.of(context).bellotaColors.chiltoma,
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
                    ),
                  ],
                ),
              ),

              // Autoexamen de mama
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionBadge(AppLocalizations.of(context)!.registrationFormBreastExam, Icons.favorite_border_rounded, const Color(0xFFA566C1)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA566C1).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFA566C1), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.registrationFormBreastExamInfo,
                              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFA566C1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildBreastExamGrid(lang),
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
