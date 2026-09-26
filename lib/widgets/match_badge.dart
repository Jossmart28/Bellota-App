import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MatchBadge extends StatelessWidget {
  final int percentage;

  const MatchBadge({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    Color getBadgeColor() {
      if (percentage >= 80) return const Color(0xFF4CAF50); // Verde
      if (percentage >= 50) return Theme.of(context).bellotaColors.melon; // Naranja
      return Theme.of(context).bellotaColors.textoMedio; // Gris
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getBadgeColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getBadgeColor().withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: getBadgeColor()),
          const SizedBox(width: 4),
          Text(
            '$percentage% Match',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: getBadgeColor(),
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack);
  }
}
