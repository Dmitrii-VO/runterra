import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../notification_item.dart';

/// Секция уведомлений
/// 
/// Отображает простой список последних уведомлений.
/// MVP: без центра уведомлений и фильтров.
class ProfileNotificationsSection extends StatelessWidget {
  final List<NotificationModel> notifications;

  const ProfileNotificationsSection({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Уведомления',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...notifications.take(5).map((notification) => NotificationItem(
                  notification: notification,
                )),
          ],
        ),
      ),
    );
  }
}
