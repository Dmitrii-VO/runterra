import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../models/profile_model.dart';
import '../../models/profile_club_model.dart';

/// Секция заголовка профиля
/// 
/// Отображает основную информацию о пользователе:
/// - Имя / ник
/// - Фото профиля (опционально)
/// - Статус (участник клуба / меркатель)
/// - Название клуба (если состоит)
/// - Роль в клубе (если в клубе)
class ProfileHeaderSection extends StatelessWidget {
  final ProfileUserData user;
  final ProfileClubModel? club;

  const ProfileHeaderSection({
    super.key,
    required this.user,
    this.club,
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
            // Фото профиля
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
            // Информация о пользователе
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Имя
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  // Статус и клуб. Явная логика: club != null | isMercenary | иначе "Без клуба"
                  if (club != null) ...[
                    Text(
                      club!.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getRoleText(context, club!.role),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ] else if (user.isMercenary) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.headerMercenary,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ] else ...[
                    // club == null && !isMercenary — явный edge-case
                    Text(
                      AppLocalizations.of(context)!.headerNoClub,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                  // Город
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

  String _getRoleText(BuildContext context, String role) {
    final l10n = AppLocalizations.of(context)!;
    switch (role) {
      case 'member':
        return l10n.roleMember;
      case 'moderator':
        return l10n.roleModerator;
      case 'leader':
        return l10n.roleLeader;
      default:
        return role;
    }
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
