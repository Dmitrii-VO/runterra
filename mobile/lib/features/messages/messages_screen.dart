import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'tabs/personal_chats_tab.dart';
import 'tabs/club_messages_tab.dart';

/// Messages screen — 2 tabs: Personal DMs and Club chats.
///
/// [initialTabIndex] — 0 = Личные, 1 = Клубы.
/// [initialClubId] — when set on tab 1, pre-selects that club.
class MessagesScreen extends StatelessWidget {
  final int initialTabIndex;
  final String? initialClubId;

  const MessagesScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialClubId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final index = initialTabIndex.clamp(0, 1);
    return DefaultTabController(
      initialIndex: index,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.messagesTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabPersonal),
              Tab(text: l10n.tabClubs),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const PersonalChatsTab(),
            ClubMessagesTab(initialClubId: initialClubId),
          ],
        ),
      ),
    );
  }
}
