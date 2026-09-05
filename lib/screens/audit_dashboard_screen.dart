import 'package:flutter/material.dart';

import '../core/models/audit_log_model.dart';
import '../core/models/user_model.dart';
import '../core/services/auth_service.dart';
import '../widgets/role_guard.dart';
import '../core/models/user_role.dart';
import '../navigation/navigation_service.dart';
import '../database/database_helper.dart';
import '../theme/bellota_colors.dart';
import 'login_screen.dart';

/// Dashboard principal del Auditor.
///
/// Permite al [UserRole.auditor] (y tambiÃ©n al [UserRole.admin]) revisar el
/// historial completo de acciones del sistema, filtrar por usuario/acciÃ³n/fecha,
/// ver estadÃ­sticas de cumplimiento y detectar anomalÃ­as.
///
/// Acceso: [UserRole.auditor] y [UserRole.admin] (solo lectura, sin ediciÃ³n).
class AuditDashboardScreen extends StatefulWidget {
  const AuditDashboardScreen({super.key});

  @override
  State<AuditDashboardScreen> createState() => _AuditDashboardScreenState();
}

class _AuditDashboardScreenState extends State<AuditDashboardScreen>
    with SingleTickerProviderStateMixin {
  // â”€â”€ Estado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  UserModel? _currentUser;
  List<AuditLogModel> _logs = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  late TabController _tabController;

  // â”€â”€ Filtros â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String? _filterAction;
  String? _filterStartDate;
  String? _filterEndDate;
  int _currentPage = 0;
  static const int _pageSize = 30;

  // Tipos de acciÃ³n disponibles para el filtro
  static const List<String> _actionTypes = [
    'login',
    'logout',
    'login_failed',
    'register',
    'role_change',
    'user_suspend',
    'user_reactivate',
    'user_delete',
    'profile_update',
    'daily_log_save',
    'daily_log_delete',
    'medication_add',
    'medication_delete',
    'export_report',
  ];

  // â”€â”€ Ciclo de vida â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.instance.currentSessionUser();
      final logs = await DatabaseHelper.instance.getAuditLogs(
        action: _filterAction,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      final stats = await DatabaseHelper.instance.getAuditStats();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _logs = logs;
          _stats = stats;
        });
      }
    } catch (e) {
      debugPrint('Error loading audit data: $e');
      // Optionally show error state
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logAction(action: 'logout');
    await AuthService.instance.clearSession();
    if (!mounted) return;
    NavigationService.goAndClearStack(context, const LoginScreen());
  }

  void _applyFilters() {
    setState(() {
      _currentPage = 0;
    });
    _loadData();
  }

  void _clearFilters() {
    setState(() {
      _filterAction = null;
      _filterStartDate = null;
      _filterEndDate = null;
      _currentPage = 0;
    });
    _loadData();
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    // Mostrar loader mientras se resuelve el usuario de sesiÃ³n
    if (_isLoading || _currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Verificar acceso solo cuando el usuario ya fue cargado
    if (!RoleGuard.check(
      _currentUser,
      roles: [UserRole.auditor, UserRole.admin],
    )) {
      return const Scaffold(
        body: Center(child: Text('Acceso denegado')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dashboard de AuditorÃ­a'),
        backgroundColor: Theme.of(context).bellotaColors.asuncion,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesiÃ³n',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Resumen'),
            Tab(icon: Icon(Icons.list_alt), text: 'Logs'),
            Tab(icon: Icon(Icons.warning_amber), text: 'AnomalÃ­as'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatsTab(),
                _buildLogsTab(),
                _buildAnomaliesTab(),
              ],
            ),
    );
  }

  // â”€â”€ Tab: Resumen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(title: 'Actividad general'),
        const SizedBox(height: 12),
        _StatsGrid(stats: _stats),
        const SizedBox(height: 24),
        _SectionTitle(title: 'InformaciÃ³n del auditor'),
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE8EAF6),
            child: Icon(Icons.manage_search, color: Colors.indigo),
          ),
          title: Text(_currentUser?.name ?? 'â€”'),
          subtitle: Text(_currentUser?.email ?? 'â€”'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              RolePermissions.roleName(_currentUser?.role ?? UserRole.auditor),
              style: TextStyle(
                color: Colors.indigo.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _SectionTitle(title: 'Permisos asignados'),
        ...RolePermissions.describe(
          _currentUser?.role ?? UserRole.auditor,
        ).map(
          (perm) => ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle_outline,
                size: 18, color: Colors.green),
            title: Text(perm, style: const TextStyle(fontSize: 14)),
          ),
        ),
      ],
    );
  }

  // â”€â”€ Tab: Logs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildLogsTab() {
    return Column(
      children: [
        // Panel de filtros
        _FiltersPanel(
          selectedAction: _filterAction,
          startDate: _filterStartDate,
          endDate: _filterEndDate,
          actionTypes: _actionTypes,
          onActionChanged: (v) => setState(() => _filterAction = v),
          onStartDateChanged: (v) => setState(() => _filterStartDate = v),
          onEndDateChanged: (v) => setState(() => _filterEndDate = v),
          onApply: _applyFilters,
          onClear: _clearFilters,
        ),

        // Contador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_logs.length} registro(s) â€” PÃ¡gina ${_currentPage + 1}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),

        // Lista de logs
        Expanded(
          child: _logs.isEmpty
              ? const Center(
                  child: Text('No hay registros para los filtros seleccionados.'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _buildLogTile(_logs[i]),
                ),
        ),

        // PaginaciÃ³n
        if (_logs.length == _pageSize || _currentPage > 0)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _currentPage > 0
                      ? () {
                          setState(() => _currentPage--);
                          _loadData();
                        }
                      : null,
                  child: const Text('â† Anterior'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _logs.length == _pageSize
                      ? () {
                          setState(() => _currentPage++);
                          _loadData();
                        }
                      : null,
                  child: const Text('Siguiente â†’'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLogTile(AuditLogModel log) {
    final color = log.isSuspicious ? Colors.red.shade400 : Colors.grey.shade500;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          _iconForAction(log.actionIconName),
          size: 16,
          color: color,
        ),
      ),
      title: Text(
        log.actionDisplayName,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: log.isSuspicious ? Colors.red.shade700 : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (log.targetType != null)
            Text(
              'Recurso: ${log.targetType}${log.targetId != null ? ' #${log.targetId}' : ''}',
              style: const TextStyle(fontSize: 11),
            ),
          Text(
            _formatDate(log.createdAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      trailing: log.userId != null
          ? Text(
              'User #${log.userId}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            )
          : null,
    );
  }

  // â”€â”€ Tab: AnomalÃ­as â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildAnomaliesTab() {
    final failedLogins = _stats['failedLogins'] ?? 0;
    final roleChanges = _stats['roleChanges'] ?? 0;
    final deletions = _stats['deletions'] ?? 0;

    final anomalies = <_AnomalyItem>[
      if (failedLogins > 0)
        _AnomalyItem(
          icon: Icons.login,
          title: 'Intentos de inicio de sesiÃ³n fallidos',
          description: '$failedLogins intento(s) fallido(s) detectado(s).',
          severity: failedLogins > 5 ? _Severity.high : _Severity.medium,
          count: failedLogins,
        ),
      if (roleChanges > 0)
        _AnomalyItem(
          icon: Icons.admin_panel_settings,
          title: 'Cambios de rol',
          description:
              '$roleChanges cambio(s) de rol registrado(s). Verificar autorizaciÃ³n.',
          severity: _Severity.medium,
          count: roleChanges,
        ),
      if (deletions > 0)
        _AnomalyItem(
          icon: Icons.delete_forever,
          title: 'Eliminaciones de usuario',
          description: '$deletions cuenta(s) de usuario eliminada(s).',
          severity: _Severity.high,
          count: deletions,
        ),
    ];

    if (anomalies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Sin anomalÃ­as detectadas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'El sistema opera dentro de los parÃ¡metros normales.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(title: 'AnomalÃ­as detectadas'),
        const SizedBox(height: 12),
        ...anomalies.map((a) => _AnomalyCard(item: a)),
      ],
    );
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  IconData _iconForAction(String name) {
    const map = {
      'login': Icons.login,
      'logout': Icons.logout,
      'error_outline': Icons.error_outline,
      'person_add': Icons.person_add,
      'admin_panel_settings': Icons.admin_panel_settings,
      'block': Icons.block,
      'check_circle': Icons.check_circle,
      'delete_forever': Icons.delete_forever,
      'edit': Icons.edit,
      'note_add': Icons.note_add,
      'medication': Icons.medication,
      'medication_liquid': Icons.medication_liquid,
      'file_download': Icons.file_download,
    };
    return map[name] ?? Icons.info;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// â”€â”€ Widgets auxiliares â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatCard(label: 'Total logs', value: stats['totalLogs'] ?? 0, icon: Icons.list_alt, color: Colors.blue),
      _StatCard(label: 'Hoy', value: stats['todayLogs'] ?? 0, icon: Icons.today, color: Colors.green),
      _StatCard(label: 'Login fallido', value: stats['failedLogins'] ?? 0, icon: Icons.error_outline, color: Colors.red),
      _StatCard(label: 'Cambios de rol', value: stats['roleChanges'] ?? 0, icon: Icons.swap_horiz, color: Colors.orange),
      _StatCard(label: 'Suspensiones', value: stats['suspensions'] ?? 0, icon: Icons.block, color: Colors.purple),
      _StatCard(label: 'Eliminaciones', value: stats['deletions'] ?? 0, icon: Icons.delete_forever, color: Colors.red.shade700),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: items,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final String? selectedAction;
  final String? startDate;
  final String? endDate;
  final List<String> actionTypes;
  final ValueChanged<String?> onActionChanged;
  final ValueChanged<String?> onStartDateChanged;
  final ValueChanged<String?> onEndDateChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _FiltersPanel({
    required this.selectedAction,
    required this.startDate,
    required this.endDate,
    required this.actionTypes,
    required this.onActionChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.filter_list),
      title: Text(
        selectedAction != null || startDate != null || endDate != null
            ? 'Filtros activos'
            : 'Filtros',
        style: TextStyle(
          fontWeight: selectedAction != null || startDate != null || endDate != null
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Filtro por acciÃ³n
              DropdownButtonFormField<String>(
                value: selectedAction,
                decoration: const InputDecoration(
                  labelText: 'Tipo de acciÃ³n',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...actionTypes.map(
                    (a) => DropdownMenuItem(
                      value: a,
                      child: Text(AuditLogModel(
                        action: a,
                        createdAt: DateTime.now(),
                      ).actionDisplayName),
                    ),
                  ),
                ],
                onChanged: onActionChanged,
              ),
              const SizedBox(height: 12),
              // Rango de fechas (inputs simples)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: startDate,
                      decoration: const InputDecoration(
                        labelText: 'Desde (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (v) =>
                          onStartDateChanged(v.isEmpty ? null : v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: endDate,
                      decoration: const InputDecoration(
                        labelText: 'Hasta (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (v) =>
                          onEndDateChanged(v.isEmpty ? null : v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: onClear, child: const Text('Limpiar')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onApply,
                    child: const Text('Aplicar filtros'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _Severity { low, medium, high }

class _AnomalyItem {
  final IconData icon;
  final String title;
  final String description;
  final _Severity severity;
  final int count;

  const _AnomalyItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.severity,
    required this.count,
  });
}

class _AnomalyCard extends StatelessWidget {
  final _AnomalyItem item;
  const _AnomalyCard({required this.item});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (item.severity) {
      case _Severity.high:
        color = Colors.red;
        label = 'Alta';
        break;
      case _Severity.medium:
        color = Colors.orange;
        label = 'Media';
        break;
      case _Severity.low:
        color = Colors.yellow.shade700;
        label = 'Baja';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(item.icon, color: color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(item.description, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}


