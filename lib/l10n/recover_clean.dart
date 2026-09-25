import 'dart:convert';
import 'dart:io';

import 'old_translations.dart';

void main() {
  final esMap = <String, String>{};
  final enMap = <String, String>{};
  final miMap = <String, String>{};
  
  // Structure: Category -> Key -> Lang -> Value
  AppTranslations.translations.forEach((category, keys) {
    keys.forEach((key, langs) {
      langs.forEach((lang, value) {
        var parts = (category + '_' + key).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').split('_').where((s) => s.isNotEmpty).toList();
        if (parts.isEmpty) return;
        var camelKey = parts[0];
        for (var i = 1; i < parts.length; i++) {
          camelKey += parts[i].substring(0, 1).toUpperCase() + parts[i].substring(1);
        }
        
        if (lang == 'es') esMap[camelKey] = value;
        else if (lang == 'en') enMap[camelKey] = value;
        else if (lang == 'mi') miMap[camelKey] = value;
      });
    });
  });
  
  final extraKeys = {
    'registrationFormStabbing': 'Punzante',
    'registrationFormPulsating': 'Pulsátil',
    'registrationFormContinuous': 'Continuo',
    'registrationFormRest': 'Descanso',
    'registrationFormHeat': 'Calor',
    'registrationFormSelfExamNormal': 'Normal',
    'registrationFormSelfExamAbnormal': 'Anormal',
    'registrationFormSticky': 'Pegajoso',
    'registrationFormCreamy': 'Cremoso',
    'registrationFormYellowish': 'Amarillento',
    'registrationFormGreenish': 'Verdoso',
    'registrationFormGrayish': 'Grisáceo',
    'registrationFormFoulOdor': 'Mal olor',
    'registrationFormItching': 'Picazón',
    'registrationFormBurning': 'Ardor',
    'registrationFormKeyInfo': 'Info',
    'symptomsAndActionsRecentPeriodTitle': 'Periodo reciente',
    'registrationFormNone': 'Ninguno',
  };
  
  esMap.addAll(extraKeys);
  enMap.addAll(extraKeys);
  miMap.addAll(extraKeys);

  void writeArb(String lang, Map<String, String> map) {
    final arb = <String, dynamic>{'@@locale': lang};
    map.forEach((k, v) => arb[k] = v);
    File('lib/l10n/app_$lang.arb').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(arb),
      encoding: utf8
    );
  }
  
  writeArb('es', esMap);
  writeArb('en', enMap);
  writeArb('mi', miMap);
}
