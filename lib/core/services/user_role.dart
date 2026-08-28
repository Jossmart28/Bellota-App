/// Sistema de roles y permisos de la aplicación Bellota.
///
/// Define los 3 roles disponibles y su conjunto de permisos asociados.
/// Usar [RolePermissions.can] para verificar acceso antes de ejecutar acciones.
library;

// ── Roles ──────────────────────────────────────────────────────────────────

/// Roles disponibles en la aplicación.
///
/// - [admin]: Acceso total. Puede gestionar usuarios y todos los datos.
/// - [usuario]: Acceso a sus propios datos. Rol por defecto al registrarse.
/// - [auditor]: Acceso de lectura a todos los datos. Solo puede exportar reportes.
enum UserRole {
  /// Administrador del sistema. Acceso completo a todas las funcionalidades.
  admin,

  /// Usuario estándar. Accede y edita únicamente sus propios datos.
  usuario,

  /// Auditor de datos. Puede ver y exportar datos, sin capacidad de edición.
  auditor,
}

// ── Permisos ───────────────────────────────────────────────────────────────

/// Identificadores de permisos disponibles en la app.
abstract final class AppPermissions {
  AppPermissions._();

  // Lectura
  static const String viewOwn = 'view_own';
  static const String viewAll = 'view_all';

  // Escritura
  static const String editOwn = 'edit_own';
  static const String editAll = 'edit_all';

  // Eliminación
  static const String deleteOwn = 'delete_own';
  static const String deleteAny = 'delete_any';

  // Funcionalidades específicas
  static const String logSymptoms = 'log_symptoms';
  static const String exportReports = 'export_reports';
  static const String manageUsers = 'manage_users';
}

// ── Motor de permisos ──────────────────────────────────────────────────────

/// Verifica si un rol tiene un permiso específico.
///
/// Ejemplo de uso:
/// ```dart
/// if (RolePermissions.can(UserRole.auditor, AppPermissions.exportReports)) {
///   _exportToPdf();
/// }
/// ```
abstract final class RolePermissions {
  RolePermissions._();

  /// Mapa de rol → conjunto de permisos concedidos.
  static const Map<UserRole, Set<String>> _permissions = {
    UserRole.admin: {
      AppPermissions.viewOwn,
      AppPermissions.viewAll,
      AppPermissions.editOwn,
      AppPermissions.editAll,
      AppPermissions.deleteOwn,
      AppPermissions.deleteAny,
      AppPermissions.logSymptoms,
      AppPermissions.exportReports,
      AppPermissions.manageUsers,
    },
    UserRole.usuario: {
      AppPermissions.viewOwn,
      AppPermissions.editOwn,
      AppPermissions.deleteOwn,
      AppPermissions.logSymptoms,
    },
    UserRole.auditor: {
      AppPermissions.viewOwn,
      AppPermissions.viewAll,
      AppPermissions.exportReports,
    },
  };

  /// Retorna `true` si el [role] tiene el [permission] especificado.
  static bool can(UserRole role, String permission) =>
      _permissions[role]?.contains(permission) ?? false;

  /// Retorna todos los permisos del [role] especificado.
  static Set<String> permissionsOf(UserRole role) =>
      Set.unmodifiable(_permissions[role] ?? {});
}
