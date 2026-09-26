import 'health_center_model.dart';

class HospitalRecommendation {
  final HealthCenter hospital;
  final double totalScore;
  final double locationScore;
  final double symptomScore;
  final double? distanceKm;
  final List<String> matchedSymptoms;

  HospitalRecommendation({
    required this.hospital,
    required this.totalScore,
    required this.locationScore,
    required this.symptomScore,
    this.distanceKm,
    this.matchedSymptoms = const [],
  });

  String get distanceText {
    if (distanceKm == null) return "Distancia desconocida";
    if (distanceKm! < 1.0) {
      return "${(distanceKm! * 1000).round()} m";
    }
    return "${distanceKm!.toStringAsFixed(1)} km";
  }

  int get matchPercentage => (totalScore * 100).round();
}
