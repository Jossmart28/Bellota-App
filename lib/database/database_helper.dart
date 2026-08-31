import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/user_model.dart';
import '../core/models/profile_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bellota.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _onOpen,
    );
  }

  Future _onOpen(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await _createProfilesTable(db);
    await _createDailyLogsTable(db);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
    ''');
    await _createProfilesTable(db);
    await _createDailyLogsTableV2(db);
  }

  /// Migración de v1 a v2: agrega columnas de sangrado, dolor y síntomas
  /// emocionales/físicos a daily_logs, y migra datos de SharedPreferences.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar columnas nuevas a daily_logs existente
      final columns = [
        'ALTER TABLE daily_logs ADD COLUMN bleeding_intensity TEXT DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN clots TEXT DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN spotting INTEGER DEFAULT 0',
        'ALTER TABLE daily_logs ADD COLUMN spotting_days TEXT DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN sexual_symptoms TEXT DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN pain_level REAL DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN pain_character TEXT DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN pain_days TEXT DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN treatment TEXT DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN physical_symptoms TEXT DEFAULT \'[]\'',
        'ALTER TABLE daily_logs ADD COLUMN emotional_symptoms TEXT DEFAULT \'[]\'',
        'ALTER TABLE daily_logs ADD COLUMN breast_exam TEXT DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN period_end INTEGER DEFAULT 0',
        'ALTER TABLE daily_logs ADD COLUMN notes TEXT DEFAULT NULL',
      ];

      for (final col in columns) {
        try {
          await db.execute(col);
        } catch (_) {
          // Columna ya existe — ignorar
        }
      }

      // Actualizar period_duration default de 7 a 5 en perfiles que aún tienen 7
      // (solo si el usuario nunca lo cambió manualmente)
      // No cambiamos el valor existente del usuario ya que pudo haberlo elegido

      // Migrar datos de SharedPreferences a SQLite
      await _migrateSharedPreferencesData(db);
    }
  }

  /// Migra datos de patrón de sangrado y dolor almacenados en SharedPreferences
  /// a la tabla daily_logs en SQLite (operación única post-upgrade).
  Future<void> _migrateSharedPreferencesData(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      for (final key in allKeys) {
        if (key.startsWith('patron_sangrado_') || key.startsWith('dolor_sintomatologia_')) {
          final dateKey = key.replaceFirst('patron_sangrado_', '').replaceFirst('dolor_sintomatologia_', '');
          // Validar formato de fecha YYYY-MM-DD
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey)) continue;

          final jsonStr = prefs.getString(key);
          if (jsonStr == null) continue;

          final data = jsonDecode(jsonStr) as Map<String, dynamic>;

          if (key.startsWith('patron_sangrado_')) {
            // Actualizar el daily_log correspondiente
            await db.update(
              'daily_logs',
              {
                'bleeding_intensity': data['intensidadFlujo'],
                'clots': data['coagulos'],
                'spotting': (data['manchado'] == 'Sí' || data['manchado'] == 'Yes') ? 1 : 0,
                'spotting_days': data['manchadoDias'],
                'sexual_symptoms': data['sintomasSexuales'],
              },
              where: 'date = ?',
              whereArgs: [dateKey],
            );
          } else if (key.startsWith('dolor_sintomatologia_')) {
            await db.update(
              'daily_logs',
              {
                'pain_level': data['nivelDolor']?.toDouble(),
                'pain_character': data['caracterDolor'],
                'pain_days': data['diasDolor'],
                'treatment': data['tratamiento'],
                'physical_symptoms': jsonEncode(data['sintomasFisicos'] ?? []),
                'emotional_symptoms': jsonEncode(data['sintomasEmocionales'] ?? []),
                'breast_exam': data['autoexamenMama'],
              },
              where: 'date = ?',
              whereArgs: [dateKey],
            );
          }

          // Limpiar la clave migrada de SharedPreferences
          await prefs.remove(key);
        }
      }
    } catch (_) {
      // No interrumpir la app si la migración falla parcialmente
    }
  }

  Future _createProfilesTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS profiles (
      user_id INTEGER PRIMARY KEY,
      username TEXT,
      gmail TEXT,
      cycle_duration INTEGER DEFAULT 28,
      period_duration INTEGER DEFAULT 5,
      profile_image_path TEXT,
      notif_periodo INTEGER DEFAULT 1,
      notif_ovulacion INTEGER DEFAULT 1,
      notif_pildora INTEGER DEFAULT 0,
      notif_hidratacion INTEGER DEFAULT 0,
      notif_ejercicio INTEGER DEFAULT 0,
      notif_app INTEGER DEFAULT 1,
      notif_sonidos INTEGER DEFAULT 1,
      notif_cita_medica INTEGER DEFAULT 0,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');
  }

  /// Tabla daily_logs versión 1 (legacy, para compatibilidad con _upgradeDB)
  Future _createDailyLogsTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS daily_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      date TEXT NOT NULL,
      period_start INTEGER DEFAULT 0,
      symptoms TEXT DEFAULT '[]',
      sexo TEXT DEFAULT '[]',
      flujo TEXT DEFAULT '[]',
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');
  }

  /// Tabla daily_logs versión 2 completa (para nuevas instalaciones)
  Future _createDailyLogsTableV2(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS daily_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      date TEXT NOT NULL,
      period_start INTEGER DEFAULT 0,
      period_end INTEGER DEFAULT 0,
      symptoms TEXT DEFAULT '[]',
      sexo TEXT DEFAULT '[]',
      flujo TEXT DEFAULT '[]',
      bleeding_intensity TEXT DEFAULT NULL,
      clots TEXT DEFAULT NULL,
      spotting INTEGER DEFAULT 0,
      spotting_days TEXT DEFAULT NULL,
      sexual_symptoms TEXT DEFAULT NULL,
      pain_level REAL DEFAULT NULL,
      pain_character TEXT DEFAULT NULL,
      pain_days TEXT DEFAULT NULL,
      treatment TEXT DEFAULT NULL,
      physical_symptoms TEXT DEFAULT '[]',
      emotional_symptoms TEXT DEFAULT '[]',
      breast_exam TEXT DEFAULT NULL,
      notes TEXT DEFAULT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
      UNIQUE (user_id, date)
    )
    ''');
  }

  // Encriptar contraseña
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Registrar un nuevo usuario
  Future<int> registerUser(String name, String email, String password) async {
    final db = await instance.database;
    final data = {
      'name': name,
      'email': email.trim().toLowerCase(),
      'password_hash': _hashPassword(password),
      'created_at': DateTime.now().toIso8601String(),
    };
    final userId = await db.insert('users', data);

    await db.insert('profiles', {
      'user_id': userId,
      'username': name,
      'gmail': '',
      'cycle_duration': 28,
      'period_duration': 5,
      'profile_image_path': null,
      'notif_periodo': 1,
      'notif_ovulacion': 1,
      'notif_pildora': 0,
      'notif_hidratacion': 0,
      'notif_ejercicio': 0,
      'notif_app': 1,
      'notif_sonidos': 1,
      'notif_cita_medica': 0,
    });

    return userId;
  }

  // Iniciar sesión
  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await instance.database;
    final hashed = _hashPassword(password);

    final result = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.trim().toLowerCase(), hashed],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Verificar si un correo ya existe
  Future<bool> emailExists(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    return result.isNotEmpty;
  }

  // Obtener el ID de un usuario por su correo electrónico
  Future<int?> getUserIdByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int?;
    }
    return null;
  }

  // Obtener usuario por correo electrónico
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Obtener el perfil de un usuario
  Future<Map<String, dynamic>?> getProfile(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    // Si no existe, lo creamos dinámicamente con los datos de 'users'
    final userResult = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (userResult.isNotEmpty) {
      final user = userResult.first;
      final name = user['name'] as String? ?? 'UsuarioApp';
      final defaultProfile = {
        'user_id': userId,
        'username': name,
        'gmail': '',
        'cycle_duration': 28,
        'period_duration': 5,
        'profile_image_path': null,
        'notif_periodo': 1,
        'notif_ovulacion': 1,
        'notif_pildora': 0,
        'notif_hidratacion': 0,
        'notif_ejercicio': 0,
        'notif_app': 1,
        'notif_sonidos': 1,
        'notif_cita_medica': 0,
      };
      await db.insert('profiles', defaultProfile);
      return defaultProfile;
    }
    return null;
  }

  // Actualizar un campo específico del perfil
  Future<int> updateProfileField(int userId, String field, dynamic value) async {
    final db = await instance.database;
    // Asegurar que el perfil exista
    await getProfile(userId);

    return await db.update(
      'profiles',
      {field: value},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ──────────────────────────────────────
  // DAILY LOGS - Registro diario por fecha
  // ──────────────────────────────────────

  /// Guarda o actualiza el registro diario para una fecha específica (legacy v1)
  Future<int> saveDailyLog({
    required int userId,
    required String date,
    required bool periodStart,
    required List<String> symptoms,
    required List<String> sexo,
    required List<String> flujo,
  }) async {
    final db = await instance.database;

    // Verificar si ya existe un registro para esta fecha
    final existing = await db.query(
      'daily_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    final data = {
      'user_id': userId,
      'date': date,
      'period_start': periodStart ? 1 : 0,
      'symptoms': jsonEncode(symptoms),
      'sexo': jsonEncode(sexo),
      'flujo': jsonEncode(flujo),
      'created_at': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      return await db.update(
        'daily_logs',
        data,
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, date],
      );
    } else {
      return await db.insert('daily_logs', data);
    }
  }

  /// Guarda o actualiza el registro diario completo v2 con todos los campos
  /// consolidados (patrón de sangrado, dolor, síntomas emocionales/físicos).
  Future<int> saveDailyLogV2({
    required int userId,
    required String date,
    required bool periodStart,
    bool periodEnd = false,
    required List<String> symptoms,
    required List<String> sexo,
    required List<String> flujo,
    // Patrón de sangrado
    String? bleedingIntensity,
    String? clots,
    bool spotting = false,
    String? spottingDays,
    String? sexualSymptoms,
    // Dolor y sintomatología
    double? painLevel,
    String? painCharacter,
    String? painDays,
    String? treatment,
    List<String> physicalSymptoms = const [],
    List<String> emotionalSymptoms = const [],
    String? breastExam,
    String? notes,
  }) async {
    final db = await instance.database;

    final existing = await db.query(
      'daily_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    final data = {
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
      'created_at': DateTime.now().toIso8601String(),
    };

    if (existing.isNotEmpty) {
      return await db.update(
        'daily_logs',
        data,
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, date],
      );
    } else {
      return await db.insert('daily_logs', data);
    }
  }

  /// Obtiene el registro diario para una fecha específica
  Future<Map<String, dynamic>?> getDailyLog(int userId, String date) async {
    final db = await instance.database;

    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// Verifica si existe un registro para una fecha determinada
  Future<bool> hasLogForDate(int userId, String date) async {
    final db = await instance.database;

    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
    return result.isNotEmpty;
  }

  /// Obtiene los registros diarios de un rango de fechas.
  /// Las fechas deben estar en formato 'YYYY-MM-DD'.
  Future<List<Map<String, dynamic>>> getLogsInRange(
    int userId,
    String startDate,
    String endDate,
  ) async {
    final db = await instance.database;

    return await db.query(
      'daily_logs',
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date ASC',
    );
  }

  /// Obtiene la última fecha en que se registró el inicio de un período
  Future<DateTime?> getLastPeriodStart(int userId) async {
    final db = await instance.database;

    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND period_start = 1',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return _parseDateString(result.first['date'] as String);
    }
    return null;
  }

  /// Obtiene la primera fecha en que se registró el inicio de un período
  Future<DateTime?> getFirstPeriodStart(int userId) async {
    final db = await instance.database;

    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND period_start = 1',
      whereArgs: [userId],
      orderBy: 'date ASC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return _parseDateString(result.first['date'] as String);
    }
    return null;
  }

  /// Obtiene todos los registros diarios de un usuario ordenados por fecha
  Future<List<Map<String, dynamic>>> getAllDailyLogs(int userId) async {
    final db = await instance.database;

    return await db.query(
      'daily_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date ASC',
    );
  }

  /// Obtiene todas las fechas de inicio de período ordenadas DESC (más reciente primero)
  Future<List<DateTime>> getAllPeriodStartDates(int userId) async {
    final db = await instance.database;

    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND period_start = 1',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    List<DateTime> dates = [];
    for (final row in result) {
      final dt = _parseDateString(row['date'] as String);
      if (dt != null) dates.add(dt);
    }
    return dates;
  }

  /// Calcula estadísticas históricas del ciclo basándose en registros reales.
  /// Retorna un mapa con: averageCycleLength, shortestCycle, longestCycle,
  /// cycleLengths, isRegular.
  Future<Map<String, dynamic>> getCycleStatistics(int userId) async {
    final starts = await getAllPeriodStartDates(userId);

    if (starts.length < 2) {
      return {
        'averageCycleLength': null,
        'shortestCycle': null,
        'longestCycle': null,
        'cycleLengths': <int>[],
        'isRegular': true,
        'count': starts.length,
      };
    }

    // starts está en orden DESC, así que revertimos para calcular intervalos
    final sorted = starts.reversed.toList();
    List<int> cycleLengths = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final diff = _dateOnly(sorted[i + 1]).difference(_dateOnly(sorted[i])).inDays;
      if (diff > 0 && diff <= 90) {
        // Solo contar ciclos razonables (≤ 90 días para evitar datos erróneos)
        cycleLengths.add(diff);
      }
    }

    if (cycleLengths.isEmpty) {
      return {
        'averageCycleLength': null,
        'shortestCycle': null,
        'longestCycle': null,
        'cycleLengths': <int>[],
        'isRegular': true,
        'count': starts.length,
      };
    }

    final avg = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final shortest = cycleLengths.reduce((a, b) => a < b ? a : b);
    final longest = cycleLengths.reduce((a, b) => a > b ? a : b);
    final isRegular = cycleLengths.every((len) => (len - avg).abs() <= 7);

    return {
      'averageCycleLength': avg,
      'shortestCycle': shortest,
      'longestCycle': longest,
      'cycleLengths': cycleLengths,
      'isRegular': isRegular,
      'count': starts.length,
    };
  }

  // ── Helpers de parseo de fecha ──────────────────────────────────────────────

  /// Parsea una fecha en formato 'YYYY-MM-DD' a DateTime normalizado a medianoche.
  DateTime? _parseDateString(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  /// Normaliza un DateTime a medianoche (elimina componente de hora).
  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ── Métodos con tipos seguros (TypedAPI) ────────────────────────────────────
  // Los métodos anteriores retornan Map<String,dynamic> para retro-compatibilidad.
  // Estos nuevos métodos retornan modelos tipados para uso en código nuevo.

  /// Versión tipada de [loginUser]. Retorna un [UserModel] o `null`.
  Future<UserModel?> loginUserTyped(String email, String password) async {
    final map = await loginUser(email, password);
    return map != null ? UserModel.fromMap(map) : null;
  }

  /// Versión tipada de [getProfile]. Retorna un [ProfileModel] o `null`.
  Future<ProfileModel?> getProfileTyped(int userId) async {
    final map = await getProfile(userId);
    return map != null ? ProfileModel.fromMap(map) : null;
  }
}
