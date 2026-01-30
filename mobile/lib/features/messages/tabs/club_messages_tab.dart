import 'package:flutter/material.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/club_chat_model.dart';
import '../../../shared/ui/list_items/club_chat_list_item.dart';

/// Tab "Клубы" — список чатов клубов.
///
/// Отображает чаты клубов, в которых состоит пользователь.
/// Минимальная реализация без state management, использует FutureBuilder.
///
/// TODO: Реализовать навигацию к экрану чата клуба
/// TODO: Реализовать обновление списка чатов в реальном времени
/// TODO: Добавить индикатор непрочитанных сообщений
/// TODO: Добавить фильтрацию по клубам, в которых состоит пользователь
class ClubMessagesTab extends StatefulWidget {
  const ClubMessagesTab({super.key});

  @override
  State<ClubMessagesTab> createState() => _ClubMessagesTabState();
}

class _ClubMessagesTabState extends State<ClubMessagesTab> {
  /// Cached future for club chats to avoid repeated HTTP calls on rebuilds.
  late final Future<List<ClubChatModel>> _clubChatsFuture;

  /// Создает Future для получения списка чатов клубов
  ///
  /// TODO: Backend API для сообщений еще не реализован.
  /// Метод возвращает пустой список (заглушка).
  Future<List<ClubChatModel>> _fetchClubChats() async {
    return ServiceLocator.messagesService.getClubChats();
  }

  @override
  void initState() {
    super.initState();
    _clubChatsFuture = _fetchClubChats();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ClubChatModel>>(
      future: _clubChatsFuture,
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
                'Ошибка загрузки чатов клубов: ${snapshot.error}',
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
                'Нет чатов клубов\n\nВы пока не состоите ни в одном клубе',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Отображаем список чатов клубов
        final clubChats = snapshot.data!;
        return ListView.builder(
          itemCount: clubChats.length,
          itemBuilder: (context, index) {
            final clubChat = clubChats[index];
            return ClubChatListItem(
              clubId: clubChat.clubId,
              clubName: clubChat.clubName,
              clubDescription: clubChat.clubDescription,
              clubLogo: clubChat.clubLogo,
              lastMessageText: clubChat.lastMessageText,
              lastMessageAt: clubChat.lastMessageAt,
            );
          },
        );
      },
    );
  }
}
