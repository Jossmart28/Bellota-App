import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/bellota_colors.dart';

/// Fila de configuración estilo cottagecore con ícono semántico.
/// Reemplaza _buildHealthRow() del profile_screen, centralizando el diseño.
class CozyRowItem extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  final IconData icon;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final bool showArrow;

  const CozyRowItem({
    super.key,
    required this.title,
    required this.value,
    required this.onTap,
    this.icon = Icons.tune_rounded,
    this.iconBackgroundColor,
    this.iconColor,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).bellotaColors;
    final bgColor = iconBackgroundColor ?? colors.melon.withValues(alpha: 0.10);
    final fgColor = iconColor ?? colors.melon;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: colors.blanco,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.nancite.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: fgColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textoDark,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textoMedio,
                  ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.textoMedio.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
