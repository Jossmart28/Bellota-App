import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bellotadevelopment/core/errors/app_logger.dart';

class DatabaseProvider {
  static Database? _database;

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
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _onOpen,
    );
  }

  Future _onOpen(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    // Las tablas dinámicas se crean si no existen
    await _createProfilesTable(db);
    await _createDailyLogsTableV2(db);
    await _createAuditLogsTable(db);
    await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_logs_user_date ON daily_logs(user_id, date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at, action)');
  }

  Future _createDB(Database db, int version) async {
    AppLogger.i('Creando base de datos inicial (v$version)');
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'usuario',
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      language_pref TEXT NOT NULL DEFAULT 'es'
    )
    ''');
    await _createProfilesTable(db);
    await _createDailyLogsTableV2(db);
    await _createAuditLogsTable(db);
    await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_logs_user_date ON daily_logs(user_id, date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at, action)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    AppLogger.i('Migrando base de datos de v$oldVersion a v$newVersion');
    
    if (oldVersion < 2) {
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
      await _safeExecuteBatch(db, columns);
      await _migrateSharedPreferencesData(db);
    }

    if (oldVersion < 3) {
      final userColumns = [
        "ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'usuario'",
        'ALTER TABLE users ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
      ];
      await _safeExecuteBatch(db, userColumns);
      await _createAuditLogsTable(db);
    }

    if (oldVersion < 4) {
      final profileCols = [
        'ALTER TABLE profiles ADD COLUMN notif_daily_log INTEGER DEFAULT 1',
        'ALTER TABLE profiles ADD COLUMN notif_log_hour INTEGER DEFAULT 21',
        'ALTER TABLE profiles ADD COLUMN notif_log_minute INTEGER DEFAULT 0',
      ];
      await _safeExecuteBatch(db, profileCols);
      await _createPillTimesTable(db);
      await _createWeeklyAppointmentsTable(db);
    }

    if (oldVersion < 5) {
      final profileCols = [
        'ALTER TABLE profiles ADD COLUMN medical_conditions TEXT DEFAULT \'[]\'',
        'ALTER TABLE profiles ADD COLUMN contraceptive TEXT DEFAULT NULL',
      ];
      await _safeExecuteBatch(db, profileCols);
      
      final logCols = [
        'ALTER TABLE daily_logs ADD COLUMN basal_temp REAL DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN lh_test_result TEXT DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN cervical_position TEXT DEFAULT NULL',
        'ALTER TABLE daily_logs ADD COLUMN mood TEXT DEFAULT NULL',
      ];
      await _safeExecuteBatch(db, logCols);
    }

    if (oldVersion < 6) {
      await _safeExecuteBatch(db, ["ALTER TABLE users ADD COLUMN language_pref TEXT NOT NULL DEFAULT 'es'"]);
    }
  }

  /// Ejecuta múltiples queries ignorando errores si la columna ya existe
  Future<void> _safeExecuteBatch(Database db, List<String> queries) async {
    for (final col in queries) {
      try {
        await db.execute(col);
      } catch (e) {
        AppLogger.w('Excepción ignorada durante migración (probablemente la columna ya existía): $e');
      }
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
      notif_daily_log INTEGER DEFAULT 1,
      notif_log_hour INTEGER DEFAULT 21,
      notif_log_minute INTEGER DEFAULT 0,
      medical_conditions TEXT DEFAULT '[]',
      contraceptive TEXT DEFAULT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');
    await _createPillTimesTable(db);
    await _createWeeklyAppointmentsTable(db);
  }

  Future _createPillTimesTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS pill_times (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      hour INTEGER NOT NULL,
      minute INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');
  }

  Future _createWeeklyAppointmentsTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS weekly_appointments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      weekday INTEGER NOT NULL,
      hour INTEGER NOT NULL,
      minute INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');
  }

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
      basal_temp REAL DEFAULT NULL,
      lh_test_result TEXT DEFAULT NULL,
      cervical_position TEXT DEFAULT NULL,
      mood TEXT DEFAULT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
      UNIQUE (user_id, date)
    )
    ''');
  }

  Future _createAuditLogsTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS audit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      action TEXT NOT NULL,
      target_type TEXT,
      target_id INTEGER,
      details TEXT,
      ip_address TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
    )
    ''');
  }

  Future<void> _migrateSharedPreferencesData(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      for (final key in allKeys) {
        if (key.startsWith('patron_sangrado_') || key.startsWith('dolor_sintomatologia_')) {
          final dateKey = key.replaceFirst('patron_sangrado_', '').replaceFirst('dolor_sintomatologia_', '');
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateKey)) continue;

          final jsonStr = prefs.getString(key);
          if (jsonStr == null) continue;

          final data = jsonDecode(jsonStr) as Map<String, dynamic>;

          if (key.startsWith('patron_sangrado_')) {
            await db.update('daily_logs', {
                'bleeding_intensity': data['intensidadFlujo'],
                'clots': data['coagulos'],
                'spotting': (data['manchado'] == 'Sí' || data['manchado'] == 'Yes') ? 1 : 0,
                'spotting_days': data['manchadoDias'],
                'sexual_symptoms': data['sintomasSexuales'],
              },
              where: 'date = ?', whereArgs: [dateKey],
            );
          } else if (key.startsWith('dolor_sintomatologia_')) {
            await db.update('daily_logs', {
                'pain_level': data['nivelDolor']?.toDouble(),
                'pain_character': data['caracterDolor'],
                'pain_days': data['diasDolor'],
                'treatment': data['tratamiento'],
                'physical_symptoms': jsonEncode(data['sintomasFisicos'] ?? []),
                'emotional_symptoms': jsonEncode(data['sintomasEmocionales'] ?? []),
                'breast_exam': data['autoexamenMama'],
              },
              where: 'date = ?', whereArgs: [dateKey],
            );
          }
          await prefs.remove(key);
        }
      }
    } catch (e) {
      AppLogger.e('Error migrando datos desde SharedPreferences', e);
    }
  }
}
