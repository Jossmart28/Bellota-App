import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
    );
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
    return await db.insert('users', data);
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
}
