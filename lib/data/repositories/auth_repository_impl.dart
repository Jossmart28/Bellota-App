import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:bellotadevelopment/core/models/user_model.dart';
import 'package:bellotadevelopment/domain/repositories/auth_repository.dart';
import 'package:bellotadevelopment/data/datasources/database_provider.dart';
import 'package:bellotadevelopment/core/errors/app_logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseProvider _dbProvider;

  AuthRepositoryImpl(this._dbProvider);

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _hashPasswordSalted(String password, String salt) {
    final bytes = utf8.encode('$salt$password');
    return '$salt:${sha256.convert(bytes)}';
  }

  @override
  Future<int> registerUser(
    String name,
    String email,
    String password, {
    String role = 'usuario',
    String languagePref = 'es',
  }) async {
    if (email.trim().toLowerCase() == 'usm.unshowmas@gmail.com') {
      throw Exception('Este correo está reservado y no puede ser registrado.');
    }

    try {
      final db = await _dbProvider.database;
      final salt = _generateSalt();
      final hashed = _hashPasswordSalted(password, salt);
      
      final data = {
        'name': name,
        'email': email.trim().toLowerCase(),
        'password_hash': hashed,
        'role': role,
        'is_active': 1,
        'created_at': DateTime.now().toIso8601String(),
        'language_pref': languagePref,
      };
      
      final userId = await db.insert('users', data);

      // Crear perfil por defecto
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
    } catch (e, stack) {
      AppLogger.e('Error al registrar usuario: $email', e, stack);
      rethrow;
    }
  }

  @override
  Future<UserModel?> loginUser(String email, String password) async {
    try {
      final db = await _dbProvider.database;
      final result = await db.query(
        'users',
        where: 'email = ? AND is_active = 1',
        whereArgs: [email.trim().toLowerCase()],
      );
      
      if (result.isEmpty) return null;
      
      final stored = result.first['password_hash'] as String;
      bool valid;
      
      if (stored.contains(':')) {
        final parts = stored.split(':');
        final rehash = _hashPasswordSalted(password, parts[0]);
        valid = rehash == stored;
      } else {
        valid = stored == _hashPassword(password);
        if (valid) {
          // Migrar hash viejo a nuevo con sal
          final salt = _generateSalt();
          final newHash = _hashPasswordSalted(password, salt);
          await db.update('users', {'password_hash': newHash},
            where: 'id = ?', whereArgs: [result.first['id']]);
        }
      }
      
      return valid ? UserModel.fromMap(result.first) : null;
    } catch (e, stack) {
      AppLogger.e('Error en loginUser', e, stack);
      return null;
    }
  }

  @override
  Future<bool> emailExists(String email) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    return result.isNotEmpty;
  }

  @override
  Future<int?> getUserIdByEmail(String email) async {
    final db = await _dbProvider.database;
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

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  @override
  Future<bool> hasAdminUser() async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'users',
      columns: ['id'],
      where: 'role = ?',
      whereArgs: ['admin'],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
