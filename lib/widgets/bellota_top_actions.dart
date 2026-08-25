import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';

class BellotaTopActions extends StatelessWidget {
  final bool showSettings;
  final bool showNotifications;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onLanguagePressed;
  final VoidCallback? onTalkBackPressed;
  final VoidCallback? onNotificationPressed;

  const BellotaTopActions({
    super.key,
    this.showSettings = false,
    this.showNotifications = false,
    this.onSettingsPressed,
    this.onLanguagePressed,
    this.onTalkBackPressed,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Botón de Configuración (Solo en Perfil)
        if (showSettings) ...[
          _buildCircleButton(
            icon: Icons.settings_outlined,
            backgroundColor: BellotaColors.blanco,
            iconColor: BellotaColors.textoDark,
            onPressed: onSettingsPressed ?? () {},
          ),
          const SizedBox(width: 6),
        ],

        // 2. Botón de Idioma (Va en todas)
        _buildCircleButton(
          child: const Text(
            '文A',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BellotaColors.textoDark,
            ),
          ),
          backgroundColor: BellotaColors.blanco,
          onPressed: onLanguagePressed ?? () {},
        ),
        const SizedBox(width: 6),

        // 3. Botón de TalkBack / Audio (Va en todas)
        _buildCircleButton(
          icon: Icons.volume_up_rounded,
          backgroundColor: BellotaColors.chilero,
          iconColor: BellotaColors.blanco,
          onPressed: onTalkBackPressed ?? () {},
        ),

        // 4. Botón de Notificaciones (Solo en el Dashboard)
        if (showNotifications) ...[
          const SizedBox(width: 6),
          _buildCircleButton(
            icon: Icons.notifications_outlined,
            backgroundColor: BellotaColors.blanco,
            iconColor: BellotaColors.textoDark,
            onPressed: onNotificationPressed ?? () {},
          ),
        ],
      ],
    );
  }

  Widget _buildCircleButton({
    IconData? icon,
    Widget? child,
    required Color backgroundColor,
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: child ?? Icon(icon, color: iconColor, size: 18),
        onPressed: onPressed,
      ),
    );
  }
}