import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_keys.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../../database/database_helper.dart';

/// Servicio de autenticaciÃ³n de Bellota.
///
/// Centraliza la lÃ³gica de login, registro y manejo de sesiÃ³n,
/// que anteriormente estaba distribuida entre [LoginScreen] y [RegisterScreen].
///
/// Uso tÃ­pico:
/// ```dart
/// final result = await AuthService.instance.login(email, password);
/// if (result != null) AuthService.instance.saveSession(result);
/// ```
class AuthService {
  // â”€â”€ Singleton â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  AuthService._();
  static final AuthService instance = AuthService._();

  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _sharedPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // â”€â”€ Login â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Valida las credenciales del usuario contra la base de datos local.
  ///
  /// Retorna un [UserModel] con el rol incluido si las credenciales son
  /// correctas y la cuenta estÃ¡ activa, `null` en caso contrario.
  Future<UserModel?> login(String email, String password) async {
    final map = await DatabaseHelper.instance.loginUser(
      email.trim().toLowerCase(),
      password,
    );
    if (map == null) return null;
    
    UserModel user = UserModel.fromMap(map);
    
    return user;
  }

  // â”€â”€ Registro â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Verifica si un correo ya estÃ¡ en uso.
  Future<bool> emailExists(String email) =>
      DatabaseHelper.instance.emailExists(email.trim().toLowerCase());

  /// Registra un nuevo usuario y retorna su [UserModel].
  ///
  /// El [role] por defecto es [UserRole.usuario]. Solo un administrador
  /// deberÃ­a pasar un rol diferente al crear cuentas privilegiadas.
  ///
  /// Lanza una excepciÃ³n si ocurre un error en la base de datos.
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

    // Construimos el modelo con los datos reciÃ©n insertados.
    return UserModel(
      id: userId,
      name: name.trim(),
      email: normalizedEmail,
      role: role,
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  // â”€â”€ SesiÃ³n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Guarda los datos de sesiÃ³n del [user] en SharedPreferences,
  /// incluyendo su rol y estado de cuenta.
  Future<void> saveSession(UserModel user) async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(AppKeys.isLoggedIn, true);
    await prefs.setString(AppKeys.userName, user.name);
    await prefs.setString(AppKeys.userEmail, user.email);
    await prefs.setInt(AppKeys.userId, user.id);
    await prefs.setString(AppKeys.userRole, user.role.name);
    await prefs.setBool(AppKeys.isActive, user.isActive);
    await prefs.setString('userCreatedAt', user.createdAt.toIso8601String());
  }

  /// Elimina todos los datos de sesiÃ³n de SharedPreferences.
  ///
  /// Llamar al cerrar sesiÃ³n para dejar el dispositivo limpio.
  Future<void> clearSession() async {
    final prefs = await _sharedPrefs;
    await prefs.remove(AppKeys.isLoggedIn);
    await prefs.remove(AppKeys.userName);
    await prefs.remove(AppKeys.userEmail);
    await prefs.remove(AppKeys.userId);
    await prefs.remove(AppKeys.userRole);
    await prefs.remove(AppKeys.isActive);
    await prefs.remove('userCreatedAt');
  }

  /// Retorna `true` si existe una sesiÃ³n activa en SharedPreferences.
  Future<bool> isLoggedIn() async {
    final prefs = await _sharedPrefs;
    return prefs.getBool(AppKeys.isLoggedIn) ?? false;
  }

  /// Recupera el [UserModel] completo (incluyendo rol) almacenado en la
  /// sesiÃ³n activa.
  ///
  /// Retorna `null` si no hay sesiÃ³n guardada.
  Future<UserModel?> currentSessionUser() async {
    final prefs = await _sharedPrefs;
    final id = prefs.getInt(AppKeys.userId);
    final name = prefs.getString(AppKeys.userName);
    final email = prefs.getString(AppKeys.userEmail);
    final roleStr = prefs.getString(AppKeys.userRole);
    final isActive = prefs.getBool(AppKeys.isActive) ?? true;
    final createdAtStr = prefs.getString('userCreatedAt');

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
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
    );
  }

  // â”€â”€ AuditorÃ­a â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Registra una acciÃ³n en el log de auditorÃ­a para el usuario de sesiÃ³n actual.
  ///
  /// Se llama internamente en operaciones crÃ­ticas (login, logout, cambios de rol, etc.).
  ///
  /// ParÃ¡metros:
  /// - [action]: Identificador de la acciÃ³n (ej: 'login', 'profile_update').
  /// - [targetType]: Tipo del recurso afectado ('user', 'daily_log', etc.).
  /// - [targetId]: ID del recurso afectado.
  /// - [details]: Contexto adicional (antes/despuÃ©s, valores cambiados).
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

  // â”€â”€ Google OAuth â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Inicia sesiÃ³n o registra un usuario usando Google OAuth.
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
      debugPrint('Error en signInWithGoogle: $e');
      return null;
    }
  }
}

