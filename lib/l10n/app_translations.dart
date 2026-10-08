import 'package:flutter/widgets.dart';
import 'package:bellotadevelopment/l10n/app_localizations.dart';

class AppTranslations {
  static const List<String> medicationKeys = [
    'none',
    'combined_pill',
    'progestin_pill',
    'ring',
    'patch',
    'hormonal_iud',
    'copper_iud',
    'implant',
    'injection',
    'other',
  ];

  static String get(String category, String key, String? lang, {BuildContext? context}) {
    if (context != null) {
      final loc = AppLocalizations.of(context)!;
      final camelKey = _toCamelCase(category, key);
      final mapped = _lookup(loc, camelKey);
      if (mapped != null) return mapped;
    }
    
    // Fallback manual dictionary si falla gen-l10n o si el key es nuevo
    final isEs = lang == 'es';
    return _manualFallback[key]?[isEs ? 'es' : 'en'] ?? key.replaceAll('_', ' ');
  }

  static const Map<String, Map<String, String>> _manualFallback = {
    'light_flow': {'es': 'Flujo ligero', 'en': 'Light flow'},
    'moderate_flow': {'es': 'Flujo moderado', 'en': 'Moderate flow'},
    'heavy_flow': {'es': 'Flujo abundante', 'en': 'Heavy flow'},
    'bright_red': {'es': 'Rojo brillante', 'en': 'Bright red'},
    'dark_red': {'es': 'Rojo oscuro', 'en': 'Dark red'},
    'brown': {'es': 'Marrón', 'en': 'Brown'},
    'pink': {'es': 'Rosado', 'en': 'Pink'},
    'never': {'es': 'Nunca', 'en': 'Never'},
    'occasional': {'es': 'Ocasionales', 'en': 'Occasional'},
    'frequent': {'es': 'Frecuentes', 'en': 'Frequent'},
    'yes': {'es': 'Sí', 'en': 'Yes'},
    'no': {'es': 'No', 'en': 'No'},
    'thermal_remedies': {'es': 'Remedios térmicos', 'en': 'Thermal remedies'},
    'medication': {'es': 'Medicamentos', 'en': 'Medication'},
    'none': {'es': 'Ninguno', 'en': 'None'},

    'body_ache': {'es': 'Dolor corporal', 'en': 'Body ache'},
    'breast_lump': {'es': 'Bulto palpado', 'en': 'Breast lump'},
    'breast_skin_change': {'es': 'Cambio en piel', 'en': 'Skin change'},
    'breast_discharge': {'es': 'Secreción inusual', 'en': 'Unusual discharge'},
    'severe_pain': {'es': 'Dolor severo', 'en': 'Severe pain'},
    'pelvic_pain': {'es': 'Dolor pélvico', 'en': 'Pelvic pain'},
    'spotting': {'es': 'Manchado', 'en': 'Spotting'},
    'clots': {'es': 'Coágulos', 'en': 'Clots'},
    'heavy': {'es': 'Flujo abundante', 'en': 'Heavy flow'},
    'egg_white': {'es': 'Clara de huevo', 'en': 'Egg white'},
    'sticky': {'es': 'Pegajoso', 'en': 'Sticky'},
    'creamy': {'es': 'Cremoso', 'en': 'Creamy'},
    'watery': {'es': 'Acuoso', 'en': 'Watery'},
    'yellow_green': {'es': 'Amarillento/Verdoso', 'en': 'Yellow/Green'},
    'cottage_cheese': {'es': 'Grumoso', 'en': 'Cottage cheese'},
    'foul_odor': {'es': 'Mal olor', 'en': 'Foul odor'},
    'incapacitating': {'es': 'Incapacitante', 'en': 'Incapacitating'},
    'not_incapacitating': {'es': 'Leve/Manejable', 'en': 'Manageable'},
    'pain_during_sex': {'es': 'Dolor', 'en': 'Pain'},
    'unprotected_new_partner': {'es': 'Sin protección (nueva pareja)', 'en': 'Unprotected (new partner)'},
    'protected': {'es': 'Con protección', 'en': 'Protected'},
    'unprotected': {'es': 'Sin protección', 'en': 'Unprotected'},
    'masturbation': {'es': 'Masturbación', 'en': 'Masturbation'},
    'high_libido': {'es': 'Líbido alta', 'en': 'High libido'},
    'thick': {'es': 'Espeso', 'en': 'Thick'},
    'liquid_elastic': {'es': 'Líquido y elástico', 'en': 'Liquid & Elastic'},
    'no_contraception': {'es': 'Ninguno', 'en': 'None'},
    'condom': {'es': 'Preservativo', 'en': 'Condom'},
    'no_ejaculation': {'es': 'Sin eyaculación interna', 'en': 'No internal ejaculation'},
    'short_pill': {'es': 'Píldora del día después', 'en': 'Morning-after pill'},
    'light': {'es': 'Ligero', 'en': 'Light'},
    'medium': {'es': 'Medio', 'en': 'Medium'},
  };

  static String _toCamelCase(String cat, String key) {
    var parts = (cat.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') + '_' + key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')).split('_').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return "";
    var res = parts[0];
    for (var i = 1; i < parts.length; i++) {
      res += parts[i].substring(0, 1).toUpperCase() + parts[i].substring(1);
    }
    return res;
  }

  static String? _lookup(AppLocalizations loc, String camelKey) {
    // This is a minimal Map to avoid manual switch mapping.
    // We'll generate a Map of getters to resolve camelKey dynamically.
    // However, Dart doesn't have `loc[camelKey]`.
    return _dynamicMap(loc)[camelKey];
  }

  static Map<String, String> _dynamicMap(AppLocalizations loc) {
    return {
      // Common dynamic ones we found
      'registrationFormNone': loc.registrationFormNone,
      'registrationFormNoContraception': loc.registrationFormNoContraception,
      'registrationFormCondom': loc.registrationFormCondom,
      'registrationFormNoEjaculation': loc.registrationFormNoEjaculation,
      'registrationFormShortPill': loc.registrationFormShortPill,
      'registrationFormBreastTenderness': loc.registrationFormBreastTenderness,
      'registrationFormAbnormalDischarge': loc.registrationFormAbnormalDischarge,
      'profileAndReportDarkMode': loc.profileAndReportDarkMode,
      'symptomsCramps': loc.symptomsCramps,
      'symptomsFatigue': loc.symptomsFatigue,
      'symptomsHighEnergy': loc.symptomsHighEnergy,
      'symptomsSeverePain': loc.symptomsSeverePain,
      'symptomsSensitivity': loc.symptomsSensitivity,
      // Add all symptoms
      'registrationFormFever': loc.registrationFormFever,
      'registrationFormBodyAche': loc.registrationFormBodyAche,
      'registrationFormGeneralDistension': loc.registrationFormGeneralDistension,
      'registrationFormExtremeFatigue': loc.registrationFormExtremeFatigue,
      'registrationFormWaterRetention': loc.registrationFormWaterRetention,
      'registrationFormNightSweats': loc.registrationFormNightSweats,
      'registrationFormHotFlashes': loc.registrationFormHotFlashes,
      'registrationFormPalpitations': loc.registrationFormPalpitations,
      'registrationFormDizziness': loc.registrationFormDizziness,
      'registrationFormJointPain': loc.registrationFormJointPain,
      'registrationFormHeadache': loc.registrationFormHeadache,
      'registrationFormVertigo': loc.registrationFormVertigo,
      'registrationFormInsomnia': loc.registrationFormInsomnia,
      'registrationFormVomiting': loc.registrationFormVomiting,
      'registrationFormAcne': loc.registrationFormAcne,
      'registrationFormConcentrationDifficulty': loc.registrationFormConcentrationDifficulty,
      'registrationFormAbdominalPain': loc.registrationFormAbdominalPain,
      'registrationFormAbdominalDistension': loc.registrationFormAbdominalDistension,
      'registrationFormBloating': loc.registrationFormBloating,
      'registrationFormDiarrhea': loc.registrationFormDiarrhea,
      'registrationFormConstipation': loc.registrationFormConstipation,
      'registrationFormNausea': loc.registrationFormNausea,
      'registrationFormPelvicPain': loc.registrationFormPelvicPain,
      'registrationFormLowerBackPain': loc.registrationFormLowerBackPain,
      'registrationFormLegCramps': loc.registrationFormLegCramps,
      'registrationFormAppetiteChanges': loc.registrationFormAppetiteChanges,
      'registrationFormCravings': loc.registrationFormCravings,
      'registrationFormIrritability': loc.registrationFormIrritability,
      'registrationFormSadness': loc.registrationFormSadness,
      'registrationFormCryingEasily': loc.registrationFormCryingEasily,
      'registrationFormMoodSwings': loc.registrationFormMoodSwings,
      'registrationFormAnxiety': loc.registrationFormAnxiety,
      'registrationFormLowSelfEsteem': loc.registrationFormLowSelfEsteem,
      'registrationFormBleeding': loc.registrationFormBleeding,
      'registrationFormPain': loc.registrationFormPain,
      'registrationFormStabbing': loc.registrationFormStabbing,
      'registrationFormPulsating': loc.registrationFormPulsating,
      'registrationFormContinuous': loc.registrationFormContinuous,
      'registrationFormMedication': loc.registrationFormMedication,
      'registrationFormRest': loc.registrationFormRest,
      'registrationFormHeat': loc.registrationFormHeat,
      'registrationFormSelfExamNormal': loc.registrationFormSelfExamNormal,
      'registrationFormSelfExamAbnormal': loc.registrationFormSelfExamAbnormal,
      'registrationFormSticky': loc.registrationFormSticky,
      'registrationFormCreamy': loc.registrationFormCreamy,
      'registrationFormEggWhite': loc.registrationFormEggWhite,
      'registrationFormWatery': loc.registrationFormWatery,
      'registrationFormDry': loc.registrationFormDry,
      'registrationFormYellowish': loc.registrationFormYellowish,
      'registrationFormGreenish': loc.registrationFormGreenish,
      'registrationFormGrayish': loc.registrationFormGrayish,
      'registrationFormFoulOdor': loc.registrationFormFoulOdor,
      'registrationFormItching': loc.registrationFormItching,
      'registrationFormBurning': loc.registrationFormBurning,
    };
  }
}

