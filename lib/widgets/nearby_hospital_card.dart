import 'package:flutter/material.dart';
import '../core/models/hospital_recommendation.dart';
import '../theme/bellota_colors.dart';

class NearbyHospitalCard extends StatelessWidget {
  final HospitalRecommendation recommendation;
  final VoidCallback onTap;

  const NearbyHospitalCard({
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.blanco,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.asuncion.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.local_hospital_rounded, color: colors.asuncion),
            ),
            const SizedBox(width: 16),
            Expanded(
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 12, color: colors.melon),
                      const SizedBox(width: 4),
                      Text(
                        '${recommendation.distanceText} • ${hospital.municipality}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textoMedio,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colors.textoMedio.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
