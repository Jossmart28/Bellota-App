import 'dart:convert';
import '../../database/database_helper.dart';
import '../data/clinical_dictionary.dart';

/// Alerta clínica generada por el motor de análisis.
/// No contiene texto para traducir — solo llaves de síntomas y metadatos.
class ClinicalAlert {
  /// 'high', 'medium', 'low'
  final String severity;

  /// 'oncology', 'infection', 'pain', 'sexual_risk', 'sexual_pain',
  /// 'general_health', 'bleeding', 'spotting', 'cycle'
  final String category;

  /// Llaves de los síntomas que dispararon esta alerta.
  /// Ej: ['breast_lump'], ['fever', 'severe_pain'], ['yellow_green', 'foul_odor']
  final List<String> triggerSymptoms;

  /// Cuántos días de la semana se detectó el patrón.
  final int weeklyCount;

  /// Cuántos días de la semana tienen datos registrados (contexto).
  final int totalDaysWithData;

  ClinicalAlert({
    required this.severity,
    required this.category,
    required this.triggerSymptoms,
    this.weeklyCount = 0,
    this.totalDaysWithData = 0,
  });
}

/// Analiza el historial de la usuaria y genera alertas predictivas.
/// Requiere acumulación semanal para disparar alertas (excepto ITS).
class ClinicalAnalysisService {
  ClinicalAnalysisService._();
  static final ClinicalAnalysisService instance = ClinicalAnalysisService._();

  /// Analiza los registros recientes y devuelve alertas activas.
  /// Solo genera alertas con datos REALES acumulados en la semana.
  Future<List<ClinicalAlert>> analyzeHealthState(int userId) async {
    final List<ClinicalAlert> alerts = [];

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    String fmt(DateTime d) =>
        "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

    final logs30 = await DatabaseHelper.instance
        .getLogsInRange(userId, fmt(thirtyDaysAgo), fmt(now));

    // Sin registros = sin alertas.
    if (logs30.isEmpty) return alerts;

    final logs30WithData =
        logs30.where((log) => _logHasRealData(log)).toList();
    if (logs30WithData.isEmpty) return alerts;

    // Logs de los últimos 7 días
    final logs7 = logs30WithData.where((log) {
      final date = DateTime.parse(log['date'].toString());
      return date.isAfter(sevenDaysAgo) ||
          date.isAtSameMomentAs(sevenDaysAgo);
    }).toList();

    final int totalDaysWithData = logs7.length;

    // ── Condiciones médicas del perfil ──
    final profile = await DatabaseHelper.instance.getProfile(userId);
    List<String> userConditions = [];
    if (profile != null && profile['medical_conditions'] != null) {
      try {
        userConditions = List<String>.from(
            jsonDecode(profile['medical_conditions'].toString()));
      } catch (_) {}
    }

    // ── Frecuencia semanal de cada ítem clínico ──
    final Map<String, int> weeklyFrequency = {};
    for (var log in logs7) {
      final dailyItems = _extractAllItemsFromLog(log);
      for (var item in dailyItems) {
        weeklyFrequency[item] = (weeklyFrequency[item] ?? 0) + 1;
      }
    }

    // ── Analizar co-ocurrencias diarias (síntomas en el mismo día) ──
    final List<Set<String>> dailyItemSets = [];
    for (var log in logs7) {
      dailyItemSets.add(_extractAllItemsFromLog(log).toSet());
    }

    final Set<String> triggeredCategories = {};

    // ══════════════════════════════════════════════════════
    //  ALERTAS HIGH (rojas) — Requieren acumulación semanal
    // ══════════════════════════════════════════════════════

    // 1. ONCOLOGÍA MAMARIA — ≥ 2 días con anomalía mamaria
    _checkHighAlert(
      alerts: alerts,
      triggeredCategories: triggeredCategories,
      category: 'oncology',
      symptomKeys: const ['breast_lump', 'breast_skin_change', 'breast_discharge'],
      weeklyFrequency: weeklyFrequency,
      minDays: 2,
      totalDaysWithData: totalDaysWithData,
    );

    // 2. INFECCIÓN GINECOLÓGICA — ≥ 2 días con flujo anormal
    _checkHighAlert(
      alerts: alerts,
      triggeredCategories: triggeredCategories,
      category: 'infection',
      symptomKeys: const ['yellow_green', 'cottage_cheese', 'foul_odor'],
      weeklyFrequency: weeklyFrequency,
      minDays: 2,
      totalDaysWithData: totalDaysWithData,
    );

    // 3. DOLOR CRÍTICO
    // 3a. Combinación emergencia (severe_pain/incapacitating + fever/vomiting mismo día)
    //     → Basta 1 día (es emergencia real)
    if (!triggeredCategories.contains('pain')) {
      final Set<String> emergencySymptoms = {};
      int emergencyDays = 0;

      for (var dayItems in dailyItemSets) {
        final hasSevere = dayItems.contains('severe_pain') ||
            dayItems.contains('incapacitating');
        final hasCompounding =
            dayItems.contains('fever') || dayItems.contains('vomiting');
        if (hasSevere && hasCompounding) {
          emergencyDays++;
          for (var s in ['severe_pain', 'incapacitating', 'fever', 'vomiting']) {
            if (dayItems.contains(s)) emergencySymptoms.add(s);
          }
        }
      }

      if (emergencyDays >= 1 && emergencySymptoms.isNotEmpty) {
        alerts.add(ClinicalAlert(
          severity: 'high',
          category: 'pain',
          triggerSymptoms: emergencySymptoms.toList(),
          weeklyCount: emergencyDays,
          totalDaysWithData: totalDaysWithData,
        ));
        triggeredCategories.add('pain');
      }
    }

    // 3b. Dolor severo/incapacitante solo (sin fiebre/vómito) → ≥ 2 días
    if (!triggeredCategories.contains('pain')) {
      _checkHighAlert(
        alerts: alerts,
        triggeredCategories: triggeredCategories,
        category: 'pain',
        symptomKeys: const ['severe_pain', 'incapacitating'],
        weeklyFrequency: weeklyFrequency,
        minDays: 2,
        totalDaysWithData: totalDaysWithData,
      );
    }

    // 3c. Fiebre sola → ≥ 2 días
    if (!triggeredCategories.contains('pain')) {
      final feverDays = weeklyFrequency['fever'] ?? 0;
      if (feverDays >= 2) {
        alerts.add(ClinicalAlert(
          severity: 'high',
          category: 'pain',
          triggerSymptoms: const ['fever'],
          weeklyCount: feverDays,
          totalDaysWithData: totalDaysWithData,
        ));
        triggeredCategories.add('pain');
      }
    }

    // 4. RIESGO DE ITS — 1 registro basta (evento puntual)
    if (!triggeredCategories.contains('sexual_risk')) {
      final itsDays = weeklyFrequency['unprotected_new_partner'] ?? 0;
      if (itsDays >= 1) {
        alerts.add(ClinicalAlert(
          severity: 'high',
          category: 'sexual_risk',
          triggerSymptoms: const ['unprotected_new_partner'],
          weeklyCount: itsDays,
          totalDaysWithData: totalDaysWithData,
        ));
        triggeredCategories.add('sexual_risk');
      }
    }

    // ══════════════════════════════════════════════════════
    //  ALERTAS MEDIUM (amarillas) — Requieren patrones semanales
    // ══════════════════════════════════════════════════════

    // 5. CARGA SINTOMÁTICA — Score acumulado semanal alto con ≥ 3 días de datos
    if (!triggeredCategories.contains('general_health') &&
        totalDaysWithData >= 3) {
      int totalWeeklyScore = 0;
      final Set<String> topContributors = {};

      for (var log in logs7) {
        final dailyItems = _extractAllItemsFromLog(log);
        if (dailyItems.isEmpty) continue;

        for (var item in dailyItems) {
          final score = ClinicalDictionary.calculateDynamicScore(
            item,
            userConditions,
            weeklyFrequency[item] ?? 1,
          );
          totalWeeklyScore += score;
          if (score >= 5) topContributors.add(item);
        }
      }

      final avgDailyScore = totalWeeklyScore / totalDaysWithData;
      if (avgDailyScore > 12 && topContributors.isNotEmpty) {
        alerts.add(ClinicalAlert(
          severity: 'medium',
          category: 'general_health',
          triggerSymptoms: topContributors.take(5).toList(),
          weeklyCount: totalDaysWithData,
          totalDaysWithData: totalDaysWithData,
        ));
        triggeredCategories.add('general_health');
      }
    }

    // 6. DOLOR DURANTE RELACIONES — ≥ 2 días (1 si tiene endometriosis)
    if (!triggeredCategories.contains('sexual_pain')) {
      final painSexDays = weeklyFrequency['pain_during_sex'] ?? 0;
      final threshold = userConditions.contains('endometriosis') ? 1 : 2;
      if (painSexDays >= threshold) {
        alerts.add(ClinicalAlert(
          severity: 'medium',
          category: 'sexual_pain',
          triggerSymptoms: const ['pain_during_sex'],
          weeklyCount: painSexDays,
          totalDaysWithData: totalDaysWithData,
        ));
        triggeredCategories.add('sexual_pain');
      }
    }

    // 7. SANGRADO PROLONGADO (análisis de 30 días) — > 7 días consecutivos
    if (!triggeredCategories.contains('bleeding')) {
      int consecutiveBleeding = 0;
      int maxConsecutive = 0;

      for (var log in logs30WithData) {
        bool isBleeding = (log['period_start'] == 1) ||
            (log['bleeding_intensity'] != null &&
                log['bleeding_intensity'].toString().isNotEmpty &&
                log['bleeding_intensity'].toString() != 'none' &&
                log['bleeding_intensity'].toString() != 'null');

        if (isBleeding) {
          consecutiveBleeding++;
          if (consecutiveBleeding > maxConsecutive) {
            maxConsecutive = consecutiveBleeding;
          }
        } else {
          consecutiveBleeding = 0;
        }
      }

      if (maxConsecutive > 7) {
        final List<String> bleedingTriggers = ['heavy'];
        if (weeklyFrequency.containsKey('clots')) bleedingTriggers.add('clots');
        alerts.add(ClinicalAlert(
          severity: 'medium',
          category: 'bleeding',
          triggerSymptoms: bleedingTriggers,
          weeklyCount: maxConsecutive,
          totalDaysWithData: totalDaysWithData,
        ));
        triggeredCategories.add('bleeding');
      }
    }

    // 8. MANCHADO INTERMENSTRUAL PERSISTENTE — > 5 días consecutivos
    if (!triggeredCategories.contains('spotting')) {
      int consecutiveSpotting = 0;
      int maxConsecutiveSpotting = 0;

      for (var log in logs30WithData) {
        if (log['spotting'] == 1) {
          consecutiveSpotting++;
          if (consecutiveSpotting > maxConsecutiveSpotting) {
            maxConsecutiveSpotting = consecutiveSpotting;
          }
        } else {
          consecutiveSpotting = 0;
        }
      }

      if (maxConsecutiveSpotting > 5) {
        // Reducir alerta si tiene PCOS (es esperado)
        final severity =
            userConditions.contains('pcos') ? 'low' : 'medium';
        alerts.add(ClinicalAlert(
          severity: severity,
          category: 'spotting',
          triggerSymptoms: const ['spotting'],
          weeklyCount: maxConsecutiveSpotting,
          totalDaysWithData: totalDaysWithData,
        ));
        triggeredCategories.add('spotting');
      }
    }

    // 9. CICLO IRREGULAR (análisis estadístico)
    if (!triggeredCategories.contains('cycle')) {
      final cycleStats =
          await DatabaseHelper.instance.getCycleStatistics(userId);
      final count = cycleStats['count'] as int? ?? 0;
      if (count >= 2) {
        final isRegular = cycleStats['isRegular'] as bool? ?? true;
        final avgLen = cycleStats['averageCycleLength'] as double?;

        if (!isRegular ||
            (avgLen != null && (avgLen < 21 || avgLen > 35))) {
          alerts.add(ClinicalAlert(
            severity: 'medium',
            category: 'cycle',
            triggerSymptoms: const ['irregular_cycle'],
            weeklyCount: count,
            totalDaysWithData: totalDaysWithData,
          ));
          triggeredCategories.add('cycle');
        }
      }
    }

    // ══════════════════════════════════════════════════════
    //  ALERTAS LOW (verdes) — Síntomas recurrentes sin urgencia
    // ══════════════════════════════════════════════════════

    // 10. Síntomas con baseScore ≥ 5 que aparecen ≥ 3 días en la semana
    if (totalDaysWithData >= 3) {
      for (var entry in weeklyFrequency.entries) {
        final symptomKey = entry.key;
        final freq = entry.value;

        if (freq >= 3) {
          final def = ClinicalDictionary.dictionary[symptomKey];
          if (def != null && def.baseScore >= 5) {
            // No duplicar si ya hay alerta para este síntoma
            final alreadyCovered = alerts.any(
                (a) => a.triggerSymptoms.contains(symptomKey));
            if (!alreadyCovered) {
              alerts.add(ClinicalAlert(
                severity: 'low',
                category: def.category,
                triggerSymptoms: [symptomKey],
                weeklyCount: freq,
                totalDaysWithData: totalDaysWithData,
              ));
            }
          }
        }
      }
    }

    return alerts;
  }

  // ══════════════════════════════════════════════════════
  //  HELPERS PRIVADOS
  // ══════════════════════════════════════════════════════

  /// Verifica si un grupo de síntomas alcanza el umbral semanal para alerta HIGH.
  void _checkHighAlert({
    required List<ClinicalAlert> alerts,
    required Set<String> triggeredCategories,
    required String category,
    required List<String> symptomKeys,
    required Map<String, int> weeklyFrequency,
    required int minDays,
    required int totalDaysWithData,
  }) {
    if (triggeredCategories.contains(category)) return;

    final found =
        symptomKeys.where((s) => (weeklyFrequency[s] ?? 0) >= minDays).toList();

    if (found.isNotEmpty) {
      alerts.add(ClinicalAlert(
        severity: 'high',
        category: category,
        triggerSymptoms: found,
        weeklyCount: found
            .map((s) => weeklyFrequency[s]!)
            .reduce((a, b) => a > b ? a : b),
        totalDaysWithData: totalDaysWithData,
      ));
      triggeredCategories.add(category);
    }
  }

  /// Verifica que un log tenga datos reales (no una fila vacía de la DB).
  bool _logHasRealData(Map<String, dynamic> log) {
    final hasSymptoms = _hasNonEmptyJsonArray(log['symptoms']);
    final hasPhysical = _hasNonEmptyJsonArray(log['physical_symptoms']);
    final hasEmotional = _hasNonEmptyJsonArray(log['emotional_symptoms']);
    final hasFlujo = _hasNonEmptyJsonArray(log['flujo']);
    final hasSexo = _hasNonEmptyJsonArray(log['sexo']);
    final hasPeriod = log['period_start'] == 1;
    final hasPain = log['pain_level'] != null &&
        (log['pain_level'] as num?) != null &&
        (log['pain_level'] as num) > 0;
    final hasBreast = log['breast_exam'] != null &&
        log['breast_exam'].toString() != 'breast_normal' &&
        log['breast_exam'].toString() != 'breast_pending' &&
        log['breast_exam'].toString().isNotEmpty;
    final hasBleeding = log['bleeding_intensity'] != null &&
        log['bleeding_intensity'].toString().isNotEmpty &&
        log['bleeding_intensity'].toString() != 'none' &&
        log['bleeding_intensity'].toString() != 'null';
    final hasMood =
        log['mood'] != null && log['mood'].toString().isNotEmpty;
    final hasSpotting = log['spotting'] == 1;

    return hasSymptoms ||
        hasPhysical ||
        hasEmotional ||
        hasFlujo ||
        hasSexo ||
        hasPeriod ||
        hasPain ||
        hasBreast ||
        hasBleeding ||
        hasMood ||
        hasSpotting;
  }

  bool _hasNonEmptyJsonArray(dynamic value) {
    if (value == null) return false;
    try {
      final list = jsonDecode(value.toString());
      return list is List && list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Extrae todas las llaves clínicas de un registro diario.
  List<String> _extractAllItemsFromLog(Map<String, dynamic> log) {
    List<String> items = [];

    // Síntomas generales, físicos, emocionales
    _addJsonArrayItems(items, log['symptoms']);
    _addJsonArrayItems(items, log['physical_symptoms']);
    _addJsonArrayItems(items, log['emotional_symptoms']);

    // Flujo vaginal
    _addJsonArrayItems(items, log['flujo']);

    // Actividad sexual
    _addJsonArrayItems(items, log['sexo']);

    // Autoexamen de mama (solo anomalías)
    if (log['breast_exam'] != null) {
      final breast = log['breast_exam'].toString();
      if (breast.isNotEmpty &&
          breast != 'breast_normal' &&
          breast != 'breast_pending') {
        items.add(breast);
      }
    }

    // Nivel de dolor → mapear a síntoma
    if (log['pain_level'] != null) {
      final painLevel = (log['pain_level'] as num?)?.toDouble() ?? 0;
      if (painLevel >= 8) {
        items.add('severe_pain');
      } else if (painLevel >= 4) {
        items.add('pelvic_pain');
      }
    }

    // Carácter del dolor
    if (log['pain_character'] != null &&
        log['pain_character'].toString().isNotEmpty) {
      items.add(log['pain_character'].toString());
    }

    return items;
  }

  void _addJsonArrayItems(List<String> items, dynamic value) {
    if (value == null) return;
    try {
      final list = List<String>.from(jsonDecode(value.toString()));
      items.addAll(list.where((s) => s.isNotEmpty));
    } catch (_) {}
  }
}
