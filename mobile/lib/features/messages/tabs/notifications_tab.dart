import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
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
  /// Future for notifications.
  late Future<List<NotificationModel>> _notificationsFuture;

  Future<List<NotificationModel>> _fetchNotifications() async {
    // Stub: no API. Same pattern as other tabs.
    return [];
  }
  
  /// Reload data
  void _retry() {
    setState(() {
      _notificationsFuture = _fetchNotifications();
    });
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.notificationsLoadError(snapshot.error.toString()),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)!.noNotifications,
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
