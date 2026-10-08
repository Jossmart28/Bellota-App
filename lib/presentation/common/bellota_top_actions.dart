import 'package:flutter/material.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/l10n/language_notifier.dart';

class BellotaTopActions extends StatelessWidget {
  final bool showSettings;
  final bool showNotifications;
  final bool showHelp;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onLanguagePressed;
  final VoidCallback? onTalkBackPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onHelpPressed;

  const BellotaTopActions({
    super.key,
    this.showSettings = false,
    this.showNotifications = false,
    this.showHelp = false,
    this.onSettingsPressed,
    this.onLanguagePressed,
    this.onTalkBackPressed,
    this.onNotificationPressed,
    this.onHelpPressed,
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
            tooltip: 'Configuración',
            backgroundColor: Theme.of(context).bellotaColors.blanco,
            iconColor: Theme.of(context).bellotaColors.textoDark,
            onPressed: onSettingsPressed ?? () {},
          ),
          SizedBox(width: 6),
        ],



        // 3. Botón de Ayuda RPG
        if (showHelp)
          _buildCircleButton(
            icon: Icons.help_outline_rounded,
            tooltip: 'Ayuda',
            backgroundColor: Theme.of(context).bellotaColors.chilero,
            iconColor: Theme.of(context).bellotaColors.blanco,
            onPressed: onHelpPressed ?? () {},
          ),

        // 4. Botón de Notificaciones (Solo en el Dashboard)
        if (showNotifications) ...[
          SizedBox(width: 6),
          _buildCircleButton(
            icon: Icons.notifications_outlined,
            tooltip: 'Notificaciones',
            backgroundColor: Theme.of(context).bellotaColors.blanco,
            iconColor: Theme.of(context).bellotaColors.textoDark,
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
    String? tooltip,
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    Widget button = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: child ?? Icon(icon, color: iconColor, size: 20),
        onPressed: onPressed,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}

