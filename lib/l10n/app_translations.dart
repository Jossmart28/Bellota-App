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
    if (context == null) return key.replaceAll('_', ' ');
    final loc = AppLocalizations.of(context)!;
    final camelKey = _toCamelCase(category, key);
    
    // We could use reflection, but Dart disables it in Flutter.
    // Instead, we will fallback to a large lookup or just handle the most common ones 
    // manually. But actually, if we use a massive switch or a Map, it would be better.
    // Since we just want it to compile, let's implement the specific dynamic keys.
    return _lookup(loc, camelKey) ?? key.replaceAll('_', ' ');
  }

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

