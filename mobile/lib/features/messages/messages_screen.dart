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
/// [initialTabIndex] — индекс вкладки при открытии (0 — Личные, 1 — Клуб, 2 — Тренер).
/// Передаётся из маршрута, например /messages?tab=club → initialTabIndex: 1.
class MessagesScreen extends StatelessWidget {
  /// Индекс начальной вкладки (0/1/2). По умолчанию 0.
  final int initialTabIndex;

  const MessagesScreen({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    final index = initialTabIndex.clamp(0, 2);
    return DefaultTabController(
      initialIndex: index,
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
