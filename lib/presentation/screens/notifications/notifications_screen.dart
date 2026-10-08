import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bellotadevelopment/presentation/theme/bellota_colors.dart';
import 'package:bellotadevelopment/core/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<PendingNotificationRequest>? _pendingNotifications;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final pending = await NotificationService.instance.getPendingNotificationRequests();
    
    if (mounted) {
      setState(() {
        // Si no hay notificaciones, agregamos unas de prueba para ver el diseño de Figma
        if (pending.isEmpty) {
          _pendingNotifications = [
            const PendingNotificationRequest(1, '¿Cómo te sientes hoy?', 'Registra tus síntomas para mejorar tus predicciones.', null),
            const PendingNotificationRequest(2, 'Estás en fase menstrual', 'Día 2 de tu ciclo. Descansa, mantente hidratada y usa calor suave si sientes cólicos.', null),
            const PendingNotificationRequest(3, 'Próximo período', 'Se estima para el 3 Nov (en 27 días).', null),
          ];
        } else {
          _pendingNotifications = pending;
        }
      });
    }
  }

  // Helper para igualar iconos y colores del diseño
  Map<String, dynamic> _getNotificationStyle(String title, BellotaColors colors) {
    title = title.toLowerCase();
    if (title.contains('síntomas') || title.contains('sientes')) {
      return {'icon': Icons.edit_rounded, 'color': colors.melon}; // Naranja
    } else if (title.contains('fase') || title.contains('menstrual')) {
      return {'icon': Icons.auto_awesome_rounded, 'color': const Color(0xFFD65C6A)}; // Rosado/Rojo claro
    } else if (title.contains('período') || title.contains('sangrado')) {
      return {'icon': Icons.water_drop_rounded, 'color': colors.chilero}; // Rojo oscuro
    }
    return {'icon': Icons.notifications_rounded, 'color': colors.asuncion}; // Azul fallback
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<BellotaColors>() ?? BellotaColors.light;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colors.basilica, // Fondo crema
      body: Stack(
        children: [
          // 1. Fondo rojo curvo superior
          _buildHeaderBackground(colors, size),
          
          // 2. Contenido principal
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón Back
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      
                      // Título
                      const Text(
                        'Notificaciones',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      
                      // Badge contador
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_pendingNotifications?.length ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Botones de acción (Marcar leídas / Limpiar)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _buildHeaderButton(
                        icon: Icons.done_all_rounded,
                        label: 'Marcar leídas',
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Limpiar',
                        onTap: () async {
                           await NotificationService.instance.cancelAll();
                           _loadNotifications();
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Lista de notificaciones con contenedor curvo
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.basilica,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: _pendingNotifications == null
                        ? Center(child: CircularProgressIndicator(color: colors.chilero))
                        : _pendingNotifications!.isEmpty
                            ? _buildEmptyState(colors)
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 40),
                                itemCount: _pendingNotifications!.length,
                                itemBuilder: (context, index) {
                                  final notif = _pendingNotifications![index];
                                  return _buildNotificationCard(
                                    title: notif.title ?? 'Notificación',
                                    body: notif.body ?? '',
                                    colors: colors,
                                    onDismiss: () async {
                                      await NotificationService.instance.cancelAll();
                                      _loadNotifications();
                                    },
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(BellotaColors colors, Size size) {
    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        height: size.height * 0.32,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFC85556), Color(0xFFBC4B4D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
        child: Stack(
          children: [
            // Círculos superpuestos del diseño
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String body,
    required BellotaColors colors,
    required VoidCallback onDismiss,
  }) {
    final style = _getNotificationStyle(title, colors);
    final badgeColor = style['color'] as Color;
    final iconData = style['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.chilero.withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: colors.chilero.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono circular con punto de no leído
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: Colors.white, size: 28),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors.chilero,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Contenido de la tarjeta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: colors.textoDark,
                        ),
                      ),
                    ),
                    Text(
                      'Hoy',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: colors.textoMedio.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        body,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          color: colors.textoMedio.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onDismiss,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Icon(Icons.close_rounded, color: colors.textoMedio.withOpacity(0.4), size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BellotaColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded,
              size: 64, color: colors.melon.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Sin notificaciones programadas',
            style: TextStyle(
              color: colors.textoMedio,
              fontSize: 16,
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width / 2, size.height + 10, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
