import 'package:flutter/material.dart';
import '../../models/profile_model.dart';

/// Profile header section
///
/// Displays user identity: avatar, full name, city.
class ProfileHeaderSection extends StatelessWidget {
  final ProfileUserData user;

  const ProfileHeaderSection({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = _getDisplayName();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  // City
                  if (user.cityName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.cityName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayName() {
    final parts = <String>[];
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      parts.add(user.firstName!);
    }
    if (user.lastName != null && user.lastName!.isNotEmpty) {
      parts.add(user.lastName!);
    }
    if (parts.isNotEmpty) return parts.join(' ');
    return user.name;
  }
}
