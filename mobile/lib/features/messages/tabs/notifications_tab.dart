import 'package:flutter/material.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/ui/notification_item.dart';

/// Tab "Уведомления" (system messages / in-app inbox).
///
/// Displays read-only list of system notifications.
/// Stub: fetches empty list. TODO: replace with API (e.g. GET /api/notifications or profile).
///
/// TODO: Navigate to screen (map / club / workout) on tap.
/// TODO: Mark as read.
class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  /// Cached future for notifications to avoid repeated HTTP calls on rebuilds.
  late final Future<List<NotificationModel>> _notificationsFuture;

  Future<List<NotificationModel>> _fetchNotifications() async {
    // Stub: no API. Same pattern as other tabs.
    return [];
  }

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationModel>>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Ошибка загрузки уведомлений: ${snapshot.error}',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Нет уведомлений',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final notifications = snapshot.data!;
        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final n = notifications[index];
            return NotificationItem(
              notification: n,
              onTap: () {
                // TODO: Navigate to screen (map / club / workout).
              },
            );
          },
        );
      },
    );
  }
}
