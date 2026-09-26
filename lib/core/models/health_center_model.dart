import 'package:latlong2/latlong.dart';

/// Modelo de datos para un centro de salud
class HealthCenter {
  final String id;
  final String name;
  final String type;
  final String address;
  final String phone;
  final String municipality;
  final String department;
  final List<String> services;
  final LatLng location;

  // Nuevos campos
  final int relevanceScore;
  final List<String> specialtyTags;
  final List<String> symptomTags;
  final String openHours;
  final bool emergencyAvailable;
  final String? imageAsset;
  final String? description;
  final Map<String, dynamic>? metadata;

  HealthCenter({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.municipality,
    required this.department,
    required this.services,
    required this.location,
    this.relevanceScore = 50,
    this.specialtyTags = const [],
    this.symptomTags = const [],
    this.openHours = '',
    this.emergencyAvailable = false,
    this.imageAsset,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'address': address,
    'phone': phone,
    'municipality': municipality,
    'department': department,
    'services': services,
    'latitude': location.latitude,
    'longitude': location.longitude,
    'relevanceScore': relevanceScore,
    'specialtyTags': specialtyTags,
    'symptomTags': symptomTags,
    'openHours': openHours,
    'emergencyAvailable': emergencyAvailable,
    'imageAsset': imageAsset,
    'description': description,
    'metadata': metadata,
  };

  factory HealthCenter.fromJson(Map<String, dynamic> json) => HealthCenter(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    type: json['type'] ?? '',
    address: json['address'] ?? '',
    phone: json['phone'] ?? '',
    municipality: json['municipality'] ?? '',
    department: json['department'] ?? '',
    services: List<String>.from(json['services'] ?? []),
    location: LatLng(json['latitude'] ?? 0.0, json['longitude'] ?? 0.0),
    relevanceScore: json['relevanceScore'] ?? 50,
    specialtyTags: List<String>.from(json['specialtyTags'] ?? []),
    symptomTags: List<String>.from(json['symptomTags'] ?? []),
    openHours: json['openHours'] ?? '',
    emergencyAvailable: json['emergencyAvailable'] ?? false,
    imageAsset: json['imageAsset'],
    description: json['description'],
    metadata: json['metadata'],
  );
}
