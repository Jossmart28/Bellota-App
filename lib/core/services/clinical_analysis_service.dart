import 'package:bellotadevelopment/domain/services/health_prediction_service.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/domain/repositories/daily_log_repository.dart';
import 'package:bellotadevelopment/domain/repositories/profile_repository.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database_helper.dart';
import '../data/clinical_dictionary.dart';
import '../constants/app_keys.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  MODELOS DE DATOS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

/// Perfil de salud integral de la usuaria.
/// Centraliza datos del perfil + historial para alimentar el motor de anÃ¡lisis.
class UserHealthProfile {
  final int age;
  final int cycleDuration;
  final int periodDuration;
  final List<String> medications;
  final List<String> medicalConditions;
  final String? contraceptiveMethod;

  /// EstadÃ­sticas calculadas del historial de ciclos.
  final double avgCycleLength;
  final bool isCycleRegular;
  final int totalCyclesRecorded;

  /// Frecuencias de actividad sexual (Ãºltimos 30 dÃ­as).
  final int sexualActivityDays;
  final Map<String, int> sexoFrequency;

  /// Frecuencias de flujo vaginal (Ãºltimos 30 dÃ­as).
  final Map<String, int> flujoFrequency;

  /// Frecuencias de patrÃ³n de sangrado (Ãºltimos 30 dÃ­as).
  final Map<String, int> bleedingFrequency;

  /// Frecuencias de dolor/sÃ­ntomas (Ãºltimos 30 dÃ­as).
  final Map<String, int> painFrequency;

  /// Frecuencias de autoexamen mamario (Ãºltimos 30 dÃ­as).
  final Map<String, int> breastFrequency;

  /// Scores de riesgo calculados (0.0-10.0).
  final double sexualRiskScore;
  final double menstrualHealthScore;
  final double overallSymptomBurden;

  const UserHealthProfile({
    required this.age,
    required this.cycleDuration,
    required this.periodDuration,
    required this.medications,
    required this.medicalConditions,
    this.contraceptiveMethod,
    required this.avgCycleLength,
    required this.isCycleRegular,
    required this.totalCyclesRecorded,
    required this.sexualActivityDays,
    required this.sexoFrequency,
    required this.flujoFrequency,
    required this.bleedingFrequency,
    required this.painFrequency,
    required this.breastFrequency,
    required this.sexualRiskScore,
    required this.menstrualHealthScore,
    required this.overallSymptomBurden,
  });
}

/// Alerta clÃ­nica generada por el motor de anÃ¡lisis.
/// Contiene solo llaves de sÃ­ntomas y metadatos â€” sin texto traducido.
class ClinicalAlert {
  /// 'high', 'medium', 'low'
  final String severity;

  /// CategorÃ­a de la alerta. Valores posibles:
  /// 'oncology', 'infection', 'pain', 'sexual_risk', 'sexual_pain',
  /// 'general_health', 'bleeding', 'spotting', 'cycle', 'contraception',
  /// 'emergency_pill', 'pregnancy_risk', 'flow_anomaly', 'breast'
  final String category;

  /// Llaves de los sÃ­ntomas que dispararon esta alerta.
  final List<String> triggerSymptoms;

  /// CuÃ¡ntos dÃ­as (de la ventana analizada) se detectÃ³ el patrÃ³n.
  final int weeklyCount;

  /// CuÃ¡ntos dÃ­as tienen datos registrados (contexto de completitud).
  final int totalDaysWithData;

  /// Mensaje interno descriptivo (para logs/debug, no para UI).
  final String? internalNote;

  ClinicalAlert({
    required this.severity,
    required this.category,
    required this.triggerSymptoms,
    this.weeklyCount = 0,
    this.totalDaysWithData = 0,
    this.internalNote,
  });
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  MOTOR DE ANÃLISIS CLÃNICO
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

/// Motor de anÃ¡lisis clÃ­nico integral de Bellota.
///
/// Combina datos del perfil de la usuaria (edad, ciclo, condiciones,
/// anticonceptivo, medicamentos) con registros de sÃ­ntomas para generar
/// alertas predictivas con perspectiva ginecolÃ³gica profesional.
///
/// Flujo de datos:
/// ```
/// Perfil (SQLite + SharedPrefs)
///        â†“
/// buildUserHealthProfile()
///        â†“
/// UserHealthProfile â†’ analyzeHealthState()
///        â†“
/// List<ClinicalAlert> (ordenadas por severidad)
/// ```
class ClinicalAnalysisService {
  ClinicalAnalysisService._();
  static final ClinicalAnalysisService instance = ClinicalAnalysisService._();

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  CONSTRUCCIÃ“N DEL PERFIL DE SALUD
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Construye el perfil de salud integral a partir de todas las fuentes de datos.
  Future<UserHealthProfile> buildUserHealthProfile(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    

    // â”€â”€ Datos del perfil â”€â”€
    final profile = await sl<ProfileRepository>().getProfile(userId);
    final int cycleDuration = (profile?.cycleDuration as int?) ?? 28;
    final int periodDuration = (profile?.periodDuration as int?) ?? 5;
    final String? contraceptive = profile?.toMap()['contraceptive'] as String?;

    // Edad
    final String? birthYearStr = prefs.getString(AppKeys.userAge);
    int age = 25; // default
    if (birthYearStr != null) {
      final birthYear = int.tryParse(birthYearStr);
      if (birthYear != null) age = DateTime.now().year - birthYear;
    }

    // Condiciones mÃ©dicas
    List<String> conditions = [];
    if (profile != null && profile.medicalConditions != null) {
      try {
        conditions = List<String>.from(
            jsonDecode(profile.medicalConditions.toString()));
        conditions.remove('none');
      } catch (_) {}
    }

    // Medicamentos
    final List<String> medications =
        prefs.getStringList('user_medications') ?? [];

    // â”€â”€ EstadÃ­sticas de ciclo â”€â”€
    final cycleStats = await sl<DailyLogRepository>().getCycleStatistics(userId);
    final int cycleCount = cycleStats['count'] as int? ?? 0;
    final double avgCycle =
        (cycleStats['averageCycleLength'] as double?) ?? cycleDuration.toDouble();
    final bool isRegular = cycleStats['isRegular'] as bool? ?? true;

    // â”€â”€ Registros de los Ãºltimos 30 dÃ­as â”€â”€
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final logs30 = (await sl<DailyLogRepository>().getLogsInRange(userId, _fmt(thirtyDaysAgo), _fmt(now))).map((m) => m.toMap()).toList();

    // â”€â”€ Frecuencias por categorÃ­a â”€â”€
    final Map<String, int> sexoFreq = {};
    final Map<String, int> flujoFreq = {};
    final Map<String, int> bleedingFreq = {};
    final Map<String, int> painFreq = {};
    final Map<String, int> breastFreq = {};
    int sexDays = 0;

    for (var log in logs30) {
      // Sexo
      final sexoItems = _parseJsonArray(log['sexo']);
      if (sexoItems.isNotEmpty) sexDays++;
      for (var s in sexoItems) {
        sexoFreq[s] = (sexoFreq[s] ?? 0) + 1;
      }

      // Flujo vaginal
      final flujoItems = _parseJsonArray(log['flujo']);
      for (var f in flujoItems) {
        flujoFreq[f] = (flujoFreq[f] ?? 0) + 1;
      }

      // PatrÃ³n de sangrado
      if (log['bleeding_intensity'] != null &&
          log['bleeding_intensity'].toString().isNotEmpty &&
          log['bleeding_intensity'].toString() != 'null') {
        final bk = log['bleeding_intensity'].toString();
        bleedingFreq[bk] = (bleedingFreq[bk] ?? 0) + 1;
      }
      if (log['clots'] != null &&
          log['clots'].toString().isNotEmpty &&
          log['clots'].toString() != 'null') {
        final ck = log['clots'].toString();
        bleedingFreq[ck] = (bleedingFreq[ck] ?? 0) + 1;
      }
      if ((log['spotting'] as int?) == 1) {
        bleedingFreq['spotting'] = (bleedingFreq['spotting'] ?? 0) + 1;
      }

      // Dolor
      if (log['pain_level'] != null) {
        final painLevel = (log['pain_level'] as num?)?.toDouble() ?? 0;
        if (painLevel >= 8) {
          painFreq['severe_pain'] = (painFreq['severe_pain'] ?? 0) + 1;
        } else if (painLevel >= 4) {
          painFreq['pelvic_pain'] = (painFreq['pelvic_pain'] ?? 0) + 1;
        }
      }
      if (log['pain_character'] != null &&
          log['pain_character'].toString().isNotEmpty) {
        final pc = log['pain_character'].toString();
        painFreq[pc] = (painFreq[pc] ?? 0) + 1;
      }
      if (log['treatment'] != null &&
          log['treatment'].toString().isNotEmpty &&
          log['treatment'].toString() != 'none') {
        final tk = log['treatment'].toString();
        painFreq['treatment_$tk'] = (painFreq['treatment_$tk'] ?? 0) + 1;
      }

      // SÃ­ntomas fÃ­sicos y emocionales
      final physItems = _parseJsonArray(log['physical_symptoms']);
      for (var p in physItems) {
        painFreq[p] = (painFreq[p] ?? 0) + 1;
      }
      final emoItems = _parseJsonArray(log['emotional_symptoms']);
      for (var e in emoItems) {
        painFreq[e] = (painFreq[e] ?? 0) + 1;
      }

      // Mama
      if (log['breast_exam'] != null &&
          log['breast_exam'].toString().isNotEmpty) {
        final bx = log['breast_exam'].toString();
        breastFreq[bx] = (breastFreq[bx] ?? 0) + 1;
      }
    }

    // â”€â”€ Scores de riesgo â”€â”€
    final double sexRisk = _calculateSexualRiskScore(
        sexoFreq, sexDays, contraceptive, conditions);
    final double menstrualHealth = _calculateMenstrualHealthScore(
        bleedingFreq, avgCycle, isRegular, periodDuration, conditions);
    final double symptomBurden = _calculateOverallSymptomBurden(
        painFreq, flujoFreq, breastFreq, conditions);

    return UserHealthProfile(
      age: age,
      cycleDuration: cycleDuration,
      periodDuration: periodDuration,
      medications: medications,
      medicalConditions: conditions,
      contraceptiveMethod: contraceptive,
      avgCycleLength: avgCycle,
      isCycleRegular: isRegular,
      totalCyclesRecorded: cycleCount,
      sexualActivityDays: sexDays,
      sexoFrequency: sexoFreq,
      flujoFrequency: flujoFreq,
      bleedingFrequency: bleedingFreq,
      painFrequency: painFreq,
      breastFrequency: breastFreq,
      sexualRiskScore: sexRisk,
      menstrualHealthScore: menstrualHealth,
      overallSymptomBurden: symptomBurden,
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  ANÃLISIS DE SALUD â€” GENERADOR DE ALERTAS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Analiza el estado de salud integral y genera alertas clÃ­nicas.
  ///
  /// Combina el perfil de salud con registros recientes para detectar
  /// patrones que requieran atenciÃ³n mÃ©dica, organizados por severidad.
  Future<List<ClinicalAlert>> analyzeHealthState(int userId) async {
    final List<ClinicalAlert> alerts = [];
    final profile = await buildUserHealthProfile(userId);

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final logs30 = await DatabaseHelper.instance
        .getLogsInRange(userId, _fmt(thirtyDaysAgo), _fmt(now));

    if (logs30.isEmpty) return alerts;

    final logs30WithData = logs30.where((log) => _logHasRealData(log)).toList();
    if (logs30WithData.isEmpty) return alerts;

    // Logs de los Ãºltimos 7 dÃ­as
    final logs7 = logs30WithData.where((log) {
      final date = DateTime.parse(log['date'].toString());
      return date.isAfter(sevenDaysAgo) || date.isAtSameMomentAs(sevenDaysAgo);
    }).toList();

    final int totalDaysWithData = logs7.length;
    if (totalDaysWithData == 0) return alerts;

    // â”€â”€ Frecuencia semanal de cada Ã­tem clÃ­nico â”€â”€
    final Map<String, int> weeklyFrequency = {};
    final List<Set<String>> dailyItemSets = [];

    for (var log in logs7) {
      final dailyItems = _extractAllItemsFromLog(log);
      for (var item in dailyItems) {
        weeklyFrequency[item] = (weeklyFrequency[item] ?? 0) + 1;
      }
      dailyItemSets.add(dailyItems.toSet());
    }

    final Set<String> triggeredCategories = {};

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  ALERTAS HIGH (rojas)
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    // 1. ONCOLOGÃA MAMARIA â€” â‰¥ 2 dÃ­as con anomalÃ­a mamaria
    _checkHighAlert(
      alerts: alerts,
      triggeredCategories: triggeredCategories,
      category: 'oncology',
      symptomKeys: const ['breast_lump', 'breast_skin_change', 'breast_discharge'],
      weeklyFrequency: weeklyFrequency,
      minDays: profile.age > 40 ? 1 : 2, // MÃ¡s sensible en > 40 aÃ±os
      totalDaysWithData: totalDaysWithData,
    );

    // 2. INFECCIÃ“N GINECOLÃ“GICA â€” â‰¥ 2 dÃ­as con flujo anormal
    _checkHighAlert(
      alerts: alerts,
      triggeredCategories: triggeredCategories,
      category: 'infection',
      symptomKeys: const ['yellow_green', 'cottage_cheese', 'foul_odor'],
      weeklyFrequency: weeklyFrequency,
      minDays: 2,
      totalDaysWithData: totalDaysWithData,
    );

    // 3. DOLOR CRÃTICO
    // 3a. CombinaciÃ³n emergencia (severe_pain/incapacitating + fever/vomiting)
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

    // 3b. Dolor severo/incapacitante solo â†’ â‰¥ 2 dÃ­as
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

    // 3c. Fiebre sola â†’ â‰¥ 2 dÃ­as
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

    // 4. RIESGO DE ITS â€” 1 registro basta
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

    // 5. PÃLDORA DE EMERGENCIA FRECUENTE â€” â‰¥ 2 en 30 dÃ­as
    //    La OMS advierte que el uso repetido de anticoncepciÃ³n de
    //    emergencia indica falla en el mÃ©todo habitual y altera el eje HPO.
    if (!triggeredCategories.contains('emergency_pill')) {
      final pillCount30 = profile.sexoFrequency['short_pill'] ?? 0;
      if (pillCount30 >= 2) {
        alerts.add(ClinicalAlert(
          severity: 'high',
          category: 'emergency_pill',
          triggerSymptoms: const ['short_pill'],
          weeklyCount: pillCount30,
          totalDaysWithData: totalDaysWithData,
          internalNote: 'Uso de anticoncepciÃ³n de emergencia â‰¥2 veces en 30 dÃ­as',
        ));
        triggeredCategories.add('emergency_pill');
      }
    }

    // 6. RIESGO DE EMBARAZO ELEVADO
    //    Sexo sin protecciÃ³n frecuente + sin anticonceptivo configurado
    if (!triggeredCategories.contains('pregnancy_risk')) {
      final unprotectedDays =
          (profile.sexoFrequency['unprotected'] ?? 0) +
          (profile.sexoFrequency['no_contraception'] ?? 0);
      final hasNoContraceptive = profile.contraceptiveMethod == null ||
          profile.contraceptiveMethod!.isEmpty;

      if (unprotectedDays >= 3 && hasNoContraceptive) {
        alerts.add(ClinicalAlert(
          severity: 'high',
          category: 'pregnancy_risk',
          triggerSymptoms: const ['unprotected', 'no_contraception'],
          weeklyCount: unprotectedDays,
          totalDaysWithData: totalDaysWithData,
          internalNote: 'Actividad sexual sin protecciÃ³n recurrente sin anticonceptivo',
        ));
        triggeredCategories.add('pregnancy_risk');
      }
    }

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  ALERTAS MEDIUM (amarillas)
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    // 7. CARGA SINTOMÃTICA â€” Score acumulado semanal alto
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
            profile.medicalConditions,
            weeklyFrequency[item] ?? 1,
            userAge: profile.age,
            contraceptiveMethod: profile.contraceptiveMethod,
            medications: profile.medications,
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

    // 8. DOLOR DURANTE RELACIONES â€” â‰¥ 2 dÃ­as (1 si endometriosis)
    if (!triggeredCategories.contains('sexual_pain')) {
      final painSexDays = weeklyFrequency['pain_during_sex'] ?? 0;
      final threshold =
          profile.medicalConditions.contains('endometriosis') ? 1 : 2;
      if (painSexDays >= threshold) {
        String severity = 'medium';
        // En adolescentes es mÃ¡s preocupante
        if (profile.age < 20) severity = 'high';

        alerts.add(ClinicalAlert(
          severity: severity,
          category: 'sexual_pain',
          triggerSymptoms: const ['pain_during_sex'],
          weeklyCount: painSexDays,
          totalDaysWithData: totalDaysWithData,
        ));
        triggeredCategories.add('sexual_pain');
      }
    }

    // 9. SANGRADO PROLONGADO (30 dÃ­as) â€” > 7 dÃ­as consecutivos
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

    // 10. MANCHADO INTERMENSTRUAL PERSISTENTE â€” > 5 dÃ­as consecutivos
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
        // Reducir alerta si tiene SOP o usa DIU/implante (es esperado)
        String severity = 'medium';
        if (profile.medicalConditions.contains('pcos') ||
            profile.contraceptiveMethod != null) {
          severity = 'low';
        }
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

    // 11. CICLO IRREGULAR
    if (!triggeredCategories.contains('cycle')) {
      final cycleStats =
          await DatabaseHelper.instance.getCycleStatistics(userId);
      final count = cycleStats['count'] as int? ?? 0;
      if (count >= 2) {
        final isRegular = cycleStats['isRegular'] as bool? ?? true;
        final avgLen = cycleStats['averageCycleLength'] as double?;

        if (!isRegular || (avgLen != null && (avgLen < 21 || avgLen > 35))) {
          // En adolescentes < 16, ciclos irregulares son normales
          String severity = profile.age < 16 ? 'low' : 'medium';

          alerts.add(ClinicalAlert(
            severity: severity,
            category: 'cycle',
            triggerSymptoms: const ['irregular_cycle'],
            weeklyCount: count,
            totalDaysWithData: totalDaysWithData,
          ));
          triggeredCategories.add('cycle');
        }
      }
    }

    // 12. FLUJO VAGINAL ANORMAL PERSISTENTE
    if (!triggeredCategories.contains('flow_anomaly')) {
      final yellowGreen30 = profile.flujoFrequency['yellow_green'] ?? 0;
      final cottageCheese30 = profile.flujoFrequency['cottage_cheese'] ?? 0;
      final foulOdor30 = profile.flujoFrequency['foul_odor'] ?? 0;
      final totalAbnormal = yellowGreen30 + cottageCheese30 + foulOdor30;

      if (totalAbnormal >= 5) {
        final List<String> triggers = [];
        if (yellowGreen30 > 0) triggers.add('yellow_green');
        if (cottageCheese30 > 0) triggers.add('cottage_cheese');
        if (foulOdor30 > 0) triggers.add('foul_odor');

        alerts.add(ClinicalAlert(
          severity: 'medium',
          category: 'flow_anomaly',
          triggerSymptoms: triggers,
          weeklyCount: totalAbnormal,
          totalDaysWithData: totalDaysWithData,
          internalNote: 'Flujo vaginal anormal persistente en 30 dÃ­as',
        ));
        triggeredCategories.add('flow_anomaly');
      }
    }

    // 13. INCONSISTENCIA ANTICONCEPTIVA
    if (!triggeredCategories.contains('contraception')) {
      final noContraceptionDays =
          profile.sexoFrequency['no_contraception'] ?? 0;
      final hasConfiguredContraceptive =
          profile.contraceptiveMethod != null &&
          profile.contraceptiveMethod!.isNotEmpty;

      if (hasConfiguredContraceptive && noContraceptionDays >= 3) {
        alerts.add(ClinicalAlert(
          severity: 'low',
          category: 'contraception',
          triggerSymptoms: const ['no_contraception'],
          weeklyCount: noContraceptionDays,
          totalDaysWithData: totalDaysWithData,
          internalNote: 'Reporta no usar anticoncepciÃ³n pero tiene mÃ©todo configurado',
        ));
        triggeredCategories.add('contraception');
      }
    }

    // 14. SANGRADO ABUNDANTE CON COÃGULOS FRECUENTES
    if (!triggeredCategories.contains('menorrhagia')) {
      final heavyFlowDays = profile.bleedingFrequency['heavy_flow'] ?? 0;
      final frequentClots = profile.bleedingFrequency['frequent'] ?? 0;

      if (heavyFlowDays >= 3 && frequentClots >= 2) {
        String severity = 'medium';
        // En endometriosis o hipotiroidismo, es mÃ¡s preocupante
        if (profile.medicalConditions.contains('endometriosis') ||
            profile.medicalConditions.contains('hypothyroidism')) {
          severity = 'high';
        }
        alerts.add(ClinicalAlert(
          severity: severity,
          category: 'menorrhagia',
          triggerSymptoms: const ['heavy_flow', 'frequent'],
          weeklyCount: heavyFlowDays,
          totalDaysWithData: totalDaysWithData,
          internalNote: 'PatrÃ³n de menorragia: sangrado abundante + coÃ¡gulos frecuentes',
        ));
        triggeredCategories.add('menorrhagia');
      }
    }

    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
    //  ALERTAS LOW (informativas)
    // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

    // 15. SÃ­ntomas recurrentes con score â‰¥ 5 que aparecen â‰¥ 3 dÃ­as
    if (totalDaysWithData >= 3) {
      for (var entry in weeklyFrequency.entries) {
        final symptomKey = entry.key;
        final freq = entry.value;

        if (freq >= 3) {
          final def = ClinicalDictionary.dictionary[symptomKey];
          if (def != null && def.baseScore >= 5) {
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

    // â”€â”€ Ordenar alertas por severidad â”€â”€
    const severityOrder = {'high': 0, 'medium': 1, 'low': 2};
    alerts.sort((a, b) =>
        (severityOrder[a.severity] ?? 3).compareTo(severityOrder[b.severity] ?? 3));

    return alerts;
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  MOTOR DE PREDICCIÃ“N DE SÃNTOMAS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Predice los sÃ­ntomas mÃ¡s probables para la fase actual.
  Future<List<String>> predictSymptoms(int userId, String phaseName, {int limit = 5}) async {
    final profile = await buildUserHealthProfile(userId);
    
    
    final historicalPhaseSymptoms = await sl<HealthPredictionService>().getTopSymptomsForPhase(userId, phaseName, limit: 10);
    
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentLogs = (await sl<DailyLogRepository>().getLogsInRange(userId, _fmt(sevenDaysAgo), _fmt(now))).map((m) => m.toMap()).toList();
    
    final Map<String, int> recentFrequency = {};
    for (var log in recentLogs) {
      final items = _extractAllItemsFromLog(log);
      for (var item in items) {
        recentFrequency[item] = (recentFrequency[item] ?? 0) + 1;
      }
    }
    
    Map<String, double> predictiveScores = {};
    
    for (int i = 0; i < historicalPhaseSymptoms.length; i++) {
      final symptom = historicalPhaseSymptoms[i];
      predictiveScores[symptom] = (predictiveScores[symptom] ?? 0) + (10.0 - i);
    }
    
    for (var entry in recentFrequency.entries) {
      final symptom = entry.key;
      final freq = entry.value;
      predictiveScores[symptom] = (predictiveScores[symptom] ?? 0) + (freq * 2.5);
    }
    
    final finalScores = <String, double>{};
    for (var entry in predictiveScores.entries) {
      final symptom = entry.key;
      final basePredictiveScore = entry.value;
      
      final clinicalRisk = ClinicalDictionary.calculateDynamicScore(
        symptom,
        profile.medicalConditions,
        recentFrequency[symptom] ?? 0,
        userAge: profile.age,
        contraceptiveMethod: profile.contraceptiveMethod,
        medications: profile.medications,
      );
      
      finalScores[symptom] = basePredictiveScore + (clinicalRisk * 1.5);
    }
    
    if (finalScores.isEmpty) {
      _injectBasePredictions(finalScores, phaseName, profile);
    }
    
    final sortedSymptoms = finalScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return sortedSymptoms.take(limit).map((e) => e.key).toList();
  }
  
  void _injectBasePredictions(Map<String, double> scores, String phaseName, UserHealthProfile profile) {
    if (phaseName.toLowerCase() == 'menstrual') {
      scores['pelvic_pain'] = 8.0;
      scores['extreme_fatigue'] = 6.0;
      scores['heavy_flow'] = 5.0;
      if (profile.medicalConditions.contains('endometriosis')) scores['severe_pain'] = 9.0;
    } else if (phaseName.toLowerCase() == 'follicular') {
      scores['high_libido'] = 5.0;
      scores['watery'] = 4.0;
    } else if (phaseName.toLowerCase() == 'ovulatory') {
      scores['egg_white'] = 8.0;
      scores['high_libido'] = 7.0;
      scores['pelvic_pain'] = 4.0; 
    } else if (phaseName.toLowerCase() == 'luteal') {
      scores['mood_swings'] = 8.0;
      scores['breast_tenderness'] = 7.0;
      scores['bloating'] = 6.0;
      scores['acne'] = 5.0;
      scores['cravings'] = 5.0;
    }
    
    if (profile.medicalConditions.contains('pcos')) {
      scores['acne'] = (scores['acne'] ?? 0) + 4.0;
      scores['spotting'] = (scores['spotting'] ?? 0) + 3.0;
    }
    if (profile.medicalConditions.contains('endometriosis')) {
      scores['lower_back_pain'] = (scores['lower_back_pain'] ?? 0) + 5.0;
    }
    if (profile.medicalConditions.contains('hypothyroidism')) {
      scores['extreme_fatigue'] = (scores['extreme_fatigue'] ?? 0) + 5.0;
      scores['water_retention'] = (scores['water_retention'] ?? 0) + 4.0;
    }
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  CÃLCULO DE SCORES DE RIESGO
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  /// Score de riesgo sexual (0.0-10.0).
  /// Factores: frecuencia sin protecciÃ³n, pareja nueva, pÃ­ldora emergencia,
  /// disponibilidad de anticonceptivo, condiciones.
  double _calculateSexualRiskScore(
    Map<String, int> sexoFreq,
    int sexDays,
    String? contraceptive,
    List<String> conditions,
  ) {
    if (sexDays == 0) return 0.0;

    double score = 0;
    final unprotected = sexoFreq['unprotected'] ?? 0;
    final noContraception = sexoFreq['no_contraception'] ?? 0;
    final newPartner = sexoFreq['unprotected_new_partner'] ?? 0;
    final shortPill = sexoFreq['short_pill'] ?? 0;
    final painSex = sexoFreq['pain_during_sex'] ?? 0;

    // ProporciÃ³n sin protecciÃ³n
    final unprotectedRatio = (unprotected + noContraception) / sexDays;
    score += unprotectedRatio * 4.0;

    // Pareja nueva sin protecciÃ³n
    if (newPartner > 0) score += 3.0;

    // PÃ­ldora de emergencia
    score += shortPill * 1.5;

    // Dolor durante sexo
    if (painSex > 0) score += 1.0;

    // Mitigador: tiene anticonceptivo configurado
    if (contraceptive != null && contraceptive.isNotEmpty) {
      score -= 1.5;
    }

    return score.clamp(0.0, 10.0);
  }

  /// Score de salud menstrual (0.0-10.0).
  /// 0 = saludable, 10 = requiere atenciÃ³n urgente.
  double _calculateMenstrualHealthScore(
    Map<String, int> bleedingFreq,
    double avgCycle,
    bool isRegular,
    int periodDuration,
    List<String> conditions,
  ) {
    double score = 0;

    // Regularidad del ciclo
    if (!isRegular) score += 2.0;

    // DuraciÃ³n del ciclo fuera de rango normal (21-35 dÃ­as)
    if (avgCycle < 21 || avgCycle > 35) score += 2.0;

    // DuraciÃ³n del sangrado fuera de rango (3-7 dÃ­as)
    if (periodDuration < 3 || periodDuration > 7) score += 1.5;

    // Sangrado abundante
    final heavyDays = bleedingFreq['heavy_flow'] ?? 0;
    if (heavyDays >= 3) score += 2.0;

    // CoÃ¡gulos frecuentes
    final freqClots = bleedingFreq['frequent'] ?? 0;
    if (freqClots >= 2) score += 1.5;

    // Manchado intermenstrual
    final spotting = bleedingFreq['spotting'] ?? 0;
    if (spotting >= 5) score += 1.0;

    return score.clamp(0.0, 10.0);
  }

  /// Carga sintomÃ¡tica general (0.0-10.0).
  double _calculateOverallSymptomBurden(
    Map<String, int> painFreq,
    Map<String, int> flujoFreq,
    Map<String, int> breastFreq,
    List<String> conditions,
  ) {
    double score = 0;
    int totalSymptoms = 0;

    // Sumar todos los sÃ­ntomas con sus scores base
    void addFromMap(Map<String, int> freq) {
      for (var entry in freq.entries) {
        final def = ClinicalDictionary.dictionary[entry.key];
        if (def != null && def.baseScore > 0) {
          totalSymptoms += entry.value;
          score += def.baseScore * entry.value * 0.1;
        }
      }
    }

    addFromMap(painFreq);
    addFromMap(flujoFreq);
    addFromMap(breastFreq);

    // Normalizar por cantidad de sÃ­ntomas
    if (totalSymptoms > 0) {
      score = score / totalSymptoms * 3.0;
    }

    return score.clamp(0.0, 10.0);
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  HELPERS PRIVADOS
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  String _fmt(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  List<String> _parseJsonArray(dynamic value) {
    if (value == null) return [];
    try {
      final list = List<String>.from(jsonDecode(value.toString()));
      return list.where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// Verifica si una alerta HIGH debe dispararse para un grupo de sÃ­ntomas.
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

  /// Verifica que un log tenga datos reales (no una fila vacÃ­a).
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

  /// Extrae todas las llaves clÃ­nicas de un registro diario.
  List<String> _extractAllItemsFromLog(Map<String, dynamic> log) {
    List<String> items = [];

    // SÃ­ntomas generales, fÃ­sicos, emocionales
    _addJsonArrayItems(items, log['symptoms']);
    _addJsonArrayItems(items, log['physical_symptoms']);
    _addJsonArrayItems(items, log['emotional_symptoms']);

    // Flujo vaginal
    _addJsonArrayItems(items, log['flujo']);

    // Actividad sexual
    _addJsonArrayItems(items, log['sexo']);

    // PatrÃ³n de sangrado
    if (log['bleeding_intensity'] != null &&
        log['bleeding_intensity'].toString().isNotEmpty &&
        log['bleeding_intensity'].toString() != 'null') {
      items.add(log['bleeding_intensity'].toString());
    }
    if (log['clots'] != null &&
        log['clots'].toString().isNotEmpty &&
        log['clots'].toString() != 'null' &&
        log['clots'].toString() != 'never') {
      items.add(log['clots'].toString());
    }
    if ((log['spotting'] as int?) == 1) {
      items.add('spotting');
    }

    // Autoexamen de mama (solo anomalÃ­as)
    if (log['breast_exam'] != null) {
      final breast = log['breast_exam'].toString();
      if (breast.isNotEmpty &&
          breast != 'breast_normal' &&
          breast != 'breast_pending') {
        items.add(breast);
      }
    }

    // Nivel de dolor â†’ mapear a sÃ­ntoma
    if (log['pain_level'] != null) {
      final painLevel = (log['pain_level'] as num?)?.toDouble() ?? 0;
      if (painLevel >= 8) {
        items.add('severe_pain');
      } else if (painLevel >= 4) {
        items.add('pelvic_pain');
      }
    }

    // CarÃ¡cter del dolor
    if (log['pain_character'] != null &&
        log['pain_character'].toString().isNotEmpty) {
      items.add(log['pain_character'].toString());
    }

    // Estado de Ã¡nimo
    if (log['mood'] != null && log['mood'].toString().isNotEmpty) {
      items.add(log['mood'].toString());
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//  TERMINALES DE DERIVACIÃ“N (ADAPTADAS A ZONAS RURALES / COSTA CARIBE)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

enum HealthcareTier {
  /// Puesto de Salud / Centro de Salud (AtenciÃ³n Primaria, Medicina General, PlanificaciÃ³n)
  primaryCare,
  
  /// Emergencias 24/7 (Hospital Primario / Departamental)
  emergency,
  
  /// Especialidad GinecolÃ³gica (Hospital Primario / Regional)
  gynecology,
  
  /// ImagenologÃ­a y DiagnÃ³stico Especializado (Ultrasonido, MamografÃ­a - Hospital Regional o Jornadas)
  specializedImaging,
  
}

class RecommendationTerminal {
  final HealthcareTier tier;
  final String title;
  final String description;

  const RecommendationTerminal({
    required this.tier,
    required this.title,
    required this.description,
  });
}

class HealthcareRoutingService {
  static const Map<HealthcareTier, RecommendationTerminal> terminals = {
    HealthcareTier.emergency: RecommendationTerminal(
      tier: HealthcareTier.emergency,
      title: 'Urgencias MÃ©dicas (AtenciÃ³n Inmediata)',
      description: 'Acude de inmediato a la sala de emergencias del hospital mÃ¡s cercano (Hospital Primario o Departamental).',
    ),
    HealthcareTier.primaryCare: RecommendationTerminal(
      tier: HealthcareTier.primaryCare,
      title: 'Centro de Salud / Puesto de Salud',
      description: 'Visita tu centro de salud local para consulta general, enfermerÃ­a, pruebas bÃ¡sicas o planificaciÃ³n familiar.',
    ),
    HealthcareTier.gynecology: RecommendationTerminal(
      tier: HealthcareTier.gynecology,
      title: 'GinecologÃ­a (Hospital Regional)',
      description: 'Requiere evaluaciÃ³n por un especialista en ginecologÃ­a. Solicita traslado o cita en el Hospital Primario/Regional.',
    ),
    HealthcareTier.specializedImaging: RecommendationTerminal(
      tier: HealthcareTier.specializedImaging,
      title: 'ExÃ¡menes Especializados (Ultrasonido / MamografÃ­a)',
      description: 'Requiere exÃ¡menes de imagen. Generalmente disponibles en Hospitales Regionales, clÃ­nicas especializadas o Brigadas MÃ©dicas.',
    ),
  };

  /// Deriva una lista de alertas clÃ­nicas a las terminales de atenciÃ³n mÃ¡s adecuadas
  /// para entornos de recursos limitados.
  static List<RecommendationTerminal> routeAlerts(List<ClinicalAlert> alerts) {
    final Set<HealthcareTier> requiredTiers = {};

    for (var alert in alerts) {
      if (alert.severity == 'high') {
        if (alert.category == 'pain' || alert.category == 'bleeding') {
          requiredTiers.add(HealthcareTier.emergency);
        } else if (alert.category == 'oncology' || alert.category == 'breast') {
          requiredTiers.add(HealthcareTier.specializedImaging);
          requiredTiers.add(HealthcareTier.gynecology);
        } else if (alert.category == 'infection' || alert.category == 'sexual_risk') {
          requiredTiers.add(HealthcareTier.primaryCare); // Las ITS y flujos se tratan primero en el Puesto de Salud
        } else {
          requiredTiers.add(HealthcareTier.gynecology); // Riesgo de embarazo, etc.
        }
      } else if (alert.severity == 'medium') {
        if (alert.category == 'general_health') {
          requiredTiers.add(HealthcareTier.primaryCare);
        } else if (alert.category == 'bleeding' || alert.category == 'menorrhagia' || alert.category == 'sexual_pain') {
          requiredTiers.add(HealthcareTier.gynecology);
        } else if (alert.category == 'flow_anomaly') {
          requiredTiers.add(HealthcareTier.primaryCare);
        }
      } else { // Low
        if (alert.category == 'emotional') {
          requiredTiers.add(HealthcareTier.primaryCare); // Salud emocional se aborda primero en atenciÃ³n primaria
        } else {
          requiredTiers.add(HealthcareTier.primaryCare);
        }
      }
    }

    // Si no hay alertas, la recomendaciÃ³n base para chequeos es atenciÃ³n primaria
    if (requiredTiers.isEmpty) {
      requiredTiers.add(HealthcareTier.primaryCare);
    }

    // Convertir a lista y ordenar por prioridad (Emergencia siempre primero)
    final sortedTiers = requiredTiers.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return sortedTiers.map((t) => terminals[t]!).toList();
  }
}
