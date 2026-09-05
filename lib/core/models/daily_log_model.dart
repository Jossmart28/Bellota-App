import 'dart:convert';

/// Modelo de datos para el registro diario del ciclo menstrual.
///
/// Consolida todos los datos que previamente estaban divididos entre
/// SQLite y SharedPreferences en una sola estructura unificada.
class DailyLogModel {
  /// ID único del registro en la base de datos
  final int? id;
  
  /// ID del usuario al que pertenece este registro
  final int userId;
  
  /// Fecha del registro en formato 'YYYY-MM-DD'
  final String date;
  
  // Seguimiento del periodo
  /// Indica si es el inicio del periodo
  final bool periodStart;
  /// Indica si es el fin del periodo
  final bool periodEnd;
  
  // Síntomas
  /// Lista de síntomas generales experimentados
  final List<String> symptoms;
  /// Lista de actividades sexuales o relacionadas
  final List<String> sexo;
  /// Lista de tipos de flujo cervical observados
  final List<String> flujo;
  
  // Patrón de sangrado
  /// Intensidad del sangrado ('light', 'moderate', 'heavy')
  final String? bleedingIntensity;
  /// Presencia de coágulos ('never', 'occasional', 'frequent')
  final String? clots;
  /// Indica si hubo manchado intermenstrual (spotting)
  final bool spotting;
  /// Días del ciclo en los que ocurrió el manchado
  final String? spottingDays;
  /// Síntomas durante las relaciones sexuales ('pain', 'bleeding', 'unusual_flow', 'none')
  final String? sexualSymptoms;
  
  // Dolor y sintomatología
  /// Nivel de dolor en escala EVA de 0 a 10
  final double? painLevel;
  /// Carácter del dolor ('incapacitating', 'non_incapacitating')
  final String? painCharacter;
  /// Días críticos de dolor
  final String? painDays;
  /// Tratamiento utilizado ('medication', 'thermal', 'none')
  final String? treatment;
  /// Síntomas físicos (cólicos, migraña, mastalgia, etc.)
  final List<String> physicalSymptoms;
  /// Síntomas emocionales (ansiedad, cambios de humor, fatiga, etc.)
  final List<String> emotionalSymptoms;
  /// Estado del autoexamen de mama ('done', 'pending')
  final String? breastExam;
  
  // Notas
  /// Notas adicionales para este día
  final String? notes;
  
  /// Fecha y hora de creación de este registro
  final DateTime createdAt;

  /// Constructor constante con todos los parámetros
  const DailyLogModel({
    this.id,
    required this.userId,
    required this.date,
    this.periodStart = false,
    this.periodEnd = false,
    this.symptoms = const [],
    this.sexo = const [],
    this.flujo = const [],
    this.bleedingIntensity,
    this.clots,
    this.spotting = false,
    this.spottingDays,
    this.sexualSymptoms,
    this.painLevel,
    this.painCharacter,
    this.painDays,
    this.treatment,
    this.physicalSymptoms = const [],
    this.emotionalSymptoms = const [],
    this.breastExam,
    this.notes,
    required this.createdAt,
  });

  /// Crea un registro diario vacío para un usuario y fecha específicos.
  static DailyLogModel empty(int userId, String date) {
    return DailyLogModel(
      userId: userId,
      date: date,
      createdAt: DateTime.now(),
    );
  }

  /// Deserializa desde un Map (usualmente de SQLite).
  factory DailyLogModel.fromMap(Map<String, dynamic> map) {
    return DailyLogModel(
      id: map['id'] != null ? map['id'] as int : null,
      userId: map['user_id'] as int,
      date: map['date'] as String,
      periodStart: map['period_start'] == 1,
      periodEnd: map['period_end'] == 1,
      symptoms: _parseStringList(map['symptoms']),
      sexo: _parseStringList(map['sexo']),
      flujo: _parseStringList(map['flujo']),
      bleedingIntensity: map['bleeding_intensity'] as String?,
      clots: map['clots'] as String?,
      spotting: map['spotting'] == 1,
      spottingDays: map['spotting_days'] as String?,
      sexualSymptoms: map['sexual_symptoms'] as String?,
      painLevel: map['pain_level'] != null ? (map['pain_level'] as num).toDouble() : null,
      painCharacter: map['pain_character'] as String?,
      painDays: map['pain_days'] as String?,
      treatment: map['treatment'] as String?,
      physicalSymptoms: _parseStringList(map['physical_symptoms']),
      emotionalSymptoms: _parseStringList(map['emotional_symptoms']),
      breastExam: map['breast_exam'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : DateTime.now(),
    );
  }

  /// Función auxiliar para decodificar listas de JSON o strings de forma segura.
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      if (value.isEmpty) return [];
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return List<String>.from(decoded.map((e) => e.toString()));
      } catch (e) {
        // En caso de error de decodificación, retornar lista vacía
        return [];
      }
    } else if (value is List) {
      return List<String>.from(value.map((e) => e.toString()));
    }
    return [];
  }

  /// Serializa para inserción/actualización en la base de datos.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'date': date,
      'period_start': periodStart ? 1 : 0,
      'period_end': periodEnd ? 1 : 0,
      'symptoms': jsonEncode(symptoms),
      'sexo': jsonEncode(sexo),
      'flujo': jsonEncode(flujo),
      'bleeding_intensity': bleedingIntensity,
      'clots': clots,
      'spotting': spotting ? 1 : 0,
      'spotting_days': spottingDays,
      'sexual_symptoms': sexualSymptoms,
      'pain_level': painLevel,
      'pain_character': painCharacter,
      'pain_days': painDays,
      'treatment': treatment,
      'physical_symptoms': jsonEncode(physicalSymptoms),
      'emotional_symptoms': jsonEncode(emotionalSymptoms),
      'breast_exam': breastExam,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crea una copia inmutable con campos actualizados.
  DailyLogModel copyWith({
    int? id,
    int? userId,
    String? date,
    bool? periodStart,
    bool? periodEnd,
    List<String>? symptoms,
    List<String>? sexo,
    List<String>? flujo,
    String? bleedingIntensity,
    String? clots,
    bool? spotting,
    String? spottingDays,
    String? sexualSymptoms,
    double? painLevel,
    String? painCharacter,
    String? painDays,
    String? treatment,
    List<String>? physicalSymptoms,
    List<String>? emotionalSymptoms,
    String? breastExam,
    String? notes,
    DateTime? createdAt,
  }) {
    return DailyLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      symptoms: symptoms ?? this.symptoms,
      sexo: sexo ?? this.sexo,
      flujo: flujo ?? this.flujo,
      bleedingIntensity: bleedingIntensity ?? this.bleedingIntensity,
      clots: clots ?? this.clots,
      spotting: spotting ?? this.spotting,
      spottingDays: spottingDays ?? this.spottingDays,
      sexualSymptoms: sexualSymptoms ?? this.sexualSymptoms,
      painLevel: painLevel ?? this.painLevel,
      painCharacter: painCharacter ?? this.painCharacter,
      painDays: painDays ?? this.painDays,
      treatment: treatment ?? this.treatment,
      physicalSymptoms: physicalSymptoms ?? this.physicalSymptoms,
      emotionalSymptoms: emotionalSymptoms ?? this.emotionalSymptoms,
      breastExam: breastExam ?? this.breastExam,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Retorna verdadero si hay datos de período.
  bool get hasPeriodData => periodStart || periodEnd;

  /// Retorna verdadero si hay algún dato de sangrado configurado.
  bool get hasBleedingData =>
      bleedingIntensity != null ||
      clots != null ||
      spotting ||
      spottingDays != null ||
      sexualSymptoms != null;

  /// Retorna verdadero si hay algún dato de dolor configurado.
  bool get hasPainData =>
      painLevel != null ||
      painCharacter != null ||
      painDays != null ||
      treatment != null ||
      physicalSymptoms.isNotEmpty ||
      emotionalSymptoms.isNotEmpty ||
      breastExam != null;

  /// Retorna verdadero si cualquier campo además de userId o date contiene datos.
  bool get hasAnyData =>
      hasPeriodData ||
      hasBleedingData ||
      hasPainData ||
      symptoms.isNotEmpty ||
      sexo.isNotEmpty ||
      flujo.isNotEmpty ||
      notes != null;

  /// Parsea la cadena de fecha a un objeto DateTime (a medianoche).
  DateTime get dateTime => DateTime.tryParse(date) ?? DateTime.now();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyLogModel &&
        other.id == id &&
        other.userId == userId &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, userId, date);

  @override
  String toString() {
    return 'DailyLogModel(id: $id, userId: $userId, date: $date)';
  }
}
