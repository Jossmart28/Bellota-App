import 'package:bellotadevelopment/core/models/user_model.dart';

abstract class UserRepository {
  Future<List<UserModel>> getAllUsers({int? limit, int offset = 0});
  Future<int> getUserCount();
  Future<int> updateUserRole(int userId, String newRole);
  Future<int> updateUserLanguage(int userId, String languagePref);
  Future<int> suspendUser(int userId);
  Future<int> reactivateUser(int userId);
  Future<int> deleteUser(int userId);
}
