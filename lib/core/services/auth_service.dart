import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_keys.dart';
import '../models/user_model.dart';
import '../../database/database_helper.dart';

/// Servicio de autenticación de Bellota.
///
/// Centraliza la lógica de login, registro y manejo de sesión,
/// que anteriormente estaba distribuida entre [LoginScreen] y [RegisterScreen].
///
/// Uso típico:
/// ```dart
/// final result = await AuthService.instance.login(email, password);
/// if (result != null) AuthService.instance.saveSession(result);
/// ```
class AuthService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  AuthService._();
  static final AuthService instance = AuthService._();

  // ── Login ──────────────────────────────────────────────────────────────────

  /// Valida las credenciales del usuario contra la base de datos local.
  ///
  /// Retorna un [UserModel] si las credenciales son correctas, `null` si no lo son.
  Future<UserModel?> login(String email, String password) async {
    final map = await DatabaseHelper.instance.loginUser(
      email.trim().toLowerCase(),
      password,
    );
    if (map == null) return null;
    return UserModel.fromMap(map);
  }

  // ── Registro ───────────────────────────────────────────────────────────────

  /// Verifica si un correo ya está en uso.
  Future<bool> emailExists(String email) =>
      DatabaseHelper.instance.emailExists(email.trim().toLowerCase());

  /// Registra un nuevo usuario y retorna su [UserModel].
  ///
  /// Lanza una excepción si ocurre un error en la base de datos.
  Future<UserModel> register(String name, String email, String password) async {
    final userId = await DatabaseHelper.instance.registerUser(
      name.trim(),
      email.trim().toLowerCase(),
      password,
    );

    // Construimos el modelo con los datos recién insertados.
    return UserModel(
      id: userId,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );
  }

  // ── Sesión ─────────────────────────────────────────────────────────────────

  /// Guarda los datos de sesión del [user] en SharedPreferences.
  Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppKeys.isLoggedIn, true);
    await prefs.setString(AppKeys.userName, user.name);
    await prefs.setString(AppKeys.userEmail, user.email);
    await prefs.setInt(AppKeys.userId, user.id);
  }

  /// Elimina todos los datos de sesión de SharedPreferences.
  ///
  /// Llamar al cerrar sesión para dejar el dispositivo limpio.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppKeys.isLoggedIn);
    await prefs.remove(AppKeys.userName);
    await prefs.remove(AppKeys.userEmail);
    await prefs.remove(AppKeys.userId);
  }

  /// Retorna `true` si existe una sesión activa en SharedPreferences.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppKeys.isLoggedIn) ?? false;
  }

  /// Recupera el [UserModel] básico almacenado en la sesión activa.
  ///
  /// Retorna `null` si no hay sesión guardada.
  Future<UserModel?> currentSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(AppKeys.userId);
    final name = prefs.getString(AppKeys.userName);
    final email = prefs.getString(AppKeys.userEmail);

    if (id == null || name == null || email == null) return null;

    return UserModel(
      id: id,
      name: name,
      email: email,
      createdAt: DateTime.now(), // fecha real no requerida en sesión
    );
  }

  // ── Google OAuth ───────────────────────────────────────────────────────────

  /// Inicia sesión o registra un usuario usando Google OAuth.
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final String email = googleUser.email.trim().toLowerCase();
      final String name = googleUser.displayName ?? 'Usuario Google';

      final userMap = await DatabaseHelper.instance.getUserByEmail(email);
      if (userMap != null) {
        return UserModel.fromMap(userMap);
      } else {
        final userId = await DatabaseHelper.instance.registerUser(
          name,
          email,
          'google_oauth_no_password_required',
        );
        return UserModel(
          id: userId,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      return null;
    }
  }
}
