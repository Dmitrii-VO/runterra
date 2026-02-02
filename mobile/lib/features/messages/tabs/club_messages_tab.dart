import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
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
  /// Future for club chats.
  late Future<List<ClubChatModel>> _clubChatsFuture;

  /// Создает Future для получения списка чатов клубов
  Future<List<ClubChatModel>> _fetchClubChats() async {
    return ServiceLocator.messagesService.getClubChats();
  }
  
  /// Reload data
  void _retry() {
    setState(() {
      _clubChatsFuture = _fetchClubChats();
    });
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.clubChatsLoadError(snapshot.error.toString()),
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
                AppLocalizations.of(context)!.noClubChats,
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
