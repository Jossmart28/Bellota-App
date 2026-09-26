import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../models/health_center_model.dart';
import '../models/hospital_recommendation.dart';
import '../data/symptom_hospital_mapping.dart';

class RecommendationEngine {
  /// Retorna una lista de hospitales recomendados ordenados por score.
  /// Incluye:
  /// - 40% distancia
  /// - 25% coincidencia de síntomas recientes
  /// - 20% coincidencia de condiciones médicas
  /// - 15% relevancia del hospital
  List<HospitalRecommendation> recommend({
    required LatLng? userLocation,
    required List<String> userSymptoms,
    required List<String> userMedicalConditions,
    required List<HealthCenter> hospitals,
  }) {
    List<HospitalRecommendation> recommendations = [];
    final requiredSpecialties = SymptomHospitalMapping.getRequiredSpecialties(userSymptoms, userMedicalConditions);
    
    // Si la usuaria no tiene ubicación ni síntomas ni condiciones, retornamos top relevancia
    if (userLocation == null && userSymptoms.isEmpty && userMedicalConditions.isEmpty) {
      hospitals.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      return hospitals.map((h) => HospitalRecommendation(
        hospital: h,
        totalScore: h.relevanceScore / 100.0,
        locationScore: 0.0,
        symptomScore: 0.0,
        distanceKm: null,
      )).take(5).toList();
    }

    for (var hospital in hospitals) {
      // 1. Calcular score de ubicación (40%)
      double distanceKm = _calculateDistance(userLocation, hospital.location);
      double locationScore = 0.0;
      if (userLocation != null) {
        // Distancia: Máximo score si está a 0km, decae a 0 score a los 25km.
        if (distanceKm <= 25.0) {
          locationScore = ((25.0 - distanceKm) / 25.0) * 0.40;
        }
      }

      // 2. Calcular score de síntomas (25%)
      double symptomScore = 0.0;
      List<String> matched = [];
      if (userSymptoms.isNotEmpty) {
        int matches = 0;
        final hospitalTags = hospital.symptomTags;
        for (var specialty in requiredSpecialties) {
          if (hospitalTags.contains(specialty) || hospital.specialtyTags.contains(specialty)) {
            matches++;
            matched.add(specialty);
          }
        }
        
        double matchRatio = matches / (requiredSpecialties.isNotEmpty ? requiredSpecialties.length : 1);
        // Penalizar si no hay match, pero recompensar parcialmente si el hospital tiene emergencia general
        if (matches == 0 && hospital.emergencyAvailable) {
          matchRatio = 0.3; // 30% del score de síntomas por tener emergencia (salvavidas)
        }
        
        symptomScore = math.min(matchRatio * 0.25, 0.25);
      }

      // 3. Calcular score de condiciones médicas (20%)
      double conditionsScore = 0.0;
      if (userMedicalConditions.isNotEmpty) {
        int conditionMatches = 0;
        final conditionSpecialties = SymptomHospitalMapping.getRequiredSpecialties([], userMedicalConditions);
        for (var specialty in conditionSpecialties) {
          if (hospital.specialtyTags.contains(specialty)) {
            conditionMatches++;
          }
        }
        double conditionRatio = conditionMatches / (conditionSpecialties.isNotEmpty ? conditionSpecialties.length : 1);
        conditionsScore = math.min(conditionRatio * 0.20, 0.20);
      }

      // 4. Calcular relevancia (15%)
      double relevanceScore = (hospital.relevanceScore / 100.0) * 0.15;

      // 5. Total
      double total = locationScore + symptomScore + conditionsScore + relevanceScore;
      
      recommendations.add(HospitalRecommendation(
        hospital: hospital,
        totalScore: total,
        locationScore: locationScore,
        symptomScore: symptomScore,
        distanceKm: userLocation != null ? distanceKm : null,
        matchedSymptoms: matched,
      ));
    }

    // Ordenar de mayor a menor score
    recommendations.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return recommendations.take(5).toList();
  }

  /// Retorna hospitales cercanos ordenados solo por distancia
  List<HospitalRecommendation> getNearby({
    required LatLng? userLocation,
    required List<HealthCenter> hospitals,
  }) {
    if (userLocation == null) return [];

    List<HospitalRecommendation> nearby = [];
    for (var hospital in hospitals) {
      double dist = _calculateDistance(userLocation, hospital.location);
      nearby.add(HospitalRecommendation(
        hospital: hospital,
        totalScore: 0.0,
        locationScore: 0.0,
        symptomScore: 0.0,
        distanceKm: dist,
      ));
    }

    nearby.sort((a, b) => (a.distanceKm ?? 9999).compareTo(b.distanceKm ?? 9999));
    return nearby.take(10).toList();
  }

  // Haversine formula para calcular distancia en KM
  double _calculateDistance(LatLng? loc1, LatLng? loc2) {
    if (loc1 == null || loc2 == null) return 9999.9;
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(loc2.latitude - loc1.latitude);
    final dLon = _degreesToRadians(loc2.longitude - loc1.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(loc1.latitude)) *
            math.cos(_degreesToRadians(loc2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
