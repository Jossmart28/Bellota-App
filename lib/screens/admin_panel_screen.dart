import 'package:flutter/material.dart';

import '../core/models/user_model.dart';
import '../core/services/auth_service.dart';
import '../core/services/navigation_service.dart';
import '../core/services/role_guard.dart';
import '../core/services/user_role.dart';
import '../database/database_helper.dart';
import '../theme/bellota_colors.dart';
import 'login_screen.dart';
import 'audit_dashboard_screen.dart';

/// Pantalla principal del Administrador.
///
/// Permite gestionar usuarios (ver lista, cambiar roles, suspender/reactivar,
/// eliminar) y proporciona accesos directos a funciones avanzadas del sistema.
///
/// Acceso restringido: solo [UserRole.admin].
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  // ── Estado ─────────────────────────────────────────────────────────────────
  UserModel? _currentUser;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late TabController _tabController;

  // ── Ciclo de vida ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await AuthService.instance.currentSessionUser();
    final users = await DatabaseHelper.instance.getAllUsers();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _users = users;
        _isLoading = false;
      });
    }
  }

  // ── Filtrado ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users.where((u) {
      return (u['name'] as String).toLowerCase().contains(q) ||
          (u['email'] as String).toLowerCase().contains(q) ||
          (u['role'] as String).toLowerCase().contains(q);
    }).toList();
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  Future<void> _changeRole(Map<String, dynamic> user) async {
    final roles = ['usuario', 'admin', 'auditor'];
    final current = user['role'] as String;

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Cambiar rol de ${user['name']}'),
        children: roles
            .map((r) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, r),
                  child: Row(
                    children: [
                      Icon(
                        r == current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: BellotaColors.chilero,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        RolePermissions.roleName(
                          UserRole.values.firstWhere((e) => e.name == r),
                        ),
                        style: TextStyle(
                          fontWeight: r == current ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );

    if (selected == null || selected == current || !mounted) return;

    final userId = user['id'] as int;
    await DatabaseHelper.instance.updateUserRole(userId, selected);
    await AuthService.instance.logAction(
      action: 'role_change',
      targetType: 'user',
      targetId: userId,
      details: {'from': current, 'to': selected},
    );
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rol actualizado a "${RolePermissions.roleName(
            UserRole.values.firstWhere((e) => e.name == selected),
          )}"'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final isActive = (user['is_active'] as int) == 1;
    final userId = user['id'] as int;
    final name = user['name'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isActive ? 'Suspender cuenta' : 'Reactivar cuenta'),
        content: Text(
          isActive
              ? '¿Suspender la cuenta de $name? No podrá iniciar sesión.'
              : '¿Reactivar la cuenta de $name?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.orange : Colors.green,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isActive ? 'Suspender' : 'Reactivar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (isActive) {
      await DatabaseHelper.instance.suspendUser(userId);
      await AuthService.instance.logAction(
        action: 'user_suspend',
        targetType: 'user',
        targetId: userId,
      );
    } else {
      await DatabaseHelper.instance.reactivateUser(userId);
      await AuthService.instance.logAction(
        action: 'user_reactivate',
        targetType: 'user',
        targetId: userId,
      );
    }
    await _loadData();
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final userId = user['id'] as int;
    final name = user['name'] as String;

    // No permitir eliminar la propia cuenta
    if (userId == _currentUser?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminar tu propia cuenta.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Eliminar permanentemente la cuenta de $name y todos sus datos? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await DatabaseHelper.instance.deleteUser(userId);
    await AuthService.instance.logAction(
      action: 'user_delete',
      targetType: 'user',
      targetId: userId,
      details: {'name': name, 'email': user['email']},
    );
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cuenta de $name eliminada.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logAction(action: 'logout');
    await AuthService.instance.clearSession();
    if (!mounted) return;
    NavigationService.goAndClearStack(context, const LoginScreen());
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Verificar acceso
    if (!RoleGuard.check(_currentUser, roles: [UserRole.admin])) {
      return const Scaffold(
        body: Center(child: Text('Acceso denegado')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        backgroundColor: BellotaColors.chilero,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.settings), text: 'Sistema'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildSystemTab(),
              ],
            ),
    );
  }

  // ── Tab: Usuarios ──────────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Barra de búsqueda
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, correo o rol…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        // Contador de resultados
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filteredUsers.length} usuario(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Lista de usuarios
        Expanded(
          child: _filteredUsers.isEmpty
              ? const Center(child: Text('No se encontraron usuarios.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildUserCard(_filteredUsers[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = (user['is_active'] as int) == 1;
    final role = user['role'] as String;
    final isCurrentUser = (user['id'] as int) == _currentUser?.id;

    Color roleColor;
    IconData roleIcon;
    switch (role) {
      case 'admin':
        roleColor = BellotaColors.chilero;
        roleIcon = Icons.admin_panel_settings;
        break;
      case 'auditor':
        roleColor = BellotaColors.asuncion;
        roleIcon = Icons.manage_search;
        break;
      default:
        roleColor = BellotaColors.chiltoma;
        roleIcon = Icons.person;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.15),
          child: Icon(roleIcon, color: roleColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Tú',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] as String, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                _RoleBadge(role: role, color: roleColor),
                const SizedBox(width: 8),
                _StatusBadge(isActive: isActive),
              ],
            ),
          ],
        ),
        trailing: isCurrentUser
            ? null
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  switch (action) {
                    case 'role':
                      _changeRole(user);
                      break;
                    case 'status':
                      _toggleActive(user);
                      break;
                    case 'delete':
                      _deleteUser(user);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'role',
                    child: Row(children: [
                      Icon(Icons.swap_horiz, size: 18),
                      SizedBox(width: 8),
                      Text('Cambiar rol'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'status',
                    child: Row(children: [
                      Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        size: 18,
                        color: isActive ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(isActive ? 'Suspender' : 'Reactivar'),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_forever, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Tab: Sistema ───────────────────────────────────────────────────────────

  Widget _buildSystemTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Información del sistema'),
        _InfoTile(
          icon: Icons.people,
          label: 'Total de usuarios',
          value: '${_users.length}',
        ),
        _InfoTile(
          icon: Icons.verified_user,
          label: 'Admins',
          value: '${_users.where((u) => u['role'] == 'admin').length}',
        ),
        _InfoTile(
          icon: Icons.manage_search,
          label: 'Auditores',
          value: '${_users.where((u) => u['role'] == 'auditor').length}',
        ),
        _InfoTile(
          icon: Icons.person,
          label: 'Usuarios estándar',
          value: '${_users.where((u) => u['role'] == 'usuario').length}',
        ),
        _InfoTile(
          icon: Icons.block,
          label: 'Cuentas suspendidas',
          value: '${_users.where((u) => (u['is_active'] as int) == 0).length}',
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Herramientas'),
        ListTile(
          leading: const Icon(Icons.manage_search, color: Colors.purple),
          title: const Text('Ver logs de auditoría'),
          subtitle: const Text('Historial completo de acciones del sistema'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => NavigationService.goTo(
            context,
            const AuditDashboardScreen(),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
          title: const Text('Mi cuenta'),
          subtitle: Text('Rol: ${RolePermissions.roleName(UserRole.admin)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {/* Navegar a perfil propio */},
        ),
      ],
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  final Color color;

  const _RoleBadge({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      'admin' => 'Administrador',
      'auditor' => 'Auditor',
      _ => 'Usuario',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.block,
            size: 12,
            color: isActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Activo' : 'Suspendido',
            style: TextStyle(
              fontSize: 11,
              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: Colors.grey.shade600),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

