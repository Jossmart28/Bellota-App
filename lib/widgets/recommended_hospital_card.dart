import 'package:flutter/material.dart';
import '../core/models/hospital_recommendation.dart';
import '../theme/bellota_colors.dart';
import 'match_badge.dart';

class RecommendedHospitalCard extends StatelessWidget {
  final HospitalRecommendation recommendation;
  final VoidCallback onTap;

  const RecommendedHospitalCard({
    super.key,
    required this.recommendation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hospital = recommendation.hospital;
    final colors = Theme.of(context).bellotaColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: colors.blanco,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.melon.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Gradient
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  colors: [colors.chilero, colors.gradienteClaro],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.local_hospital_rounded, color: colors.blanco.withOpacity(0.8), size: 40),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: MatchBadge(percentage: recommendation.matchPercentage),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hospital.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textoDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: colors.melon),
                      const SizedBox(width: 4),
                      Text(
                        recommendation.distanceText,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textoMedio,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (hospital.openHours.isNotEmpty) ...[
                        Icon(Icons.access_time_rounded, size: 14, color: colors.melon),
                        const SizedBox(width: 4),
                        Text(
                          hospital.openHours,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textoMedio,
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: hospital.specialtyTags.take(2).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.nancite,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: colors.textoDark,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
