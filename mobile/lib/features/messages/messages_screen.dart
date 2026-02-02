import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'tabs/global_chat_tab.dart';
import 'tabs/club_messages_tab.dart';
import 'tabs/notifications_tab.dart';

/// Messages screen
///
/// Экран сообщений с тремя вкладками (MVP по 123.md):
/// - Город (общий чат)
/// - Клубы (чаты клубов)
/// - Уведомления (системные сообщения, read-only)
///
/// Использует TabBar для переключения.
/// Минимальная реализация без state management.
///
/// TODO: Реализовать отправку сообщений
/// TODO: Реализовать обновление в реальном времени
/// TODO: Добавить навигацию к экранам конкретных чатов
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.messagesTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.tabCity),
              Tab(text: AppLocalizations.of(context)!.tabClubs),
              Tab(text: AppLocalizations.of(context)!.tabNotifications),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GlobalChatTab(),
            ClubMessagesTab(),
            NotificationsTab(),
          ],
        ),
      ),
    );
  }
}
