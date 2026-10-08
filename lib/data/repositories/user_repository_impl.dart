import 'package:bellotadevelopment/core/models/user_model.dart';
import 'package:bellotadevelopment/domain/repositories/user_repository.dart';
import 'package:bellotadevelopment/data/datasources/database_provider.dart';

class UserRepositoryImpl implements UserRepository {
  final DatabaseProvider _dbProvider;

  UserRepositoryImpl(this._dbProvider);

  @override
  Future<List<UserModel>> getAllUsers({int? limit, int offset = 0}) async {
    final db = await _dbProvider.database;
    final results = await db.query(
      'users',
      columns: ['id', 'name', 'email', 'role', 'is_active', 'created_at', 'language_pref'],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((e) => UserModel.fromMap(e)).toList();
  }

  @override
  Future<int> getUserCount() async {
    final db = await _dbProvider.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return result.first['count'] as int? ?? 0;
  }

  @override
  Future<int> updateUserRole(int userId, String newRole) async {
    final db = await _dbProvider.database;
    return await db.update('users', {'role': newRole}, where: 'id = ?', whereArgs: [userId]);
  }

  @override
  Future<int> updateUserLanguage(int userId, String languagePref) async {
    final db = await _dbProvider.database;
    return await db.update('users', {'language_pref': languagePref}, where: 'id = ?', whereArgs: [userId]);
  }

  @override
  Future<int> suspendUser(int userId) async {
    final db = await _dbProvider.database;
    return await db.update('users', {'is_active': 0}, where: 'id = ?', whereArgs: [userId]);
  }

  @override
  Future<int> reactivateUser(int userId) async {
    final db = await _dbProvider.database;
    return await db.update('users', {'is_active': 1}, where: 'id = ?', whereArgs: [userId]);
  }

  @override
  Future<int> deleteUser(int userId) async {
    final db = await _dbProvider.database;
    return await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }
}
