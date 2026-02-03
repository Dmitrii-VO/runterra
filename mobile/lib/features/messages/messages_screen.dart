import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'tabs/personal_chats_tab.dart';
import 'tabs/club_messages_tab.dart';
import 'tabs/coach_tab.dart';

/// Messages screen
///
/// Экран сообщений с тремя вкладками:
/// - Личные (заглушка)
/// - Клуб (чаты клубов)
/// - Тренер (заглушка)
///
/// Использует TabBar для переключения.
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
              Tab(text: AppLocalizations.of(context)!.tabPersonal),
              Tab(text: AppLocalizations.of(context)!.tabClub),
              Tab(text: AppLocalizations.of(context)!.tabCoach),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PersonalChatsTab(),
            ClubMessagesTab(),
            CoachTab(),
          ],
        ),
      ),
    );
  }
}
