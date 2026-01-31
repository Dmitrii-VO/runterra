import 'package:flutter/material.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/ui/list_items/message_list_item.dart';

/// Tab "Город" — общий (городской) чат.
///
/// Отображает список сообщений общего чата.
/// Минимальная реализация без state management, использует FutureBuilder.
///
/// TODO: Реализовать отправку сообщений
/// TODO: Реализовать обновление сообщений в реальном времени
/// TODO: Добавить пагинацию для загрузки старых сообщений
class GlobalChatTab extends StatefulWidget {
  const GlobalChatTab({super.key});

  @override
  State<GlobalChatTab> createState() => _GlobalChatTabState();
}

class _GlobalChatTabState extends State<GlobalChatTab> {
  /// Future for global chat messages.
  late Future<List<MessageModel>> _messagesFuture;

  /// Создает Future для получения сообщений общего чата
  Future<List<MessageModel>> _fetchMessages() async {
    return ServiceLocator.messagesService.getGlobalChatMessages();
  }
  
  /// Reload messages
  void _retry() {
    setState(() {
      _messagesFuture = _fetchMessages();
    });
  }

  @override
  void initState() {
    super.initState();
    _messagesFuture = _fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MessageModel>>(
      future: _messagesFuture,
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
                    'Ошибка загрузки сообщений: ${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
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
                'Пока тихо. Напиши первое сообщение и задай ритм городу 🏃‍♂️',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Отображаем список сообщений (новые сверху)
        final messages = snapshot.data!;
        return ListView.builder(
          reverse: true, // Новые сообщения внизу
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return MessageListItem(
              messageText: message.text,
              userName: message.userName,
              createdAt: message.createdAt,
            );
          },
        );
      },
    );
  }
}
