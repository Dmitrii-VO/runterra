import 'package:flutter/material.dart';

/// UI-компонент для отображения элемента сообщения в списке
/// 
/// Простой StatelessWidget без логики и состояний.
/// Принимает данные через конструктор и отображает их.
/// 
/// Использование:
/// ```dart
/// MessageListItem(
///   messageText: 'Привет! Как дела?',
///   userName: 'Иван Иванов',
///   createdAt: DateTime.now(),
/// )
/// ```
class MessageListItem extends StatelessWidget {
  /// Текст сообщения
  final String messageText;

  /// Имя пользователя, отправившего сообщение
  final String? userName;

  /// Дата и время создания сообщения
  final DateTime createdAt;

  /// Аватар пользователя (URL или путь к изображению)
  /// 
  /// TODO: Реализовать загрузку и отображение аватара
  final String? userAvatar;

  const MessageListItem({
    super.key,
    required this.messageText,
    this.userName,
    required this.createdAt,
    this.userAvatar,
  });

  /// Форматирует дату сообщения для отображения
  /// 
  /// TODO: Реализовать форматирование (сегодня, вчера, дата)
  String _formatMessageDate(DateTime date) {
    // TODO: Реализовать форматирование даты
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аватар пользователя
          CircleAvatar(
            radius: 20,
            // TODO: Загружать и отображать аватар из userAvatar
            child: Text(
              userName != null && userName!.isNotEmpty
                  ? userName![0].toUpperCase()
                  : '?',
            ),
          ),
          const SizedBox(width: 12),
          // Контент сообщения
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Имя пользователя и время
                Row(
                  children: [
                    if (userName != null)
                      Text(
                        userName!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      _formatMessageDate(createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Текст сообщения
                Text(
                  messageText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
