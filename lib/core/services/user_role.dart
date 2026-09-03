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

  // ── Lectura ────────────────────────────────────────────────────────────────
  /// Ver los datos propios del usuario.
  static const String viewOwn = 'view_own';

  /// Ver los datos de todos los usuarios.
  static const String viewAll = 'view_all';

  // ── Escritura ──────────────────────────────────────────────────────────────
  /// Editar los datos propios del usuario.
  static const String editOwn = 'edit_own';

  /// Editar los datos de cualquier usuario.
  static const String editAll = 'edit_all';

  // ── Eliminación ────────────────────────────────────────────────────────────
  /// Eliminar los datos propios del usuario.
  static const String deleteOwn = 'delete_own';

  /// Eliminar los datos de cualquier usuario.
  static const String deleteAny = 'delete_any';

  // ── Funcionalidades del usuario ────────────────────────────────────────────
  /// Registrar síntomas y datos diarios.
  static const String logSymptoms = 'log_symptoms';

  /// Exportar reportes personales (PDF médico).
  static const String exportReports = 'export_reports';

  // ── Administración ─────────────────────────────────────────────────────────
  /// Crear, editar, suspender o eliminar cuentas de usuario.
  static const String manageUsers = 'manage_users';

  /// Modificar configuraciones globales del sistema.
  static const String configureSystem = 'configure_system';

  /// Moderar contenido de cualquier usuario (editar/eliminar por violaciones).
  static const String moderateContent = 'moderate_content';

  /// Gestionar respaldos y mantenimiento de la base de datos.
  static const String manageBackups = 'manage_backups';

  /// Asignar o cambiar roles de otros usuarios.
  static const String assignRoles = 'assign_roles';

  /// Suspender o reactivar cuentas de usuario.
  static const String suspendUsers = 'suspend_users';

  // ── Auditoría ──────────────────────────────────────────────────────────────
  /// Consultar el historial de acciones (logs de auditoría).
  static const String viewAuditLogs = 'view_audit_logs';

  /// Generar reportes de cumplimiento y seguridad.
  static const String generateComplianceReports =
      'generate_compliance_reports';

  /// Detectar anomalías en el flujo de trabajo y accesos.
  static const String detectAnomalies = 'detect_anomalies';
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
    // ── Admin: acceso total ────────────────────────────────────────────────
    UserRole.admin: {
      // Lectura
      AppPermissions.viewOwn,
      AppPermissions.viewAll,
      // Escritura
      AppPermissions.editOwn,
      AppPermissions.editAll,
      // Eliminación
      AppPermissions.deleteOwn,
      AppPermissions.deleteAny,
      // Funcionalidades
      AppPermissions.logSymptoms,
      AppPermissions.exportReports,
      // Administración
      AppPermissions.manageUsers,
      AppPermissions.configureSystem,
      AppPermissions.moderateContent,
      AppPermissions.manageBackups,
      AppPermissions.assignRoles,
      AppPermissions.suspendUsers,
      // Auditoría (admin también puede ver logs)
      AppPermissions.viewAuditLogs,
      AppPermissions.generateComplianceReports,
      AppPermissions.detectAnomalies,
    },

    // ── Usuario: solo datos propios ────────────────────────────────────────
    UserRole.usuario: {
      AppPermissions.viewOwn,
      AppPermissions.editOwn,
      AppPermissions.deleteOwn,
      AppPermissions.logSymptoms,
      AppPermissions.exportReports,
    },

    // ── Auditor: lectura global + reportes, sin edición ────────────────────
    UserRole.auditor: {
      AppPermissions.viewOwn,
      AppPermissions.viewAll,
      AppPermissions.exportReports,
      AppPermissions.viewAuditLogs,
      AppPermissions.generateComplianceReports,
      AppPermissions.detectAnomalies,
    },
  };

  /// Retorna `true` si el [role] tiene el [permission] especificado.
  static bool can(UserRole role, String permission) =>
      _permissions[role]?.contains(permission) ?? false;

  /// Retorna `true` si el [role] tiene **al menos uno** de los [permissions].
  static bool canAny(UserRole role, List<String> permissions) =>
      permissions.any((p) => can(role, p));

  /// Retorna `true` si el [role] tiene **todos** los [permissions].
  static bool canAll(UserRole role, List<String> permissions) =>
      permissions.every((p) => can(role, p));

  /// Retorna todos los permisos del [role] especificado.
  static Set<String> permissionsOf(UserRole role) =>
      Set.unmodifiable(_permissions[role] ?? {});

  /// Mapa legible de permiso → descripción en español.
  static const Map<String, String> _descriptions = {
    AppPermissions.viewOwn: 'Ver datos propios',
    AppPermissions.viewAll: 'Ver datos de todos los usuarios',
    AppPermissions.editOwn: 'Editar datos propios',
    AppPermissions.editAll: 'Editar datos de cualquier usuario',
    AppPermissions.deleteOwn: 'Eliminar datos propios',
    AppPermissions.deleteAny: 'Eliminar datos de cualquier usuario',
    AppPermissions.logSymptoms: 'Registrar síntomas diarios',
    AppPermissions.exportReports: 'Exportar reportes',
    AppPermissions.manageUsers: 'Gestionar usuarios',
    AppPermissions.configureSystem: 'Configurar el sistema',
    AppPermissions.moderateContent: 'Moderar contenido',
    AppPermissions.manageBackups: 'Gestionar respaldos',
    AppPermissions.assignRoles: 'Asignar roles',
    AppPermissions.suspendUsers: 'Suspender usuarios',
    AppPermissions.viewAuditLogs: 'Ver logs de auditoría',
    AppPermissions.generateComplianceReports: 'Generar reportes de cumplimiento',
    AppPermissions.detectAnomalies: 'Detectar anomalías',
  };

  /// Retorna una lista de descripciones legibles para los permisos del [role].
  static List<String> describe(UserRole role) {
    final perms = permissionsOf(role);
    return perms
        .map((p) => _descriptions[p] ?? p)
        .toList()
      ..sort();
  }

  /// Nombre legible del rol en español.
  static String roleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.usuario:
        return 'Usuario';
      case UserRole.auditor:
        return 'Auditor';
    }
  }

  /// Descripción breve del rol.
  static String roleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Acceso completo al sistema, gestión de usuarios y configuración.';
      case UserRole.usuario:
        return 'Acceso a datos propios y funcionalidades básicas de la app.';
      case UserRole.auditor:
        return 'Lectura global de datos, logs de auditoría y reportes de cumplimiento.';
    }
  }
}
