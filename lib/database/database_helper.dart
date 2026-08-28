import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
      version: 1,
      onCreate: _createDB,
      onOpen: _onOpen,
    );
  }

  Future _onOpen(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await _createProfilesTable(db);
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
  }

  Future _createProfilesTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS profiles (
      user_id INTEGER PRIMARY KEY,
      username TEXT,
      gmail TEXT,
      cycle_duration INTEGER DEFAULT 28,
      period_duration INTEGER DEFAULT 7,
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
      'period_duration': 7,
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
        'period_duration': 7,
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

  /// Guarda o actualiza el registro diario para una fecha específica
  Future<int> saveDailyLog({
    required int userId,
    required String date,
    required bool periodStart,
    required List<String> symptoms,
    required List<String> sexo,
    required List<String> flujo,
  }) async {
    final db = await instance.database;
    await _createDailyLogsTable(db);

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

  /// Obtiene el registro diario para una fecha específica
  Future<Map<String, dynamic>?> getDailyLog(int userId, String date) async {
    final db = await instance.database;
    await _createDailyLogsTable(db);

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
    await _createDailyLogsTable(db);

    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );
    return result.isNotEmpty;
  }

  /// Obtiene la última fecha en que se registró el inicio de un período
  Future<DateTime?> getLastPeriodStart(int userId) async {
    final db = await instance.database;
    await _createDailyLogsTable(db);

    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND period_start = 1',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final dateString = result.first['date'] as String;
      // Date format is expected to be YYYY-MM-DD
      try {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (e) {
        // ignore
      }
    }
    return null;
  }

  /// Obtiene la primera fecha en que se registró el inicio de un período
  Future<DateTime?> getFirstPeriodStart(int userId) async {
    final db = await instance.database;
    await _createDailyLogsTable(db);

    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND period_start = 1',
      whereArgs: [userId],
      orderBy: 'date ASC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final dateString = result.first['date'] as String;
      try {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (e) {
        // ignore
      }
    }
    return null;
  }

  /// Obtiene todos los registros diarios de un usuario ordenados por fecha
  Future<List<Map<String, dynamic>>> getAllDailyLogs(int userId) async {
    final db = await instance.database;
    await _createDailyLogsTable(db);

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
    await _createDailyLogsTable(db);

    final result = await db.query(
      'daily_logs',
      where: 'user_id = ? AND period_start = 1',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    List<DateTime> dates = [];
    for (final row in result) {
      final dateString = row['date'] as String;
      try {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          dates.add(DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])));
        }
      } catch (e) {
        // ignore
      }
    }
    return dates;
  }

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

