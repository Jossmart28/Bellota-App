/// Definición de un síntoma clínico con score base y metadatos médicos.
class ClinicalSymptomDef {
  final String key;

  /// Score base clínico (0-10). Escala ginecológica:
  ///   0 = Normal/Fisiológico
  ///   1-3 = Bajo riesgo, informativo
  ///   4-6 = Riesgo moderado, requiere seguimiento
  ///   7-8 = Riesgo alto, requiere evaluación médica
  ///   9-10 = Urgencia/Emergencia
  final int baseScore;

  /// Especialidades médicas relacionadas.
  final List<String> relatedSpecialties;

  /// Categoría del síntoma para agrupación de alertas.
  final String category;

  const ClinicalSymptomDef({
    required this.key,
    required this.baseScore,
    required this.relatedSpecialties,
    required this.category,
  });
}

/// Diccionario clínico exhaustivo de todos los síntomas registrables en Bellota.
///
/// Cada entrada mapea una key de síntoma a su definición clínica con score base,
/// especialidades relacionadas y categoría. Los scores reflejan criterios
/// ginecológicos estándar (ACOG, FIGO, OMS).
class ClinicalDictionary {
  static const Map<String, ClinicalSymptomDef> dictionary = {
    // ══════════════════════════════════════════════════════════════
    //  SÍNTOMAS FÍSICOS GENERALES (category: 'physical')
    // ══════════════════════════════════════════════════════════════

    // — Alto riesgo —
    'fever': ClinicalSymptomDef(key: 'fever', baseScore: 10, relatedSpecialties: ['medicina_general', 'infectologia', 'emergencia'], category: 'physical'),
    'vomiting': ClinicalSymptomDef(key: 'vomiting', baseScore: 8, relatedSpecialties: ['gastroenterologia', 'emergencia'], category: 'physical'),
    'palpitations': ClinicalSymptomDef(key: 'palpitations', baseScore: 8, relatedSpecialties: ['cardiologia', 'emergencia'], category: 'physical'),
    'extreme_fatigue': ClinicalSymptomDef(key: 'extreme_fatigue', baseScore: 5, relatedSpecialties: ['medicina_interna', 'endocrinologia'], category: 'physical'),
    'hot_flashes': ClinicalSymptomDef(key: 'hot_flashes', baseScore: 4, relatedSpecialties: ['endocrinologia', 'ginecologia'], category: 'physical'),

    // — Dolor —
    'severe_pain': ClinicalSymptomDef(key: 'severe_pain', baseScore: 9, relatedSpecialties: ['emergencia', 'clinica_del_dolor'], category: 'pain'),
    'incapacitating': ClinicalSymptomDef(key: 'incapacitating', baseScore: 9, relatedSpecialties: ['ginecologia', 'clinica_del_dolor', 'emergencia'], category: 'pain'),
    'not_incapacitating': ClinicalSymptomDef(key: 'not_incapacitating', baseScore: 2, relatedSpecialties: ['medicina_general'], category: 'pain'),
    'pelvic_pain': ClinicalSymptomDef(key: 'pelvic_pain', baseScore: 6, relatedSpecialties: ['ginecologia', 'emergencia'], category: 'pain'),
    'severe_cramps': ClinicalSymptomDef(key: 'severe_cramps', baseScore: 7, relatedSpecialties: ['ginecologia'], category: 'pain'),
    'menstrual_migraine': ClinicalSymptomDef(key: 'menstrual_migraine', baseScore: 6, relatedSpecialties: ['neurologia', 'ginecologia'], category: 'pain'),
    'mastalgia': ClinicalSymptomDef(key: 'mastalgia', baseScore: 3, relatedSpecialties: ['ginecologia', 'mastologia'], category: 'pain'),
    'lower_back_pain': ClinicalSymptomDef(key: 'lower_back_pain', baseScore: 3, relatedSpecialties: ['ginecologia', 'ortopedia'], category: 'pain'),
    'leg_cramps': ClinicalSymptomDef(key: 'leg_cramps', baseScore: 2, relatedSpecialties: ['medicina_interna'], category: 'pain'),

    // — Riesgo medio —
    'dizziness': ClinicalSymptomDef(key: 'dizziness', baseScore: 6, relatedSpecialties: ['neurologia', 'medicina_interna'], category: 'physical'),
    'diarrhea': ClinicalSymptomDef(key: 'diarrhea', baseScore: 5, relatedSpecialties: ['gastroenterologia'], category: 'physical'),
    'constipation': ClinicalSymptomDef(key: 'constipation', baseScore: 3, relatedSpecialties: ['gastroenterologia'], category: 'physical'),
    'nausea': ClinicalSymptomDef(key: 'nausea', baseScore: 4, relatedSpecialties: ['gastroenterologia', 'ginecologia'], category: 'physical'),
    'night_sweats': ClinicalSymptomDef(key: 'night_sweats', baseScore: 5, relatedSpecialties: ['endocrinologia', 'ginecologia'], category: 'physical'),
    'headache': ClinicalSymptomDef(key: 'headache', baseScore: 4, relatedSpecialties: ['neurologia'], category: 'physical'),
    'insomnia': ClinicalSymptomDef(key: 'insomnia', baseScore: 4, relatedSpecialties: ['psiquiatria', 'neurologia'], category: 'physical'),
    'body_ache': ClinicalSymptomDef(key: 'body_ache', baseScore: 3, relatedSpecialties: ['medicina_interna'], category: 'physical'),
    'abdominal_distension': ClinicalSymptomDef(key: 'abdominal_distension', baseScore: 3, relatedSpecialties: ['gastroenterologia', 'ginecologia'], category: 'physical'),

    // — Bajo riesgo —
    'acne': ClinicalSymptomDef(key: 'acne', baseScore: 2, relatedSpecialties: ['dermatologia', 'endocrinologia'], category: 'physical'),
    'cravings': ClinicalSymptomDef(key: 'cravings', baseScore: 1, relatedSpecialties: ['nutricion'], category: 'physical'),
    'appetite_changes': ClinicalSymptomDef(key: 'appetite_changes', baseScore: 1, relatedSpecialties: ['nutricion', 'endocrinologia'], category: 'physical'),
    'bloating': ClinicalSymptomDef(key: 'bloating', baseScore: 2, relatedSpecialties: ['gastroenterologia', 'ginecologia'], category: 'physical'),
    'water_retention': ClinicalSymptomDef(key: 'water_retention', baseScore: 3, relatedSpecialties: ['medicina_interna', 'nefrologia'], category: 'physical'),
    'breast_tenderness': ClinicalSymptomDef(key: 'breast_tenderness', baseScore: 2, relatedSpecialties: ['ginecologia'], category: 'physical'),

    // ══════════════════════════════════════════════════════════════
    //  SÍNTOMAS EMOCIONALES (category: 'emotional')
    // ══════════════════════════════════════════════════════════════
    'mood_swings': ClinicalSymptomDef(key: 'mood_swings', baseScore: 3, relatedSpecialties: ['psicologia', 'endocrinologia'], category: 'emotional'),
    'anxiety': ClinicalSymptomDef(key: 'anxiety', baseScore: 5, relatedSpecialties: ['psiquiatria', 'psicologia'], category: 'emotional'),
    'sadness': ClinicalSymptomDef(key: 'sadness', baseScore: 4, relatedSpecialties: ['psicologia', 'psiquiatria'], category: 'emotional'),
    'irritability': ClinicalSymptomDef(key: 'irritability', baseScore: 3, relatedSpecialties: ['psicologia'], category: 'emotional'),
    'low_self_esteem': ClinicalSymptomDef(key: 'low_self_esteem', baseScore: 4, relatedSpecialties: ['psicologia', 'psiquiatria'], category: 'emotional'),

    // ══════════════════════════════════════════════════════════════
    //  FLUJO VAGINAL (category: 'flow')
    // ══════════════════════════════════════════════════════════════

    // — Fisiológico (normal) —
    'dry': ClinicalSymptomDef(key: 'dry', baseScore: 0, relatedSpecialties: [], category: 'flow'),
    'sticky': ClinicalSymptomDef(key: 'sticky', baseScore: 0, relatedSpecialties: [], category: 'flow'),
    'creamy': ClinicalSymptomDef(key: 'creamy', baseScore: 0, relatedSpecialties: [], category: 'flow'),
    'watery': ClinicalSymptomDef(key: 'watery', baseScore: 0, relatedSpecialties: [], category: 'flow'),
    'egg_white': ClinicalSymptomDef(key: 'egg_white', baseScore: 0, relatedSpecialties: [], category: 'flow'),

    // — Patológico (posible infección) —
    'yellow_green': ClinicalSymptomDef(key: 'yellow_green', baseScore: 8, relatedSpecialties: ['ginecologia', 'infectologia'], category: 'flow'),
    'cottage_cheese': ClinicalSymptomDef(key: 'cottage_cheese', baseScore: 7, relatedSpecialties: ['ginecologia'], category: 'flow'),
    'foul_odor': ClinicalSymptomDef(key: 'foul_odor', baseScore: 9, relatedSpecialties: ['ginecologia', 'infectologia'], category: 'flow'),

    // ══════════════════════════════════════════════════════════════
    //  PATRÓN DE SANGRADO (category: 'bleeding')
    // ══════════════════════════════════════════════════════════════

    // — Intensidad —
    'light_flow': ClinicalSymptomDef(key: 'light_flow', baseScore: 0, relatedSpecialties: [], category: 'bleeding'),
    'moderate_flow': ClinicalSymptomDef(key: 'moderate_flow', baseScore: 0, relatedSpecialties: [], category: 'bleeding'),
    'heavy_flow': ClinicalSymptomDef(key: 'heavy_flow', baseScore: 5, relatedSpecialties: ['ginecologia', 'hematologia'], category: 'bleeding'),

    // — Color —
    'bright_red': ClinicalSymptomDef(key: 'bright_red', baseScore: 0, relatedSpecialties: [], category: 'bleeding'),
    'dark_red': ClinicalSymptomDef(key: 'dark_red', baseScore: 0, relatedSpecialties: [], category: 'bleeding'),
    'brown': ClinicalSymptomDef(key: 'brown', baseScore: 1, relatedSpecialties: ['ginecologia'], category: 'bleeding'),
    'pink': ClinicalSymptomDef(key: 'pink', baseScore: 2, relatedSpecialties: ['ginecologia'], category: 'bleeding'),

    // — Coágulos —
    'never': ClinicalSymptomDef(key: 'never', baseScore: 0, relatedSpecialties: [], category: 'bleeding'),
    'occasional': ClinicalSymptomDef(key: 'occasional', baseScore: 2, relatedSpecialties: ['ginecologia'], category: 'bleeding'),
    'frequent': ClinicalSymptomDef(key: 'frequent', baseScore: 6, relatedSpecialties: ['ginecologia', 'hematologia'], category: 'bleeding'),

    // — Otros —
    'spotting': ClinicalSymptomDef(key: 'spotting', baseScore: 6, relatedSpecialties: ['ginecologia'], category: 'bleeding'),
    'clots': ClinicalSymptomDef(key: 'clots', baseScore: 6, relatedSpecialties: ['ginecologia'], category: 'bleeding'),


    // ══════════════════════════════════════════════════════════════
    //  ACTIVIDAD SEXUAL (category: 'sexual')
    // ══════════════════════════════════════════════════════════════

    // — Actividad (informativo) —
    'protected': ClinicalSymptomDef(key: 'protected', baseScore: 0, relatedSpecialties: [], category: 'sexual'),
    'masturbation': ClinicalSymptomDef(key: 'masturbation', baseScore: 0, relatedSpecialties: [], category: 'sexual'),
    'high_libido': ClinicalSymptomDef(key: 'high_libido', baseScore: 0, relatedSpecialties: [], category: 'sexual'),
    'condom': ClinicalSymptomDef(key: 'condom', baseScore: 0, relatedSpecialties: [], category: 'sexual'),

    // — Riesgo reproductivo —
    'unprotected': ClinicalSymptomDef(key: 'unprotected', baseScore: 5, relatedSpecialties: ['ginecologia'], category: 'sexual'),
    'no_contraception': ClinicalSymptomDef(key: 'no_contraception', baseScore: 6, relatedSpecialties: ['ginecologia'], category: 'sexual'),
    'no_ejaculation': ClinicalSymptomDef(key: 'no_ejaculation', baseScore: 3, relatedSpecialties: ['ginecologia'], category: 'sexual'),
    'short_pill': ClinicalSymptomDef(key: 'short_pill', baseScore: 7, relatedSpecialties: ['ginecologia', 'endocrinologia'], category: 'sexual'),

    // — Complicaciones —
    'pain_during_sex': ClinicalSymptomDef(key: 'pain_during_sex', baseScore: 8, relatedSpecialties: ['ginecologia', 'psicologia'], category: 'sexual'),
    'unprotected_new_partner': ClinicalSymptomDef(key: 'unprotected_new_partner', baseScore: 7, relatedSpecialties: ['ginecologia', 'infectologia'], category: 'sexual'),

    // ══════════════════════════════════════════════════════════════
    //  MAMA (category: 'breast')
    // ══════════════════════════════════════════════════════════════
    'breast_normal': ClinicalSymptomDef(key: 'breast_normal', baseScore: 0, relatedSpecialties: [], category: 'breast'),
    'breast_pending': ClinicalSymptomDef(key: 'breast_pending', baseScore: 0, relatedSpecialties: [], category: 'breast'),
    'breast_lump': ClinicalSymptomDef(key: 'breast_lump', baseScore: 10, relatedSpecialties: ['oncologia', 'oncologia_ginecologica', 'mastologia'], category: 'breast'),
    'breast_localized_pain': ClinicalSymptomDef(key: 'breast_localized_pain', baseScore: 5, relatedSpecialties: ['mastologia', 'ginecologia'], category: 'breast'),
    'breast_skin_change': ClinicalSymptomDef(key: 'breast_skin_change', baseScore: 9, relatedSpecialties: ['oncologia', 'mastologia'], category: 'breast'),
    'breast_discharge': ClinicalSymptomDef(key: 'breast_discharge', baseScore: 9, relatedSpecialties: ['oncologia', 'mastologia'], category: 'breast'),

    // ══════════════════════════════════════════════════════════════
    //  TRATAMIENTO (category: 'treatment') — Informativo
    // ══════════════════════════════════════════════════════════════
    'medication': ClinicalSymptomDef(key: 'medication', baseScore: 0, relatedSpecialties: [], category: 'treatment'),
    'thermal_remedies': ClinicalSymptomDef(key: 'thermal_remedies', baseScore: 0, relatedSpecialties: [], category: 'treatment'),

    // ══════════════════════════════════════════════════════════════
    //  FERTILIDAD (category: 'fertility') — Informativo
    // ══════════════════════════════════════════════════════════════
    'negative': ClinicalSymptomDef(key: 'negative', baseScore: 0, relatedSpecialties: [], category: 'fertility'),
    'positive': ClinicalSymptomDef(key: 'positive', baseScore: 0, relatedSpecialties: [], category: 'fertility'),
    'peak': ClinicalSymptomDef(key: 'peak', baseScore: 0, relatedSpecialties: [], category: 'fertility'),
    'low_firm': ClinicalSymptomDef(key: 'low_firm', baseScore: 0, relatedSpecialties: [], category: 'fertility'),
    'mid': ClinicalSymptomDef(key: 'mid', baseScore: 0, relatedSpecialties: [], category: 'fertility'),
    'high_soft': ClinicalSymptomDef(key: 'high_soft', baseScore: 0, relatedSpecialties: [], category: 'fertility'),

    // ══════════════════════════════════════════════════════════════
    //  CICLO (category: 'cycle') — Para alertas generadas internamente
    // ══════════════════════════════════════════════════════════════
    'irregular_cycle': ClinicalSymptomDef(key: 'irregular_cycle', baseScore: 5, relatedSpecialties: ['ginecologia', 'endocrinologia'], category: 'cycle'),
  };

  // ══════════════════════════════════════════════════════════════════
  //  SCORE CLÍNICO DINÁMICO
  // ══════════════════════════════════════════════════════════════════

  /// Calcula el Score Clínico Dinámico considerando:
  /// 1. Score base del síntoma
  /// 2. Frecuencia semanal (recurrencia amplifica severidad)
  /// 3. Condiciones médicas preexistentes (contexto clínico)
  /// 4. Edad de la paciente (umbrales ajustados)
  /// 5. Uso de anticonceptivo (modula riesgo reproductivo)
  /// 6. Medicamentos (interacciones esperadas)
  static int calculateDynamicScore(
    String symptomKey,
    List<String> userConditions,
    int weeklyFrequency, {
    int? userAge,
    String? contraceptiveMethod,
    List<String>? medications,
  }) {
    final def = dictionary[symptomKey];
    if (def == null) return 0;

    int score = def.baseScore;

    // ── 1. Modificadores por Frecuencia Semanal ──
    if (weeklyFrequency >= 4) {
      if (score > 0 && score <= 4) {
        score += 3; // Síntoma leve recurrente → moderado/alto
      } else if (score >= 5 && score < 10) {
        score += 2; // Síntoma moderado recurrente → se agrava
      }
    } else if (weeklyFrequency == 3) {
      if (score > 0 && score < 10) score += 1;
    }

    // ── 2. Modificadores por Condiciones Médicas ──

    // SOP (Síndrome de Ovario Poliquístico)
    if (userConditions.contains('pcos')) {
      // Síntomas esperados en SOP → reducir alarma
      if (symptomKey == 'acne' || symptomKey == 'spotting' || symptomKey == 'heavy') {
        score -= 2;
      }
      // Dolor pélvico en SOP → vigilancia por quistes ováricos
      if (symptomKey == 'pelvic_pain' && score < 8) score += 1;
      // Cólicos severos en SOP → posible ruptura de quiste
      if (symptomKey == 'severe_cramps') score += 1;
      // Coágulos frecuentes → esperado en SOP
      if (symptomKey == 'frequent') score -= 1;
      // Píldora de emergencia altera más el eje hormonal en SOP
      if (symptomKey == 'short_pill') score += 1;
    }

    // Endometriosis
    if (userConditions.contains('endometriosis')) {
      // Dolor crónico esperado → normalizar levemente
      if (symptomKey == 'severe_pain' || symptomKey == 'pelvic_pain') {
        score -= 1;
      }
      // Dispareunia (dolor en sexo) → alerta clave en endometriosis profunda
      if (symptomKey == 'pain_during_sex') score += 2;
      // Dolor incapacitante → red flag para infiltración profunda
      if (symptomKey == 'incapacitating') score += 1;
      // Sangrado abundante → menorragia asociada
      if (symptomKey == 'heavy_flow') score += 2;
      // Dolor mamario localizado → requiere seguimiento
      if (symptomKey == 'breast_localized_pain') score += 1;
    }

    // Hipotiroidismo
    if (userConditions.contains('hypothyroidism')) {
      // Síntomas crónicos esperados → reducir alarma
      if (symptomKey == 'extreme_fatigue' ||
          symptomKey == 'water_retention' ||
          symptomKey == 'mood_swings') {
        score -= 1;
      }
      // Menorragia es común en hipotiroidismo
      if (symptomKey == 'heavy_flow') score += 1;
    }

    // ── 3. Modificadores por Edad ──
    if (userAge != null) {
      // Adolescentes (< 16): ciclos irregulares son normales (inmadurez HPO)
      if (userAge < 16 && symptomKey == 'irregular_cycle') {
        score -= 2;
      }
      // Adolescentes (< 20): dolor durante sexo requiere atención especial
      if (userAge < 20 && symptomKey == 'pain_during_sex') {
        score += 1;
      }
      // Mayores de 35: sangrado irregular requiere mayor vigilancia
      if (userAge > 35 && (symptomKey == 'spotting' || symptomKey == 'heavy_flow')) {
        score += 1;
      }
      // Mayores de 40: hallazgos mamarios son más urgentes
      if (userAge > 40 && (symptomKey == 'breast_lump' || symptomKey == 'breast_skin_change')) {
        score = 10; // Máxima urgencia
      }
    }

    // ── 4. Modificadores por Anticonceptivo ──
    if (contraceptiveMethod != null && contraceptiveMethod.isNotEmpty) {
      // Si usa anticonceptivo, el sexo sin protección no implica tanto riesgo de embarazo
      if (symptomKey == 'unprotected' || symptomKey == 'no_contraception') {
        score -= 2;
      }
      // Manchado intermenstrual es esperado con DIU y implante
      if (symptomKey == 'spotting') {
        score -= 1;
      }
    }

    // ── 5. Límites de seguridad ──
    if (score > 10) score = 10;
    if (score < 0) score = 0;

    return score;
  }
}
