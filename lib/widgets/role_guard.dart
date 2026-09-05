import 'package:flutter/material.dart';
import '../core/models/user_model.dart';
import '../core/models/user_role.dart';

/// Widget guardia que controla el acceso a partes de la UI segÃºn el rol
/// y los permisos del usuario autenticado.
///
/// Uso bÃ¡sico (bloqueo por permiso especÃ­fico):
/// ```dart
/// RoleGuard(
///   user: currentUser,
///   requiredPermission: AppPermissions.manageUsers,
///   child: AdminButton(),
/// )
/// ```
///
/// Uso con rol mÃ­nimo requerido:
/// ```dart
/// RoleGuard(
///   user: currentUser,
///   allowedRoles: [UserRole.admin, UserRole.auditor],
///   child: AuditSection(),
///   fallback: Text('Acceso denegado'),
/// )
/// ```
class RoleGuard extends StatelessWidget {
  /// Usuario actualmente autenticado.
  final UserModel? user;

  /// Roles que tienen acceso. Si es `null`, se usa [requiredPermission].
  final List<UserRole>? allowedRoles;

  /// Permiso especÃ­fico requerido. Si es `null`, se usa [allowedRoles].
  final String? requiredPermission;

  /// Widget a mostrar cuando el acceso estÃ¡ permitido.
  final Widget child;

  /// Widget a mostrar cuando el acceso estÃ¡ denegado.
  /// Por defecto es `SizedBox.shrink()` (invisible).
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.user,
    this.allowedRoles,
    this.requiredPermission,
    required this.child,
    this.fallback,
  }) : assert(
          allowedRoles != null || requiredPermission != null,
          'Debes especificar allowedRoles o requiredPermission',
        );

  /// Verifica el acceso imperativamente (sin renderizar nada).
  ///
  /// ```dart
  /// if (RoleGuard.check(user, permission: AppPermissions.manageUsers)) {
  ///   _doAdminAction();
  /// }
  /// ```
  static bool check(
    UserModel? user, {
    List<UserRole>? roles,
    String? permission,
  }) {
    if (user == null || !user.isActive) return false;
    if (roles != null && roles.contains(user.role)) return true;
    if (permission != null && RolePermissions.can(user.role, permission)) {
      return true;
    }
    return false;
  }

  bool _hasAccess() {
    if (user == null || !user!.isActive) return false;

    if (allowedRoles != null && allowedRoles!.contains(user!.role)) {
      return true;
    }

    if (requiredPermission != null &&
        RolePermissions.can(user!.role, requiredPermission!)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _hasAccess() ? child : (fallback ?? const SizedBox.shrink());
  }
}

/// Decorador que muestra un banner de "Acceso denegado" cuando el rol
/// no tiene acceso, en lugar de ocultarlo.
class RoleGuardBanner extends StatelessWidget {
  final UserModel? user;
  final List<UserRole>? allowedRoles;
  final String? requiredPermission;
  final Widget child;
  final String? deniedMessage;

  const RoleGuardBanner({
    super.key,
    required this.user,
    this.allowedRoles,
    this.requiredPermission,
    required this.child,
    this.deniedMessage,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccess = RoleGuard.check(
      user,
      roles: allowedRoles,
      permission: requiredPermission,
    );

    if (hasAccess) return child;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              deniedMessage ?? 'No tienes permisos para acceder a esta secciÃ³n.',
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

