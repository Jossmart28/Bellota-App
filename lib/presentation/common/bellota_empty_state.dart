import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';

class BellotaEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? imagePath;
  final IconData? fallbackIcon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool compact;

  const BellotaEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.imagePath = 'assets/images/bella_mascot.png',
    this.fallbackIcon,
    this.buttonText,
    this.onButtonPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<BellotaColors>() ?? BellotaColors.light;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 16.0 : 32.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagen o Icono con animación flotante sutil
            if (imagePath != null)
              Image.asset(
                imagePath!,
                height: compact ? 100 : 160,
                fit: BoxFit.contain,
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut)
            else if (fallbackIcon != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.nancite.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  fallbackIcon,
                  size: compact ? 48 : 72,
                  color: colors.chilero.withValues(alpha: 0.7),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut),

            SizedBox(height: compact ? 16 : 24),

            // Título
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w800,
                color: colors.textoDark,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 12),

            // Mensaje descriptivo
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w500,
                color: colors.textoMedio,
                height: 1.4,
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),

            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: compact ? 24 : 32),
              // Botón de acción con estilo Bellota
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.chilero,
                  foregroundColor: colors.blanco,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  buttonText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutBack),
            ],
          ],
        ),
      ),
    );
  }
}
