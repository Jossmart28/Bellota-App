/// Mapeo estático de síntomas a especialidades y etiquetas de hospitales
class SymptomHospitalMapping {
  // Mapa de condiciones médicas a especialidades requeridas
  static const Map<String, List<String>> medicalConditionToSpecialty = {
    'pcos': ['ginecologia', 'endocrinologia', 'fertilidad'],
    'endometriosis': ['ginecologia', 'cirugia_minimamente_invasiva', 'clinica_del_dolor'],
    'hypothyroidism': ['endocrinologia', 'medicina_interna'],
    'other': ['medicina_general'],
  };

  // Mapa ampliado de síntomas a especialidades
  static const Map<String, List<String>> symptomToSpecialty = {
    // ── Cuerpo entero (10) ──────────────────────────────
    'fever': ['medicina_general', 'emergencia', 'infectologia'],
    'body_ache': ['medicina_general', 'ortopedia', 'reumatologia'],
    'general_distension': ['medicina_general', 'gastroenterologia'],
    'extreme_fatigue': ['medicina_general', 'endocrinologia', 'hematologia'],
    'water_retention': ['nefrologia', 'medicina_interna', 'cardiologia'],
    'night_sweats': ['endocrinologia', 'ginecologia', 'medicina_interna'],
    'hot_flashes': ['ginecologia', 'endocrinologia'],
    'palpitations': ['cardiologia', 'emergencia'],
    'dizziness': ['neurologia', 'otorrinolaringologia', 'medicina_interna'],
    'joint_pain': ['reumatologia', 'ortopedia'],

    // ── Cabeza (6) ──────────────────────────────────────
    'headache': ['neurologia', 'medicina_general'],
    'vertigo': ['otorrinolaringologia', 'neurologia'],
    'insomnia': ['psiquiatria', 'neurologia'],
    'vomiting': ['gastroenterologia', 'emergencia'],
    'acne': ['dermatologia', 'endocrinologia'],
    'concentration_difficulty': ['psiquiatria', 'neurologia'],

    // ── Abdomen (9) ─────────────────────────────────────
    'abdominal_pain': ['gastroenterologia', 'emergencia', 'cirugia_general', 'ginecologia'],
    'abdominal_distension': ['gastroenterologia'],
    'bloating': ['gastroenterologia', 'ginecologia'],
    'diarrhea': ['gastroenterologia', 'medicina_general'],
    'constipation': ['gastroenterologia', 'medicina_general'],
    'nausea': ['gastroenterologia', 'medicina_general'],
    'pelvic_pain': ['ginecologia', 'emergencia'],
    'lower_back_pain': ['ortopedia', 'reumatologia', 'clinica_del_dolor'],
    'leg_cramps': ['medicina_interna', 'neurologia'],

    // ── Otros (5) ───────────────────────────────────────
    'breast_tenderness': ['ginecologia', 'mastologia'],
    'abnormal_discharge': ['ginecologia', 'infectologia'],
    'spotting': ['ginecologia'],
    'appetite_changes': ['endocrinologia', 'nutricion'],
    'cravings': ['nutricion', 'psicologia'],

    // ── Emocionales (6) ─────────────────────────────────
    'irritability': ['psicologia', 'psiquiatria'],
    'sadness': ['psicologia', 'psiquiatria'],
    'crying_easily': ['psicologia', 'psiquiatria'],
    'mood_swings': ['psicologia', 'psiquiatria', 'endocrinologia'],
    'anxiety': ['psicologia', 'psiquiatria'],
    'low_self_esteem': ['psicologia'],
  };

  /// Extrae la lista combinada de especialidades necesarias
  /// basándose en los síntomas y condiciones médicas de la usuaria.
  static Set<String> getRequiredSpecialties(List<String> symptoms, List<String> medicalConditions) {
    final Set<String> requiredSpecialties = {};

    for (var symptom in symptoms) {
      if (symptomToSpecialty.containsKey(symptom)) {
        requiredSpecialties.addAll(symptomToSpecialty[symptom]!);
      }
    }

    for (var condition in medicalConditions) {
      if (medicalConditionToSpecialty.containsKey(condition)) {
        requiredSpecialties.addAll(medicalConditionToSpecialty[condition]!);
      }
    }

    return requiredSpecialties;
  }
}
