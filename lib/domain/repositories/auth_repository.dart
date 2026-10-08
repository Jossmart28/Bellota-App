import 'package:bellotadevelopment/core/models/user_model.dart';

/// Interfaz abstracta para la autenticación y gestión de cuentas
abstract class AuthRepository {
  Future<int> registerUser(
    String name,
    String email,
    String password, {
    String role = 'usuario',
    String languagePref = 'es',
  });

  Future<UserModel?> loginUser(String email, String password);

  Future<bool> emailExists(String email);

  Future<int?> getUserIdByEmail(String email);

  Future<UserModel?> getUserByEmail(String email);

  Future<bool> hasAdminUser();
}
