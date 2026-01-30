import 'package:flutter/material.dart';
import '../../navigation/user_action.dart';

/// UI-компонент для отображения элемента списка чата клуба
/// 
/// Простой StatelessWidget без логики и состояний.
/// Принимает данные через конструктор и отображает их.
/// 
/// Использование:
/// ```dart
/// ClubChatListItem(
///   clubId: 'club-123',
///   clubName: 'Клуб бегунов',
///   lastMessageText: 'Новая тренировка завтра!',
///   lastMessageAt: DateTime.now(),
///   onAction: (action) => print('Action: $action'),
/// )
/// ```
class ClubChatListItem extends StatelessWidget {
  /// ID клуба (используется для навигации)
  final String clubId;

  /// Название клуба
  final String? clubName;

  /// Описание клуба (опционально)
  final String? clubDescription;

  /// Логотип клуба (URL или путь к изображению)
  /// 
  /// TODO: Реализовать загрузку и отображение логотипа
  final String? clubLogo;

  /// Текст последнего сообщения (preview)
  final String? lastMessageText;

  /// Дата и время последнего сообщения
  final DateTime? lastMessageAt;

  /// Callback для обработки действий пользователя (intent-based navigation)
  final void Function(UserAction)? onAction;

  const ClubChatListItem({
    super.key,
    required this.clubId,
    this.clubName,
    this.clubDescription,
    this.clubLogo,
    this.lastMessageText,
    this.lastMessageAt,
    this.onAction,
  });

  /// Форматирует дату последнего сообщения для отображения
  /// 
  /// TODO: Реализовать форматирование (сегодня, вчера, дата)
  String _formatLastMessageDate(DateTime? date) {
    if (date == null) return '';
    // TODO: Реализовать форматирование даты
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        // TODO: Загружать и отображать логотип из clubLogo
        child: Text(
          clubName != null && clubName!.isNotEmpty
              ? clubName![0].toUpperCase()
              : '?',
        ),
      ),
      title: Text(
        clubName ?? 'Неизвестный клуб',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (clubDescription != null)
            Text(
              clubDescription!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (lastMessageText != null)
            Text(
              lastMessageText!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            const Text('Нет сообщений'),
        ],
      ),
      trailing: lastMessageAt != null
          ? Text(
              _formatLastMessageDate(lastMessageAt),
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: () {
        // TODO: Реализовать навигацию к экрану чата клуба
        // onAction?.call(SelectClubChatAction(clubId: clubId));
      },
    );
  }
}
