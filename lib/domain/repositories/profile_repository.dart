import 'package:bellotadevelopment/core/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel?> getProfile(int userId);
  Future<int> updateProfileField(int userId, String field, dynamic value);
}
