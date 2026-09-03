import 'dart:convert';

/// Modelo de datos para los registros del log de auditoría.
///
/// Registra las acciones realizadas por los usuarios en el sistema
/// para seguimiento, cumplimiento y detección de anomalías.
class AuditLogModel {
  /// ID único del registro en la base de datos.
  final int? id;

  /// ID del usuario que realizó la acción.
  final int? userId;

  /// Nombre de la acción realizada (ej: 'login', 'role_change', 'user_delete').
  final String action;

  /// Tipo del recurso afectado ('user', 'profile', 'daily_log', 'medication', 'system').
  final String? targetType;

  /// ID del recurso afectado.
  final int? targetId;

  /// Detalles adicionales en formato JSON (antes/después, contexto extra).
  final Map<String, dynamic>? details;

  /// Dirección IP del usuario (cuando esté disponible).
  final String? ipAddress;

  /// Fecha y hora de la acción.
  final DateTime createdAt;

  const AuditLogModel({
    this.id,
    this.userId,
    required this.action,
    this.targetType,
    this.targetId,
    this.details,
    this.ipAddress,
    required this.createdAt,
  });

  // ── Deserialización ────────────────────────────────────────────────────────

  /// Crea un [AuditLogModel] a partir de un mapa de SQLite.
  factory AuditLogModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? parsedDetails;
    if (map['details'] != null && map['details'] is String) {
      try {
        parsedDetails =
            jsonDecode(map['details'] as String) as Map<String, dynamic>;
      } catch (_) {
        parsedDetails = {'raw': map['details']};
      }
    }

    return AuditLogModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      action: map['action'] as String,
      targetType: map['target_type'] as String?,
      targetId: map['target_id'] as int?,
      details: parsedDetails,
      ipAddress: map['ip_address'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  /// Convierte el modelo a un mapa compatible con SQLite.
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'details': details != null ? jsonEncode(details) : null,
        'ip_address': ipAddress,
        'created_at': createdAt.toIso8601String(),
      };

  // ── Utilidades ─────────────────────────────────────────────────────────────

  /// Mapa de acción → nombre legible para la UI.
  static const Map<String, String> _actionLabels = {
    'login': 'Inicio de sesión',
    'logout': 'Cierre de sesión',
    'login_failed': 'Intento de login fallido',
    'register': 'Registro de usuario',
    'role_change': 'Cambio de rol',
    'user_suspend': 'Suspensión de cuenta',
    'user_reactivate': 'Reactivación de cuenta',
    'user_delete': 'Eliminación de usuario',
    'profile_update': 'Actualización de perfil',
    'daily_log_save': 'Registro diario guardado',
    'daily_log_delete': 'Registro diario eliminado',
    'medication_add': 'Medicamento agregado',
    'medication_delete': 'Medicamento eliminado',
    'system_config': 'Configuración del sistema',
    'export_report': 'Exportación de reporte',
  };

  /// Nombre legible de la acción para mostrar en la UI.
  String get actionDisplayName => _actionLabels[action] ?? action;

  /// Icono sugerido para la acción (nombre de Material Icon).
  String get actionIconName {
    switch (action) {
      case 'login':
        return 'login';
      case 'logout':
        return 'logout';
      case 'login_failed':
        return 'error_outline';
      case 'register':
        return 'person_add';
      case 'role_change':
        return 'admin_panel_settings';
      case 'user_suspend':
        return 'block';
      case 'user_reactivate':
        return 'check_circle';
      case 'user_delete':
        return 'delete_forever';
      case 'profile_update':
        return 'edit';
      case 'daily_log_save':
        return 'note_add';
      case 'medication_add':
        return 'medication';
      case 'medication_delete':
        return 'medication_liquid';
      case 'export_report':
        return 'file_download';
      default:
        return 'info';
    }
  }

  /// Indica si esta acción es potencialmente anómala.
  bool get isSuspicious =>
      action == 'login_failed' ||
      action == 'user_delete' ||
      action == 'role_change';

  @override
  String toString() =>
      'AuditLogModel(id: $id, userId: $userId, action: $action, '
      'target: $targetType#$targetId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AuditLogModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
