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
  });
}
