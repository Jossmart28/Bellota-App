import 'package:bellotadevelopment/core/models/audit_log_model.dart';

abstract class AuditRepository {
  Future<int> insertAuditLog({
    int? userId,
    required String action,
    String? targetType,
    int? targetId,
    Map<String, dynamic>? details,
    String? ipAddress,
  });

  Future<List<AuditLogModel>> getAuditLogs({
    int? userId,
    String? action,
    String? targetType,
    String? startDate,
    String? endDate,
    int limit = 50,
    int offset = 0,
  });

  Future<int> getAuditLogCount({
    int? userId,
    String? action,
    String? startDate,
    String? endDate,
  });

  Future<Map<String, int>> getAuditStats();
}
