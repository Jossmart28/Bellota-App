import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/user_model.dart';
import '../core/models/profile_model.dart';
import '../core/models/audit_log_model.dart';

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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: _onOpen,
    );
  }

  Future _onOpen(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await _createProfilesTable(db);
    await _createDailyLogsTableV2(db);
    await _createAuditLogsTable(db);
    await _seedAdminUser(db);
  }

  Future _seedAdminUser(Database db) async {
    final email = 'usm.unshowmas@gmail.com';
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isEmpty) {
      final hashed = _hashPassword('UsmAdmin26!');
      final userId = await db.insert('users', {
        'name': 'Administrador',
        'email': email,
        'password_hash': hashed,
        'role': 'admin',
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('profiles', {
        'user_id': userId,
        'username': 'Administrador',
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
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'usuario',
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL
    )
    ''');
    await _createProfilesTable(db);
    await _createDailyLogsTableV2(db);
    await _createAuditLogsTable(db);
  }

  /// Migración de v1 a v2: agrega columnas de sangrado, dolor y síntomas
  /// emocionales/físicos a daily_logs, y migra datos de SharedPreferences.
  /// Migración de v2 a v3: agrega columnas de rol y estado activo a users,
  /// y crea la tabla audit_logs.
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

      // Migrar datos de SharedPreferences a SQLite
      await _migrateSharedPreferencesData(db);
    }

    if (oldVersion < 3) {
      final userColumns = [
        "ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'usuario'",
        'ALTER TABLE users ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1',
      ];

      for (final col in userColumns) {
        try {
          await db.execute(col);
        } catch (_) {}
      }

      await _createAuditLogsTable(db);
    }

    if (oldVersion < 4) {
      // New notification prefs columns in profiles
      final profileCols = [
        'ALTER TABLE profiles ADD COLUMN notif_daily_log INTEGER DEFAULT 1',
        'ALTER TABLE profiles ADD COLUMN notif_log_hour INTEGER DEFAULT 21',
        'ALTER TABLE profiles ADD COLUMN notif_log_minute INTEGER DEFAULT 0',
      ];
      for (final col in profileCols) {
        try { await db.execute(col); } catch (_) {}
      }
      await _createPillTimesTable(db);
      await _createWeeklyAppointmentsTable(db);
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
      notif_daily_log INTEGER DEFAULT 1,
      notif_log_hour INTEGER DEFAULT 21,
      notif_log_minute INTEGER DEFAULT 0,
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

  /// Tabla audit_logs para registrar acciones de usuarios (v3+).
  ///
  /// Almacena quién hizo qué, cuándo y sobre qué recurso,
  /// permitiendo al Auditor revisar el historial de actividad.
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

  // ── Autenticación ──────────────────────────────────────────────────────────

  // Encriptar contraseña
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Registra un nuevo usuario con un rol opcional (por defecto 'usuario').
  Future<int> registerUser(
    String name,
    String email,
    String password, {
    String role = 'usuario',
  }) async {
    if (email.trim().toLowerCase() == 'usm.unshowmas@gmail.com') {
      throw Exception('Este correo está reservado y no puede ser registrado.');
    }

    final db = await instance.database;
    final data = {
      'name': name,
      'email': email.trim().toLowerCase(),
      'password_hash': _hashPassword(password),
      'role': role,
      'is_active': 1,
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
      where: 'email = ? AND password_hash = ? AND is_active = 1',
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

  // ── Perfil de usuario ──────────────────────────────────────────────────────

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

  // ──────────────────────────────────────────────────────────────────────────
  // ADMIN — Gestión de usuarios
  // ──────────────────────────────────────────────────────────────────────────

  /// Retorna todos los usuarios registrados (sólo para [UserRole.admin]).
  ///
  /// Incluye: id, name, email, role, is_active, created_at.
  /// No incluye password_hash por seguridad.
  Future<List<Map<String, dynamic>>> getAllUsers({
    int? limit,
    int offset = 0,
  }) async {
    final db = await instance.database;
    return await db.query(
      'users',
      columns: ['id', 'name', 'email', 'role', 'is_active', 'created_at'],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Retorna el total de usuarios registrados.
  Future<int> getUserCount() async {
    final db = await instance.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return result.first['count'] as int? ?? 0;
  }

  /// Cambia el rol de un usuario específico.
  /// Sólo debe ser llamado por un [UserRole.admin].
  Future<int> updateUserRole(int userId, String newRole) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'role': newRole},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Suspende una cuenta de usuario (is_active = 0).
  /// El usuario no podrá iniciar sesión mientras esté suspendido.
  Future<int> suspendUser(int userId) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Reactiva una cuenta de usuario suspendida (is_active = 1).
  Future<int> reactivateUser(int userId) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Elimina un usuario y todos sus datos asociados (CASCADE).
  /// Sólo debe ser llamado por un [UserRole.admin].
  Future<int> deleteUser(int userId) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Verifica si existe al menos un administrador en el sistema.
  /// Útil para el flujo de bootstrapping del primer admin.
  Future<bool> hasAdminUser() async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      columns: ['id'],
      where: 'role = ?',
      whereArgs: ['admin'],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AUDIT LOGS — Registro de acciones
  // ──────────────────────────────────────────────────────────────────────────

  /// Inserta un nuevo registro de auditoría.
  ///
  /// Parámetros:
  /// - [userId]: ID del usuario que realizó la acción (puede ser null para acciones de sistema).
  /// - [action]: Identificador de la acción (ej: 'login', 'role_change').
  /// - [targetType]: Tipo del recurso afectado (ej: 'user', 'daily_log').
  /// - [targetId]: ID del recurso afectado.
  /// - [details]: Mapa con contexto adicional (antes/después, etc.).
  Future<int> insertAuditLog({
    int? userId,
    required String action,
    String? targetType,
    int? targetId,
    Map<String, dynamic>? details,
    String? ipAddress,
  }) async {
    final db = await instance.database;
    return await db.insert('audit_logs', {
      'user_id': userId,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'details': details != null ? jsonEncode(details) : null,
      'ip_address': ipAddress,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Consulta logs de auditoría con filtros opcionales.
  ///
  /// Parámetros de filtro:
  /// - [userId]: Filtrar por usuario específico.
  /// - [action]: Filtrar por tipo de acción.
  /// - [targetType]: Filtrar por tipo de recurso.
  /// - [startDate]: Fecha de inicio (formato 'YYYY-MM-DD').
  /// - [endDate]: Fecha de fin (formato 'YYYY-MM-DD').
  /// - [limit]: Máximo de resultados (default: 50).
  /// - [offset]: Offset para paginación.
  Future<List<AuditLogModel>> getAuditLogs({
    int? userId,
    String? action,
    String? targetType,
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await instance.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (userId != null) {
      conditions.add('user_id = ?');
      args.add(userId);
    }
    if (action != null && action.isNotEmpty) {
      conditions.add('action = ?');
      args.add(action);
    }
    if (targetType != null && targetType.isNotEmpty) {
      conditions.add('target_type = ?');
      args.add(targetType);
    }
    if (startDate != null) {
      conditions.add("created_at >= ?");
      args.add('$startDate 00:00:00');
    }
    if (endDate != null) {
      conditions.add("created_at <= ?");
      args.add('$endDate 23:59:59');
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');

    final result = await db.query(
      'audit_logs',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return result.map(AuditLogModel.fromMap).toList();
  }

  /// Retorna el conteo total de logs según los filtros dados.
  /// Útil para calcular el número de páginas en la UI.
  Future<int> getAuditLogCount({
    int? userId,
    String? action,
    String? startDate,
    String? endDate,
  }) async {
    final db = await instance.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (userId != null) {
      conditions.add('user_id = ?');
      args.add(userId);
    }
    if (action != null && action.isNotEmpty) {
      conditions.add('action = ?');
      args.add(action);
    }
    if (startDate != null) {
      conditions.add("created_at >= ?");
      args.add('$startDate 00:00:00');
    }
    if (endDate != null) {
      conditions.add("created_at <= ?");
      args.add('$endDate 23:59:59');
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final countQuery = 'SELECT COUNT(*) as count FROM audit_logs'
        '${where != null ? ' WHERE $where' : ''}';

    final result = await db.rawQuery(countQuery, args.isEmpty ? null : args);
    return result.first['count'] as int? ?? 0;
  }

  /// Retorna estadísticas resumidas de auditoría para el dashboard.
  ///
  /// Devuelve un mapa con: totalLogs, todayLogs, failedLogins,
  /// roleChanges, suspensions, deletions.
  Future<Map<String, int>> getAuditStats() async {
    final db = await instance.database;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}'
        '-${today.day.toString().padLeft(2, '0')}';

    final total =
        (await db.rawQuery('SELECT COUNT(*) as c FROM audit_logs')).first['c']
            as int? ??
            0;
    final todayCount = (await db.rawQuery(
      'SELECT COUNT(*) as c FROM audit_logs WHERE created_at >= ?',
      ['$todayStr 00:00:00'],
    ))
        .first['c'] as int? ?? 0;
    final failedLogins = (await db.rawQuery(
      "SELECT COUNT(*) as c FROM audit_logs WHERE action = 'login_failed'",
    ))
        .first['c'] as int? ?? 0;
    final roleChanges = (await db.rawQuery(
      "SELECT COUNT(*) as c FROM audit_logs WHERE action = 'role_change'",
    ))
        .first['c'] as int? ?? 0;
    final suspensions = (await db.rawQuery(
      "SELECT COUNT(*) as c FROM audit_logs WHERE action = 'user_suspend'",
    ))
        .first['c'] as int? ?? 0;
    final deletions = (await db.rawQuery(
      "SELECT COUNT(*) as c FROM audit_logs WHERE action = 'user_delete'",
    ))
        .first['c'] as int? ?? 0;

    return {
      'totalLogs': total,
      'todayLogs': todayCount,
      'failedLogins': failedLogins,
      'roleChanges': roleChanges,
      'suspensions': suspensions,
      'deletions': deletions,
    };
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DAILY LOGS - Registro diario por fecha
  // ──────────────────────────────────────────────────────────────────────────

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

    bool isEmptyString(String? s) => s == null || s.trim().isEmpty || s == 'null';
    bool isEmptyLog = !periodStart && !periodEnd && symptoms.isEmpty && sexo.isEmpty && flujo.isEmpty 
        && isEmptyString(bleedingIntensity) && isEmptyString(clots) && !spotting 
        && isEmptyString(spottingDays) && isEmptyString(sexualSymptoms) 
        && (painLevel == null || painLevel == 0) && isEmptyString(painCharacter) && isEmptyString(painDays) 
        && isEmptyString(treatment) && physicalSymptoms.isEmpty && emotionalSymptoms.isEmpty 
        && isEmptyString(breastExam) && isEmptyString(notes);

    if (isEmptyLog) {
      if (existing.isNotEmpty) {
        return await db.delete('daily_logs', where: 'user_id = ? AND date = ?', whereArgs: [userId, date]);
      }
      return 0;
    }

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

  /// Obtiene solo las fechas que tienen algún tipo de registro en un rango.
  Future<Set<String>> getLoggedDatesInRange(
    int userId,
    String startDate,
    String endDate,
  ) async {
    final db = await instance.database;

    final result = await db.query(
      'daily_logs',
      columns: ['date'],
      where: 'user_id = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, startDate, endDate],
    );

    return result.map((e) => e['date'] as String).toSet();
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

  /// Calcula el promedio real de días de sangrado basándose en los registros consecutivos.
  Future<double?> getRealBleedingAverage(int userId) async {
    final logs = await getAllDailyLogs(userId);
    if (logs.isEmpty) return null;

    List<int> bleedingDurations = [];
    int currentDuration = 0;

    for (final log in logs) {
      bool isBleeding = log['period_start'] == 1 || (log['bleeding_intensity'] != null && log['bleeding_intensity'] != 'none');
      if (isBleeding) {
        currentDuration++;
      } else {
        if (currentDuration > 0) {
          bleedingDurations.add(currentDuration);
          currentDuration = 0;
        }
      }
    }
    if (currentDuration > 0) {
      bleedingDurations.add(currentDuration);
    }

    if (bleedingDurations.isEmpty) return null;
    final sum = bleedingDurations.reduce((a, b) => a + b);
    return sum / bleedingDurations.length;
  }

  /// Centraliza la generación de estadísticas y el reporte médico.
  /// Retorna un mapa con todos los datos necesarios para generar el JSON.
  Future<Map<String, dynamic>> getMedicalReportSummary(int userId) async {
    final allLogs = await getAllDailyLogs(userId);
    final cycleStats = await getCycleStatistics(userId);
    final realBleedingAvg = await getRealBleedingAverage(userId);
    
    // Calcular flujo más frecuente en ciclo actual
    final lastPeriod = await getLastPeriodStart(userId);
    Map<String, int> flujoCount = {};
    if (lastPeriod != null && cycleStats['averageCycleLength'] != null) {
      final endOfCycle = lastPeriod.add(Duration(days: (cycleStats['averageCycleLength'] as num).toInt()));
      for (final log in allLogs) {
        try {
          final d = DateTime.parse(log['date'] as String);
          if (d.isAfter(lastPeriod.subtract(Duration(days: 1))) && d.isBefore(endOfCycle.add(Duration(days: 1)))) {
            for (final f in (jsonDecode(log['flujo'] as String? ?? '[]') as List)) {
              flujoCount[f.toString()] = (flujoCount[f.toString()] ?? 0) + 1;
            }
          }
        } catch (_) {}
      }
    }
    final flujoMasFrecuente = flujoCount.isNotEmpty
        ? flujoCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key
        : null;

    // Síntomas más frecuentes generales
    Map<String, int> sympCount = {};
    for (final log in allLogs) {
      for (final s in (jsonDecode(log['symptoms'] as String? ?? '[]') as List)) {
        sympCount[s.toString()] = (sympCount[s.toString()] ?? 0) + 1;
      }
    }
    final topSyms = (sympCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).map((e) => e.key).toList();

    return {
      'allLogs': allLogs,
      'cycleStats': cycleStats,
      'realBleedingAvg': realBleedingAvg,
      'lastPeriod': lastPeriod,
      'flujoMasFrecuente': flujoMasFrecuente,
      'topSyms': topSyms,
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

  // ── Pill times ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPillTimesRaw(int userId) async {
    final db = await instance.database;
    return await db.query('pill_times', where: 'user_id = ?', whereArgs: [userId], orderBy: 'hour ASC, minute ASC');
  }

  Future<void> setPillTimes(int userId, List<Map<String, dynamic>> times) async {
    final db = await instance.database;
    await db.delete('pill_times', where: 'user_id = ?', whereArgs: [userId]);
    for (final t in times) {
      await db.insert('pill_times', {'user_id': userId, 'hour': t['h'], 'minute': t['m']});
    }
  }

  // ── Weekly appointments ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWeeklyAppointmentsRaw(int userId) async {
    final db = await instance.database;
    return await db.query('weekly_appointments', where: 'user_id = ?', whereArgs: [userId], orderBy: 'weekday ASC, hour ASC');
  }

  Future<void> setWeeklyAppointments(int userId, List<Map<String, dynamic>> appts) async {
    final db = await instance.database;
    await db.delete('weekly_appointments', where: 'user_id = ?', whereArgs: [userId]);
    for (final a in appts) {
      await db.insert('weekly_appointments', {'user_id': userId, 'weekday': a['wd'], 'hour': a['h'], 'minute': a['m']});
    }
  }

  // These are used by NotificationService — return domain models via maps
  Future<List<Map<String, dynamic>>> getPillTimes(int userId) => getPillTimesRaw(userId);
  Future<List<Map<String, dynamic>>> getWeeklyAppointments(int userId) => getWeeklyAppointmentsRaw(userId);
}
