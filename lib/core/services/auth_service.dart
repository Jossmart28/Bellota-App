import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_keys.dart';
import '../models/user_model.dart';
import '../services/user_role.dart';
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
  /// Retorna un [UserModel] con el rol incluido si las credenciales son
  /// correctas y la cuenta está activa, `null` en caso contrario.
  Future<UserModel?> login(String email, String password) async {
    final map = await DatabaseHelper.instance.loginUser(
      email.trim().toLowerCase(),
      password,
    );
    if (map == null) return null;
    
    UserModel user = UserModel.fromMap(map);
    
    return user;
  }

  // ── Registro ───────────────────────────────────────────────────────────────

  /// Verifica si un correo ya está en uso.
  Future<bool> emailExists(String email) =>
      DatabaseHelper.instance.emailExists(email.trim().toLowerCase());

  /// Registra un nuevo usuario y retorna su [UserModel].
  ///
  /// El [role] por defecto es [UserRole.usuario]. Solo un administrador
  /// debería pasar un rol diferente al crear cuentas privilegiadas.
  ///
  /// Lanza una excepción si ocurre un error en la base de datos.
  Future<UserModel> register(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.usuario,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final userId = await DatabaseHelper.instance.registerUser(
      name.trim(),
      normalizedEmail,
      password,
      role: role.name,
    );

    // Construimos el modelo con los datos recién insertados.
    return UserModel(
      id: userId,
      name: name.trim(),
      email: normalizedEmail,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  // ── Sesión ─────────────────────────────────────────────────────────────────

  /// Guarda los datos de sesión del [user] en SharedPreferences,
  /// incluyendo su rol y estado de cuenta.
  Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppKeys.isLoggedIn, true);
    await prefs.setString(AppKeys.userName, user.name);
    await prefs.setString(AppKeys.userEmail, user.email);
    await prefs.setInt(AppKeys.userId, user.id);
    await prefs.setString(AppKeys.userRole, user.role.name);
    await prefs.setBool(AppKeys.isActive, user.isActive);
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
    await prefs.remove(AppKeys.userRole);
    await prefs.remove(AppKeys.isActive);
  }

  /// Retorna `true` si existe una sesión activa en SharedPreferences.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppKeys.isLoggedIn) ?? false;
  }

  /// Recupera el [UserModel] completo (incluyendo rol) almacenado en la
  /// sesión activa.
  ///
  /// Retorna `null` si no hay sesión guardada.
  Future<UserModel?> currentSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(AppKeys.userId);
    final name = prefs.getString(AppKeys.userName);
    final email = prefs.getString(AppKeys.userEmail);
    final roleStr = prefs.getString(AppKeys.userRole);
    final isActive = prefs.getBool(AppKeys.isActive) ?? true;

    if (id == null || name == null || email == null) return null;

    // Parsear rol desde string almacenado
    UserRole role = UserRole.usuario;
    switch (roleStr) {
      case 'admin':
        role = UserRole.admin;
        break;
      case 'auditor':
        role = UserRole.auditor;
        break;
    }

    return UserModel(
      id: id,
      name: name,
      email: email,
      role: role,
      isActive: isActive,
      createdAt: DateTime.now(), // fecha real no requerida en sesión
    );
  }

  // ── Auditoría ──────────────────────────────────────────────────────────────

  /// Registra una acción en el log de auditoría para el usuario de sesión actual.
  ///
  /// Se llama internamente en operaciones críticas (login, logout, cambios de rol, etc.).
  ///
  /// Parámetros:
  /// - [action]: Identificador de la acción (ej: 'login', 'profile_update').
  /// - [targetType]: Tipo del recurso afectado ('user', 'daily_log', etc.).
  /// - [targetId]: ID del recurso afectado.
  /// - [details]: Contexto adicional (antes/después, valores cambiados).
  Future<void> logAction({
    required String action,
    String? targetType,
    int? targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final user = await currentSessionUser();
      await DatabaseHelper.instance.insertAuditLog(
        userId: user?.id,
        action: action,
        targetType: targetType,
        targetId: targetId,
        details: details,
      );
    } catch (_) {
      // No interrumpir el flujo normal si el log falla
    }
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
          role: 'usuario',
        );
        return UserModel(
          id: userId,
          name: name,
          email: email,
          role: UserRole.usuario,
          isActive: true,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      return null;
    }
  }
}
