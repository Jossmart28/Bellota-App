import 'dart:convert';
import 'dart:io';

void main() async {
  final esMap = <String, String>{};
  final enMap = <String, String>{};
  final miMap = <String, String>{};
  
  final file = File('lib/l10n/old_translations.dart');
  final lines = await file.readAsLines(encoding: latin1);
  
  String currentLang = '';
  String currentCategory = '';
  
  for (var line in lines) {
    if (line.contains('static const Map<String, Map<String, Map<String, String>>> translations = {')) {
      continue;
    }
    
    var langMatch = RegExp(r"^\s*'([a-z]{2})':\s*\{").firstMatch(line);
    if (langMatch != null) {
      currentLang = langMatch.group(1)!;
      continue;
    }
    
    var catMatch = RegExp(r"^\s*'([^']+)':\s*\{").firstMatch(line);
    if (catMatch != null) {
      currentCategory = catMatch.group(1)!;
      continue;
    }
    
    var keyMatch = RegExp(r"^\s*'([^']+)':\s*'([^']*)',?").firstMatch(line);
    if (keyMatch != null) {
      var key = keyMatch.group(1)!;
      var value = keyMatch.group(2)!;
      
      // Convert to camelCase
      var parts = (currentCategory + '_' + key).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').split('_').where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) continue;
      var camelKey = parts[0];
      for (var i = 1; i < parts.length; i++) {
        camelKey += parts[i].substring(0, 1).toUpperCase() + parts[i].substring(1);
      }
      
      if (currentLang == 'es') esMap[camelKey] = value;
      else if (currentLang == 'en') enMap[camelKey] = value;
      else if (currentLang == 'mi') miMap[camelKey] = value;
    }
  }
  
  // Add missing keys
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

  // Write ARBs
  void writeArb(String lang, Map<String, String> map) {
    final arb = <String, dynamic>{
      '@@locale': lang,
    };
    map.forEach((k, v) {
      arb[k] = v;
    });
    
    File('lib/l10n/app_$lang.arb').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(arb),
      encoding: utf8
    );
  }
  
  writeArb('es', esMap);
  writeArb('en', enMap);
  writeArb('mi', miMap);
}
