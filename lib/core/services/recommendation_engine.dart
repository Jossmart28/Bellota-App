import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:bellotadevelopment/core/models/health_center_model.dart';
import 'package:bellotadevelopment/core/models/hospital_recommendation.dart';
import 'package:bellotadevelopment/core/services/clinical_analysis_service.dart';

class RecommendationEngine {
  /// Retorna una lista de hospitales recomendados ordenados por score.
  /// 
  /// Integra el ruteo médico adaptado a la Costa Caribe (HealthcareRoutingService)
  /// para calcular la coincidencia entre lo que necesita la paciente y los 
  /// niveles de atención (tiers) que ofrece el centro de salud.
  List<HospitalRecommendation> recommend({
    required LatLng? userLocation,
    required List<String> userSymptoms,
    required List<String> userMedicalConditions,
    required List<HealthCenter> hospitals,
    List<ClinicalAlert>? activeAlerts,
  }) {
    List<HospitalRecommendation> recommendations = [];
    
    // Si no hay información de salud, ordenamos por pura relevancia y proximidad
    if (userLocation == null && userSymptoms.isEmpty && userMedicalConditions.isEmpty && (activeAlerts == null || activeAlerts.isEmpty)) {
      hospitals.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
      return hospitals.map((h) => HospitalRecommendation(
        hospital: h,
        totalScore: h.relevanceScore / 100.0,
        locationScore: 0.0,
        symptomScore: 0.0,
        distanceKm: null,
      )).take(5).toList();
    }

    // 1. Obtener los Niveles de Atención (Tiers) requeridos para la paciente
    final requiredTerminals = HealthcareRoutingService.routeAlerts(activeAlerts ?? []);
    final requiredTiers = requiredTerminals.map((t) => t.tier.name).toList();
    
    // Si no hay alertas activas, por defecto buscamos atención primaria
    if (requiredTiers.isEmpty) {
      requiredTiers.add(HealthcareTier.primaryCare.name);
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

      // 2. Calcular score de Tiers / Niveles de Atención (40%)
      double tierScore = 0.0;
      List<String> matchedTiers = [];
      
      int matchCount = 0;
      for (var reqTier in requiredTiers) {
        if (hospital.supportedTiers.contains(reqTier)) {
          matchCount++;
          matchedTiers.add(reqTier);
        }
      }
      
      if (requiredTiers.isNotEmpty) {
        // Ratio de cobertura de los servicios necesarios
        tierScore = (matchCount / requiredTiers.length) * 0.40;
      }
      
      // Si el hospital tiene emergencia y la paciente la requiere, damos un bonus del 10%
      if (requiredTiers.contains('emergency') && hospital.supportedTiers.contains('emergency')) {
        tierScore += 0.10; 
      }

      // 3. Calcular relevancia base del hospital (20%)
      double relevanceScore = (hospital.relevanceScore / 100.0) * 0.20;

      double totalScore = locationScore + tierScore + relevanceScore;

      // Penalizar si la paciente requiere emergencia y el hospital no la tiene
      if (requiredTiers.contains('emergency') && !hospital.supportedTiers.contains('emergency')) {
        totalScore *= 0.3; // Reduce dramáticamente la puntuación
      }
      
      // Asegurar que el score no pase de 1.0
      totalScore = math.min(totalScore, 1.0);

      recommendations.add(HospitalRecommendation(
        hospital: hospital,
        totalScore: totalScore,
        locationScore: locationScore,
        symptomScore: tierScore, // Guardado aquí para la UI
        distanceKm: userLocation != null ? distanceKm : null,
        matchedSymptoms: matchedTiers, 
      ));
    }

    // Ordenar de mayor a menor score
    recommendations.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return recommendations.take(5).toList();
  }

  /// Retorna hospitales ordenados únicamente por cercanía física (para el mapa)
  List<HospitalRecommendation> getNearby({
    required LatLng? userLocation,
    required List<HealthCenter> hospitals,
  }) {
    if (userLocation == null) {
      return hospitals.map((h) => HospitalRecommendation(
        hospital: h,
        totalScore: 0.0,
        locationScore: 0.0,
        symptomScore: 0.0,
        distanceKm: null,
      )).toList();
    }

    var nearby = hospitals.map((h) {
      final dist = _calculateDistance(userLocation, h.location);
      return HospitalRecommendation(
        hospital: h,
        totalScore: 0.0,
        locationScore: 1.0, // Solo importa cercanía
        symptomScore: 0.0,
        distanceKm: dist,
      );
    }).toList();

    nearby.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
    return nearby;
  }

  double _calculateDistance(LatLng? p1, LatLng p2) {
    if (p1 == null) return 999.0;
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2) / 1000.0; // en km
  }
}
