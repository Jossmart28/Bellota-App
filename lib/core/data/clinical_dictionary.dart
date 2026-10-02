class ClinicalSymptomDef {
  final String key;
  final int baseScore;
  final List<String> relatedSpecialties;
  final String category;

  const ClinicalSymptomDef({
    required this.key,
    required this.baseScore,
    required this.relatedSpecialties,
    required this.category,
  });
}

class ClinicalDictionary {
  static const Map<String, ClinicalSymptomDef> dictionary = {
    // High Risk Physical & Pain Characteristics
    'fever': ClinicalSymptomDef(key: 'fever', baseScore: 10, relatedSpecialties: ['medicina_general', 'infectologia', 'emergencia'], category: 'physical'),
    'vomiting': ClinicalSymptomDef(key: 'vomiting', baseScore: 8, relatedSpecialties: ['gastroenterologia', 'emergencia'], category: 'physical'),
    'palpitations': ClinicalSymptomDef(key: 'palpitations', baseScore: 8, relatedSpecialties: ['cardiologia', 'emergencia'], category: 'physical'),
    'severe_pain': ClinicalSymptomDef(key: 'severe_pain', baseScore: 9, relatedSpecialties: ['emergencia', 'clinica_del_dolor'], category: 'physical'),
    'incapacitating': ClinicalSymptomDef(key: 'incapacitating', baseScore: 9, relatedSpecialties: ['ginecologia', 'clinica_del_dolor', 'emergencia'], category: 'physical'),
    'pelvic_pain': ClinicalSymptomDef(key: 'pelvic_pain', baseScore: 6, relatedSpecialties: ['ginecologia', 'emergencia'], category: 'physical'),
    
    // Medium Risk Physical
    'dizziness': ClinicalSymptomDef(key: 'dizziness', baseScore: 6, relatedSpecialties: ['neurologia', 'medicina_interna'], category: 'physical'),
    'diarrhea': ClinicalSymptomDef(key: 'diarrhea', baseScore: 5, relatedSpecialties: ['gastroenterologia'], category: 'physical'),
    'night_sweats': ClinicalSymptomDef(key: 'night_sweats', baseScore: 5, relatedSpecialties: ['endocrinologia', 'ginecologia'], category: 'physical'),
    'headache': ClinicalSymptomDef(key: 'headache', baseScore: 4, relatedSpecialties: ['neurologia'], category: 'physical'),
    'insomnia': ClinicalSymptomDef(key: 'insomnia', baseScore: 4, relatedSpecialties: ['psiquiatria', 'neurologia'], category: 'physical'),
    
    // Low Risk Physical
    'acne': ClinicalSymptomDef(key: 'acne', baseScore: 2, relatedSpecialties: ['dermatologia', 'endocrinologia'], category: 'physical'),
    'cravings': ClinicalSymptomDef(key: 'cravings', baseScore: 1, relatedSpecialties: ['nutricion'], category: 'physical'),
    'bloating': ClinicalSymptomDef(key: 'bloating', baseScore: 2, relatedSpecialties: ['gastroenterologia', 'ginecologia'], category: 'physical'),
    'water_retention': ClinicalSymptomDef(key: 'water_retention', baseScore: 3, relatedSpecialties: ['medicina_interna', 'nefrologia'], category: 'physical'),

    // Emotional
    'mood_swings': ClinicalSymptomDef(key: 'mood_swings', baseScore: 3, relatedSpecialties: ['psicologia', 'endocrinologia'], category: 'emotional'),
    'anxiety': ClinicalSymptomDef(key: 'anxiety', baseScore: 5, relatedSpecialties: ['psiquiatria', 'psicologia'], category: 'emotional'),
    'sadness': ClinicalSymptomDef(key: 'sadness', baseScore: 4, relatedSpecialties: ['psicologia', 'psiquiatria'], category: 'emotional'),
    'irritability': ClinicalSymptomDef(key: 'irritability', baseScore: 3, relatedSpecialties: ['psicologia'], category: 'emotional'),

    // Vaginal Flow
    'yellow_green': ClinicalSymptomDef(key: 'yellow_green', baseScore: 8, relatedSpecialties: ['ginecologia', 'infectologia'], category: 'flow'),
    'cottage_cheese': ClinicalSymptomDef(key: 'cottage_cheese', baseScore: 7, relatedSpecialties: ['ginecologia'], category: 'flow'),
    'foul_odor': ClinicalSymptomDef(key: 'foul_odor', baseScore: 9, relatedSpecialties: ['ginecologia', 'infectologia'], category: 'flow'),
    'egg_white': ClinicalSymptomDef(key: 'egg_white', baseScore: 0, relatedSpecialties: [], category: 'flow'),
    'sticky': ClinicalSymptomDef(key: 'sticky', baseScore: 0, relatedSpecialties: [], category: 'flow'),
    
    // Bleeding
    'spotting': ClinicalSymptomDef(key: 'spotting', baseScore: 6, relatedSpecialties: ['ginecologia'], category: 'bleeding'),
    'clots': ClinicalSymptomDef(key: 'clots', baseScore: 6, relatedSpecialties: ['ginecologia'], category: 'bleeding'),
    'heavy': ClinicalSymptomDef(key: 'heavy', baseScore: 4, relatedSpecialties: ['ginecologia'], category: 'bleeding'),

    // Sex
    'pain_during_sex': ClinicalSymptomDef(key: 'pain_during_sex', baseScore: 8, relatedSpecialties: ['ginecologia', 'psicologia'], category: 'sexual'),
    'unprotected_new_partner': ClinicalSymptomDef(key: 'unprotected_new_partner', baseScore: 7, relatedSpecialties: ['ginecologia', 'infectologia'], category: 'sexual'),
    
    // Breast
    'breast_lump': ClinicalSymptomDef(key: 'breast_lump', baseScore: 10, relatedSpecialties: ['oncologia', 'oncologia_ginecologica', 'mastologia'], category: 'breast'),
    'breast_skin_change': ClinicalSymptomDef(key: 'breast_skin_change', baseScore: 9, relatedSpecialties: ['oncologia', 'mastologia'], category: 'breast'),
    'breast_discharge': ClinicalSymptomDef(key: 'breast_discharge', baseScore: 9, relatedSpecialties: ['oncologia', 'mastologia'], category: 'breast'),
  };

  /// Calcula el Score Clínico Dinámico considerando padecimientos y frecuencia semanal
  static int calculateDynamicScore(String symptomKey, List<String> userConditions, int weeklyFrequency) {
    final def = dictionary[symptomKey];
    if (def == null) return 0;
    
    int score = def.baseScore;

    // 1. Modificadores por Frecuencia Semanal (Weekly Frequency Context)
    if (weeklyFrequency >= 4) {
      if (score > 0 && score <= 4) {
        score += 3; // Síntoma leve recurrente se vuelve moderado/alto
      } else if (score >= 5 && score < 10) {
        score += 2; // Síntoma moderado se agrava
      }
    } else if (weeklyFrequency == 3) {
      if (score > 0 && score < 10) score += 1;
    }

    // 2. Modificadores por Condiciones Médicas
    
    // PCOS (Síndrome de Ovario Poliquístico)
    if (userConditions.contains('pcos')) {
      if (symptomKey == 'acne' || symptomKey == 'spotting' || symptomKey == 'heavy') {
        score -= 2; // Es esperado, se reduce la alarma clínica general
      }
      if (symptomKey == 'pelvic_pain' && score < 8) {
        score += 1; // Dolor pélvico en SOP requiere mayor vigilancia por quistes
      }
    }
    
    // Endometriosis
    if (userConditions.contains('endometriosis')) {
      if (symptomKey == 'severe_pain' || symptomKey == 'pelvic_pain') {
        score -= 1; // Normalizar ligeramente ya que es un síntoma crónico esperado
      }
      if (symptomKey == 'pain_during_sex') {
        score += 2; // Dispareunia es alerta clave en endometriosis profunda
      }
    }
    
    // Hipotiroidismo
    if (userConditions.contains('hypothyroidism')) {
      if (symptomKey == 'extreme_fatigue' || symptomKey == 'water_retention' || symptomKey == 'mood_swings') {
        score -= 1; // Síntoma crónico esperado
      }
    }

    // Límites de seguridad
    if (score > 10) score = 10;
    if (score < 0) score = 0;

    return score;
  }
}
