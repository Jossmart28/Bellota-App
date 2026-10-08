import 'package:bellotadevelopment/core/models/profile_model.dart';
import 'package:bellotadevelopment/domain/repositories/profile_repository.dart';
import 'package:bellotadevelopment/data/datasources/database_provider.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final DatabaseProvider _dbProvider;

  ProfileRepositoryImpl(this._dbProvider);

  @override
  Future<ProfileModel?> getProfile(int userId) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return ProfileModel.fromMap(result.first);
    }

    // Fallback: Si no existe, crearlo con datos base de 'users'
    final userResult = await db.query('users', where: 'id = ?', whereArgs: [userId]);
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
      return ProfileModel.fromMap(defaultProfile);
    }
    return null;
  }

  @override
  Future<int> updateProfileField(int userId, String field, dynamic value) async {
    final db = await _dbProvider.database;
    // Asegurar que el perfil existe
    await getProfile(userId);

    return await db.update(
      'profiles',
      {field: value},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
