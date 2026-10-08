import 'dart:io';

void main() async {
  // Restore admin_panel from git and fix imports comprehensively
  final result = await Process.run('git', ['show', 'HEAD:lib/screens/admin_panel_screen.dart']);
  if (result.exitCode != 0) { print('git show failed'); return; }
  
  String c = result.stdout as String;
  
  // Replace the import block with working ones
  final badImports = [
    "import '../core/models/user_model.dart';",
    "import '../core/services/auth_service.dart';",
    "import '../navigation/navigation_service.dart';",
    "import '../widgets/role_guard.dart';",
    "import '../core/models/user_role.dart';",
    "import '../database/database_helper.dart';",
    "import '../theme/bellota_colors.dart';",
    "import 'login_screen.dart';",
    "import 'audit_dashboard_screen.dart';",
  ];
  final goodImports = """import 'package:flutter/material.dart';
import 'package:bellotadevelopment/core/models/user_model.dart';
import 'package:bellotadevelopment/core/di/injection_container.dart';
import 'package:bellotadevelopment/domain/repositories/user_repository.dart';
import 'package:bellotadevelopment/domain/repositories/auth_repository.dart';
import 'package:bellotadevelopment/navigation/navigation_service.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/presentation/screens/auth/login_screen.dart';
import 'package:bellotadevelopment/presentation/screens/admin/audit_dashboard_screen.dart';
""";

  // Remove old imports
  for (final imp in badImports) {
    c = c.replaceAll(imp + '\n', '');
    c = c.replaceAll(imp, '');
  }
  c = c.replaceAll("import 'package:flutter/material.dart';\n", '');
  
  // Prepend good imports
  c = goodImports + c;
  
  // Fix all old references
  c = c.replaceAll('DatabaseHelper.instance.getAllUsers()', 'sl<UserRepository>().getAllUsers()');
  c = c.replaceAll('DatabaseHelper.instance.updateUserRole(userId, selected)', 'sl<UserRepository>().updateUserRole(userId, selected)');
  c = c.replaceAll('DatabaseHelper.instance.suspendUser(userId)', 'sl<UserRepository>().suspendUser(userId)');
  c = c.replaceAll('DatabaseHelper.instance.reactivateUser(userId)', 'sl<UserRepository>().reactivateUser(userId)');
  c = c.replaceAll('DatabaseHelper.instance.deleteUser(userId)', 'sl<UserRepository>().deleteUser(userId)');
  c = c.replaceAll('AuthService.instance.currentSessionUser()', 'sl<AuthRepository>().getCurrentUser()');
  c = c.replaceAll('AuthService.instance.logAction(', '//AuthService.instance.logAction(');
  c = c.replaceAll('AuthService.instance.clearSession()', 'sl<AuthRepository>().logout()');
  c = c.replaceAll('RolePermissions.roleName(UserRole.admin)', '"Administrador"');
  c = c.replaceAll('RolePermissions.roleName(\n            UserRole.values.firstWhere((e) => e.name == selected),\n          )', 'selected');
  c = c.replaceAll('RolePermissions.roleName(', '//RolePermissions.roleName(');
  c = c.replaceAll('UserRole.values.firstWhere((e) => e.name == r)', 'r');
  c = c.replaceAll('UserRole.values.firstWhere((e) => e.name == selected)', 'selected');
  c = c.replaceAll('UserRole.admin', '"admin"');
  c = c.replaceAll('RoleGuard.check(_currentUser, roles: ["admin"])', '_currentUser?.role == "admin"');
  c = c.replaceAll('RoleGuard.check(', '//_currentUser?.role == ');

  File('lib/presentation/screens/admin/admin_panel_screen.dart').writeAsStringSync(c);
  print('Admin panel screen fully restored and fixed.');
}
