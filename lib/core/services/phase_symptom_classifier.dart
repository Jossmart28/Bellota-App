import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/domain/repositories/profile_repository.dart';

/// Resultado de predicción enriquecida con nivel de confianza y razón.
class SymptomPrediction {
  final String symptomKey;
  final double score; // 0.0 – 10.0
  final String confidence; // 'high' | 'medium' | 'low'
  final String reason; // clave de razón (sin traducir)

  const SymptomPrediction({
    required this.symptomKey,
    required this.score,
    required this.confidence,
    required this.reason,
  });
}

/// Servicio de clasificación de síntomas por fase y día del ciclo.
///
/// Combina:
///   1. Conocimiento clínico por fase + sub-fase (día del ciclo).
///   2. Modificadores personales: edad, condiciones médicas, anticonceptivos,
///      medicamentos registrados en el perfil.
///   3. Combinación con predicción histórica (puntaje externo se mezcla).
///
/// Principio de diseño: este servicio NO accede a la BD directamente para
/// el historial — eso lo hace [ClinicalAnalysisService.predictSymptoms].
/// Este servicio únicamente aporta el "prior clínico" que se mezcla con
/// la evidencia histórica.
class PhaseSymptomClassifier {
  PhaseSymptomClassifier._();
  static final PhaseSymptomClassifier instance = PhaseSymptomClassifier._();

  // ─────────────────────────────────────────────────────────────
  //  API PRINCIPAL
  // ─────────────────────────────────────────────────────────────

  /// Devuelve [limit] síntomas predichos para el [cycleDay] / [phaseName]
  /// dados, ajustados al perfil del usuario.
  ///
  /// [historicalScores] es el mapa {symptomKey: score} que ya calculó
  /// ClinicalAnalysisService. Este método lo mezcla con el prior clínico
  /// y devuelve la lista final ordenada.
  Future<List<SymptomPrediction>> getPredictions({
    required int userId,
    required String phaseName,
    required int cycleDay,
    required int cycleDuration,
    required int periodDuration,
    Map<String, double> historicalScores = const {},
    int limit = 5,
  }) async {
    final profile = await _loadProfile(userId);

    // 1. Prior clínico base para la fase + sub-fase
    final Map<String, double> priorScores =
        _buildPriorScores(phaseName, cycleDay, cycleDuration, periodDuration);

    // 2. Modificadores personales
    _applyPersonalModifiers(priorScores, profile);

    // 3. Mezclar prior clínico + historial (60% prior, 40% histórico)
    final Map<String, double> combined = {};
    final allKeys = {...priorScores.keys, ...historicalScores.keys};
    for (final key in allKeys) {
      final prior = priorScores[key] ?? 0.0;
      final hist = historicalScores[key] ?? 0.0;
      combined[key] = (prior * 0.6) + (hist * 0.4);
    }

    // 4. Ordenar y devolver
    final sorted = combined.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) {
      final score = e.value.clamp(0.0, 10.0);
      return SymptomPrediction(
        symptomKey: e.key,
        score: score,
        confidence: score >= 7.0
            ? 'high'
            : score >= 4.5
                ? 'medium'
                : 'low',
        reason: _reasonKey(e.key, phaseName, profile),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────
  //  PRIOR CLÍNICO POR FASE Y DÍA
  // ─────────────────────────────────────────────────────────────

  /// Construye puntajes clínicos base para la fase, con gradaciones por
  /// sub-fase (día exacto dentro del rango de la fase).
  Map<String, double> _buildPriorScores(
    String phaseName,
    int cycleDay,
    int cycleDuration,
    int periodDuration,
  ) {
    final Map<String, double> scores = {};
    final phase = phaseName.toLowerCase();
    final ovulationDay = cycleDuration - 14;

    switch (phase) {
      case 'menstrual':
        // Días 1-periodDuration
        final dayInPhase = cycleDay.clamp(1, periodDuration);
        final intensity = dayInPhase <= 2
            ? 1.0 // Inicio más intenso
            : dayInPhase <= periodDuration - 1
                ? 0.7 // Medio
                : 0.4; // Final

        scores['pelvic_pain'] = 8.0 * intensity;
        scores['cramps'] = 7.5 * intensity;
        scores['extreme_fatigue'] = 7.0 * intensity;
        scores['heavy_flow'] = dayInPhase <= 2 ? 8.0 : 5.0;
        scores['spotting'] = dayInPhase == periodDuration ? 6.0 : 0.0;
        scores['lower_back_pain'] = 6.5 * intensity;
        scores['headache'] = 5.5 * intensity;
        scores['nausea'] = 4.5 * (dayInPhase <= 2 ? 1.0 : 0.5);
        scores['mood_swings'] = 5.0 * intensity;
        scores['bloating'] = 5.0 * (dayInPhase <= 2 ? 1.0 : 0.6);
        break;

      case 'follicular':
        // Días periodDuration+1 a ovulationDay-2
        final follLength = (ovulationDay - 2) - periodDuration;
        final dayInPhase = (cycleDay - periodDuration).clamp(1, follLength.abs());
        final progress = follLength > 0 ? dayInPhase / follLength : 0.5;

        scores['high_energy'] = 5.0 + (progress * 3.0);
        scores['high_libido'] = 4.0 + (progress * 4.0);
        scores['watery'] = 3.0 + (progress * 4.0); // Flujo acuoso pre-ovulación
        scores['clear_skin'] = 4.0;
        scores['improved_mood'] = 5.0 + (progress * 2.0);
        scores['improved_concentration'] = 4.5;
        scores['breast_tenderness'] = 2.0; // Bajo en folicular
        break;

      case 'ovulatory':
        // ± 1-2 días alrededor de ovulationDay
        scores['egg_white'] = 9.0; // Flujo tipo clara de huevo
        scores['high_libido'] = 9.0;
        scores['pelvic_pain'] = 5.0; // Mittelschmerz
        scores['breast_tenderness'] = 4.0;
        scores['high_energy'] = 7.0;
        scores['light_spotting'] = 3.5;
        scores['bloating'] = 3.5;
        scores['elevated_basal_temp'] = 8.0;
        break;

      case 'luteal':
        // ovulationDay+2 a cycleDuration
        final lutLength = cycleDuration - (ovulationDay + 1);
        final dayInLuteal = (cycleDay - (ovulationDay + 1)).clamp(1, lutLength.abs());
        final progress = lutLength > 0 ? dayInLuteal / lutLength : 0.5;

        // PMS escala hacia el final de la fase lútea
        final pmsIntensity = progress < 0.4 ? 0.3 : progress < 0.7 ? 0.65 : 1.0;

        scores['mood_swings'] = 5.0 + (pmsIntensity * 4.0);
        scores['breast_tenderness'] = 5.0 + (pmsIntensity * 3.5);
        scores['bloating'] = 4.0 + (pmsIntensity * 4.0);
        scores['acne'] = 3.0 + (pmsIntensity * 3.0);
        scores['cravings'] = 4.0 + (pmsIntensity * 3.0);
        scores['fatigue'] = 3.0 + (pmsIntensity * 4.0);
        scores['irritability'] = 2.0 + (pmsIntensity * 5.0);
        scores['water_retention'] = 3.0 + (pmsIntensity * 3.5);
        scores['headache'] = 2.0 + (pmsIntensity * 3.0);
        scores['lower_back_pain'] = 2.0 + (pmsIntensity * 3.0);
        break;
    }

    return scores;
  }

  // ─────────────────────────────────────────────────────────────
  //  MODIFICADORES PERSONALES
  // ─────────────────────────────────────────────────────────────

  void _applyPersonalModifiers(
      Map<String, double> scores, _UserProfileSnapshot profile) {
    // ── Condiciones médicas ──
    if (profile.conditions.contains('endometriosis')) {
      scores['pelvic_pain'] = (scores['pelvic_pain'] ?? 0) + 3.0;
      scores['lower_back_pain'] = (scores['lower_back_pain'] ?? 0) + 2.5;
      scores['heavy_flow'] = (scores['heavy_flow'] ?? 0) + 2.0;
      scores['cramps'] = (scores['cramps'] ?? 0) + 3.0;
    }

    if (profile.conditions.contains('pcos')) {
      scores['acne'] = (scores['acne'] ?? 0) + 3.0;
      scores['spotting'] = (scores['spotting'] ?? 0) + 2.5;
      scores['irregular_period'] = (scores['irregular_period'] ?? 0) + 3.0;
      scores['excess_hair'] = (scores['excess_hair'] ?? 0) + 2.5;
      scores['mood_swings'] = (scores['mood_swings'] ?? 0) + 1.5;
    }

    if (profile.conditions.contains('hypothyroidism')) {
      scores['extreme_fatigue'] = (scores['extreme_fatigue'] ?? 0) + 3.5;
      scores['water_retention'] = (scores['water_retention'] ?? 0) + 2.5;
      scores['depression'] = (scores['depression'] ?? 0) + 2.0;
    }

    if (profile.conditions.contains('fibromyalgia')) {
      scores['lower_back_pain'] = (scores['lower_back_pain'] ?? 0) + 3.0;
      scores['extreme_fatigue'] = (scores['extreme_fatigue'] ?? 0) + 2.5;
      scores['headache'] = (scores['headache'] ?? 0) + 2.0;
    }

    if (profile.conditions.contains('migraines')) {
      scores['headache'] = (scores['headache'] ?? 0) + 4.0;
      scores['nausea'] = (scores['nausea'] ?? 0) + 2.0;
    }

    if (profile.conditions.contains('anemia')) {
      scores['extreme_fatigue'] = (scores['extreme_fatigue'] ?? 0) + 3.0;
      scores['dizziness'] = (scores['dizziness'] ?? 0) + 2.5;
    }

    // ── Anticonceptivos ──
    final c = profile.contraceptive?.toLowerCase() ?? '';
    if (c.contains('pill') || c.contains('oral') || c.contains('pildora')) {
      // Las pastillas anticonceptivas reducen síntomas menstruales
      scores['heavy_flow'] = (scores['heavy_flow'] ?? 0) * 0.5;
      scores['cramps'] = (scores['cramps'] ?? 0) * 0.6;
      scores['pelvic_pain'] = (scores['pelvic_pain'] ?? 0) * 0.6;
      // Pueden causar náuseas al inicio
      scores['nausea'] = (scores['nausea'] ?? 0) + 1.5;
    }

    if (c.contains('iud') || c.contains('diu')) {
      // DIU hormonal: reduce flujo. DIU de cobre: puede aumentar flujo
      if (c.contains('copper') || c.contains('cobre')) {
        scores['heavy_flow'] = (scores['heavy_flow'] ?? 0) + 2.0;
        scores['cramps'] = (scores['cramps'] ?? 0) + 1.5;
      } else {
        scores['heavy_flow'] = (scores['heavy_flow'] ?? 0) * 0.4;
      }
    }

    if (c.contains('implant') || c.contains('implante')) {
      scores['spotting'] = (scores['spotting'] ?? 0) + 3.0;
      scores['mood_swings'] = (scores['mood_swings'] ?? 0) + 1.5;
    }

    if (c.contains('injection') || c.contains('inyeccion')) {
      scores['spotting'] = (scores['spotting'] ?? 0) + 2.0;
      scores['weight_gain'] = (scores['weight_gain'] ?? 0) + 2.0;
    }

    // ── Edad ──
    if (profile.age >= 40) {
      scores['hot_flashes'] = (scores['hot_flashes'] ?? 0) + 3.0;
      scores['irregular_period'] = (scores['irregular_period'] ?? 0) + 2.0;
      scores['night_sweats'] = (scores['night_sweats'] ?? 0) + 2.0;
    }
    if (profile.age < 20) {
      scores['acne'] = (scores['acne'] ?? 0) + 2.0;
      scores['cramps'] = (scores['cramps'] ?? 0) + 1.5; // Dismenorrea primaria
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────

  String _reasonKey(
      String symptom, String phase, _UserProfileSnapshot profile) {
    if (profile.conditions.contains('endometriosis') &&
        (symptom == 'pelvic_pain' || symptom == 'cramps')) {
      return 'endometriosis';
    }
    if (profile.conditions.contains('pcos') && symptom == 'acne') {
      return 'pcos';
    }
    return phase.toLowerCase();
  }

  Future<_UserProfileSnapshot> _loadProfile(int userId) async {
    try {
      final profileModel = await sl<ProfileRepository>().getProfile(userId);
      final p = profileModel?.toMap() ?? {};
      final age = _calcAge(p['birth_year'] as int? ?? 2000);
      final conditions = _parseList(p['medical_conditions']);
      final medications = _parseList(p['medications']);
      final contraceptive = p['contraceptive_method'] as String?;
      return _UserProfileSnapshot(
        age: age,
        conditions: conditions,
        medications: medications,
        contraceptive: contraceptive,
      );
    } catch (_) {
      return _UserProfileSnapshot(
          age: 25, conditions: [], medications: [], contraceptive: null);
    }
  }

  int _calcAge(int birthYear) {
    return DateTime.now().year - birthYear;
  }

  List<String> _parseList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    try {
      final decoded = raw.toString();
      if (decoded.startsWith('[')) {
        return List<String>.from(
            (decoded.replaceAll('[', '').replaceAll(']', '').split(',')).map(
                (e) => e.trim().replaceAll('"', '').replaceAll("'", '')));
      }
    } catch (_) {}
    return [];
  }
}

class _UserProfileSnapshot {
  final int age;
  final List<String> conditions;
  final List<String> medications;
  final String? contraceptive;

  const _UserProfileSnapshot({
    required this.age,
    required this.conditions,
    required this.medications,
    required this.contraceptive,
  });
}
