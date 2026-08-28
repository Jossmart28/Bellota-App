/// Modelo tipado para los datos del usuario autenticado.
///
/// Reemplaza el uso de `Map<String, dynamic>` retornado por la base de datos,
/// aportando type-safety, autocompletado y validación en tiempo de compilación.
class UserModel {
  final int id;
  final String name;
  final String email;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  // ── Deserialización ────────────────────────────────────────────────────────

  /// Crea un [UserModel] a partir de un mapa de SQLite.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  /// Convierte el modelo a un mapa compatible con SQLite.
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'created_at': createdAt.toIso8601String(),
      };

  // ── Utilidades ─────────────────────────────────────────────────────────────

  /// Retorna el primer nombre del usuario.
  String get firstName => name.split(' ').first;

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
