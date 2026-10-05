import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../theme/bellota_colors.dart';
import '../core/services/notification_service.dart';

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
        _pendingNotifications = pending;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<BellotaColors>() ?? BellotaColors.light;

    return Scaffold(
      backgroundColor: colors.blanco,
      appBar: AppBar(
        backgroundColor: colors.blanco,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textoDark),
        title: Text(
          'Mis Notificaciones',
          style: TextStyle(
            color: colors.textoDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _pendingNotifications == null
          // Loading state
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: colors.chilero,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando notificaciones...',
                    style: TextStyle(
                      color: colors.textoMedio,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _pendingNotifications!.isEmpty
              // Empty state
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded,
                          size: 64, color: colors.melon.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'Sin notificaciones programadas',
                        style: TextStyle(
                          color: colors.textoMedio,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Actívalas en Recordatorios y Notificaciones',
                        style: TextStyle(
                          color: colors.textoMedio.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              // List state
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _pendingNotifications!.length,
                  itemBuilder: (context, index) {
                    final notif = _pendingNotifications![index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.nancite.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: colors.melon.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.blanco,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.notifications_active_rounded,
                                color: colors.chilero, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif.title ?? 'Notificación',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: colors.textoDark,
                                  ),
                                ),
                                if (notif.body != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.body!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textoMedio,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
