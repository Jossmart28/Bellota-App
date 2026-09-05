import 'package:flutter/material.dart';
import '../theme/bellota_colors.dart';
import '../l10n/language_notifier.dart';

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
            tooltip: 'Configuración',
            backgroundColor: Theme.of(context).bellotaColors.blanco,
            iconColor: Theme.of(context).bellotaColors.textoDark,
            onPressed: onSettingsPressed ?? () {},
          ),
          SizedBox(width: 6),
        ],

        // 2. Botón de Idioma (Va en todas)
        _buildCircleButton(
          tooltip: 'Cambiar idioma',
          child: ValueListenableBuilder<String>(
            valueListenable: languageNotifier,
            builder: (context, lang, _) {
              return Text(
                lang.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).bellotaColors.textoDark,
                ),
              );
            }
          ),
          backgroundColor: Theme.of(context).bellotaColors.blanco,
          onPressed: () {
            languageNotifier.toggle();
            if (onLanguagePressed != null) {
              onLanguagePressed!();
            }
          },
        ),
        SizedBox(width: 6),

        // 3. Botón de TalkBack / Audio (Va en todas)
        _buildCircleButton(
          icon: Icons.volume_up_rounded,
          tooltip: 'Audio y Accesibilidad',
          backgroundColor: Theme.of(context).bellotaColors.chilero,
          iconColor: Theme.of(context).bellotaColors.blanco,
          onPressed: onTalkBackPressed ?? () {},
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
      width: 48,
      height: 48,
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
        icon: child ?? Icon(icon, color: iconColor, size: 24),
        onPressed: onPressed,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }
}
