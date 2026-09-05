import '../models/user_role.dart';

/// Modelo tipado para los datos del usuario autenticado.
///
/// Reemplaza el uso de `Map<String, dynamic>` retornado por la base de datos,
/// aportando type-safety, autocompletado y validaciÃ³n en tiempo de compilaciÃ³n.
class UserModel {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = UserRole.usuario,
    this.isActive = true,
    required this.createdAt,
  });

  // â”€â”€ DeserializaciÃ³n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Crea un [UserModel] a partir de un mapa de SQLite.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      role: _parseRole(map['role'] as String?),
      isActive: (map['is_active'] as int?) != 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Convierte una cadena de texto al enum [UserRole].
  static UserRole _parseRole(String? roleStr) {
    switch (roleStr) {
      case 'admin':
        return UserRole.admin;
      case 'auditor':
        return UserRole.auditor;
      case 'usuario':
      default:
        return UserRole.usuario;
    }
  }

  // â”€â”€ SerializaciÃ³n â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Convierte el modelo a un mapa compatible con SQLite.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  // â”€â”€ Utilidades â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Retorna el primer nombre del usuario.
  String get firstName => name.trim().isEmpty ? '' : name.trim().split(' ').first;

  /// `true` si el usuario es administrador.
  bool get isAdmin => role == UserRole.admin;

  /// `true` si el usuario es auditor.
  bool get isAuditor => role == UserRole.auditor;

  /// `true` si el usuario es un usuario estÃ¡ndar.
  bool get isUsuario => role == UserRole.usuario;

  /// Crea una copia del modelo con los campos especificados modificados.
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email, role: ${role.name})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role &&
        other.isActive == isActive &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, email, role, isActive, createdAt);
}

