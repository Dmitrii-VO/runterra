import 'package:flutter/material.dart';
import '../../navigation/user_action.dart';

/// UI-компонент для отображения элемента списка личного чата
/// 
/// Простой StatelessWidget без логики и состояний.
/// Принимает данные через конструктор и отображает их.
/// 
/// Использование:
/// ```dart
/// ChatListItem(
///   chatId: 'chat-123',
///   otherUserName: 'Иван Иванов',
///   lastMessageText: 'Привет! Как дела?',
///   lastMessageAt: DateTime.now(),
///   onAction: (action) => print('Action: $action'),
/// )
/// ```
class ChatListItem extends StatelessWidget {
  /// ID чата (используется для навигации)
  final String chatId;

  /// Имя собеседника
  final String? otherUserName;

  /// Аватар собеседника (URL или путь к изображению)
  /// 
  /// TODO: Реализовать загрузку и отображение аватара
  final String? otherUserAvatar;

  /// Текст последнего сообщения (preview)
  final String? lastMessageText;

  /// Дата и время последнего сообщения
  final DateTime? lastMessageAt;

  /// Callback для обработки действий пользователя (intent-based navigation)
  final void Function(UserAction)? onAction;

  const ChatListItem({
    super.key,
    required this.chatId,
    this.otherUserName,
    this.otherUserAvatar,
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
        // TODO: Загружать и отображать аватар из otherUserAvatar
        child: Text(
          otherUserName != null && otherUserName!.isNotEmpty
              ? otherUserName![0].toUpperCase()
              : '?',
        ),
      ),
      title: Text(
        otherUserName ?? 'Неизвестный пользователь',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: lastMessageText != null
          ? Text(
              lastMessageText!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : const Text('Нет сообщений'),
      trailing: lastMessageAt != null
          ? Text(
              _formatLastMessageDate(lastMessageAt),
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: () {
        // TODO: Реализовать навигацию к экрану чата
        // onAction?.call(SelectChatAction(chatId: chatId));
      },
    );
  }
}
