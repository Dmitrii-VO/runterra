import 'package:flutter/material.dart';
import '../../navigation/user_action.dart';

/// UI-компонент для отображения элемента списка клуба
/// 
/// Простой StatelessWidget без логики и состояний.
/// Принимает данные через конструктор и отображает их.
/// 
/// Использование:
/// ```dart
/// ClubListItem(
///   clubId: 'club-123',
///   clubName: 'Клуб бегунов',
///   description: 'Описание клуба',
///   status: 'active',
///   onAction: (action) => print('Action: $action'),
/// )
/// ```
class ClubListItem extends StatelessWidget {
  /// ID клуба (используется для навигации)
  final String clubId;

  /// Название клуба
  final String clubName;

  /// Описание клуба (опционально)
  final String? description;

  /// Статус клуба
  final String status;

  /// Callback для обработки действий пользователя (intent-based navigation)
  final void Function(UserAction)? onAction;

  const ClubListItem({
    super.key,
    required this.clubId,
    required this.clubName,
    this.description,
    required this.status,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        clubName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: description != null
          ? Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        onAction?.call(SelectClubAction(clubId: clubId));
      },
    );
  }
}
