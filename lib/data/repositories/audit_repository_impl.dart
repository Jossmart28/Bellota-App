import 'dart:convert';
import 'package:bellotadevelopment/core/models/audit_log_model.dart';
import 'package:bellotadevelopment/domain/repositories/audit_repository.dart';
import 'package:bellotadevelopment/data/datasources/database_provider.dart';

class AuditRepositoryImpl implements AuditRepository {
  final DatabaseProvider _dbProvider;

  AuditRepositoryImpl(this._dbProvider);

  @override
  Future<int> insertAuditLog({
    int? userId,
    required String action,
    String? targetType,
    int? targetId,
    Map<String, dynamic>? details,
    String? ipAddress,
  }) async {
    final db = await _dbProvider.database;
    return await db.insert('audit_logs', {
      'user_id': userId,
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'details': details != null ? jsonEncode(details) : null,
      'ip_address': ipAddress,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<AuditLogModel>> getAuditLogs({
    int? userId,
    String? action,
    String? targetType,
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _dbProvider.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (userId != null) { conditions.add('user_id = ?'); args.add(userId); }
    if (action != null && action.isNotEmpty) { conditions.add('action = ?'); args.add(action); }
    if (targetType != null && targetType.isNotEmpty) { conditions.add('target_type = ?'); args.add(targetType); }
    if (startDate != null) { conditions.add("created_at >= ?"); args.add('$startDate 00:00:00'); }
    if (endDate != null) { conditions.add("created_at <= ?"); args.add('$endDate 23:59:59'); }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');

    final result = await db.query(
      'audit_logs',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return result.map(AuditLogModel.fromMap).toList();
  }

  @override
  Future<int> getAuditLogCount({
    int? userId,
    String? action,
    String? startDate,
    String? endDate,
  }) async {
    final db = await _dbProvider.database;

    final conditions = <String>[];
    final args = <dynamic>[];

    if (userId != null) { conditions.add('user_id = ?'); args.add(userId); }
    if (action != null && action.isNotEmpty) { conditions.add('action = ?'); args.add(action); }
    if (startDate != null) { conditions.add("created_at >= ?"); args.add('$startDate 00:00:00'); }
    if (endDate != null) { conditions.add("created_at <= ?"); args.add('$endDate 23:59:59'); }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');
    final countQuery = 'SELECT COUNT(*) as count FROM audit_logs${where != null ? ' WHERE $where' : ''}';

    final result = await db.rawQuery(countQuery, args.isEmpty ? null : args);
    return result.first['count'] as int? ?? 0;
  }

  @override
  Future<Map<String, int>> getAuditStats() async {
    final db = await _dbProvider.database;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')} 00:00:00';

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN created_at >= ? THEN 1 ELSE 0 END) as todayCount,
        SUM(CASE WHEN action = 'login_failed' THEN 1 ELSE 0 END) as failedLogins,
        SUM(CASE WHEN action = 'role_change' THEN 1 ELSE 0 END) as roleChanges,
        SUM(CASE WHEN action = 'suspend_user' THEN 1 ELSE 0 END) as suspensions,
        SUM(CASE WHEN action = 'delete_user' THEN 1 ELSE 0 END) as deletions
      FROM audit_logs
    ''', [todayStr]);

    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'totalLogs': row['total'] as int? ?? 0,
        'todayLogs': row['todayCount'] as int? ?? 0,
        'failedLogins': row['failedLogins'] as int? ?? 0,
        'roleChanges': row['roleChanges'] as int? ?? 0,
        'suspensions': row['suspensions'] as int? ?? 0,
        'deletions': row['deletions'] as int? ?? 0,
      };
    }
    return {
      'totalLogs': 0, 'todayLogs': 0, 'failedLogins': 0,
      'roleChanges': 0, 'suspensions': 0, 'deletions': 0,
    };
  }
}
