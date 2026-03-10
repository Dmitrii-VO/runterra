import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/direct_chat_model.dart';
import '../direct_chat_screen.dart';

/// Tab "Личные" — all DM conversations.
///
/// Trainers are pinned at the top with a red "Тренер" badge.
/// The "+" FAB navigates to /people to start a new conversation.
class PersonalChatsTab extends StatefulWidget {
  const PersonalChatsTab({super.key});

  @override
  State<PersonalChatsTab> createState() => _PersonalChatsTabState();
}

class _PersonalChatsTabState extends State<PersonalChatsTab> {
  late Future<List<DirectChatModel>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = ServiceLocator.messagesService.getConversations();
  }

  void _reload() {
    setState(() {
      _conversationsFuture = ServiceLocator.messagesService.getConversations();
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);
    if (msgDay == today) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    final diff = today.difference(msgDay).inDays;
    if (diff == 1) return 'Вчера';
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FutureBuilder<List<DirectChatModel>>(
      future: _conversationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final all = snapshot.data ?? [];
        // Pinned trainers first, then rest sorted by last message time
        final pinned = all.where((c) => c.isTrainerRelation).toList();
        final others = all.where((c) => !c.isTrainerRelation).toList();
        final sorted = [...pinned, ...others];

        return Scaffold(
          body: sorted.isEmpty
              ? RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.personalChatsEmpty,
                                  style: theme.textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => context.push('/people'),
                                  icon: const Icon(Icons.person_search),
                                  label: Text(l10n.personalChatsNewChat),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, index) {
                      final chat = sorted[index];
                      return _ConversationTile(
                        chat: chat,
                        formatTime: _formatTime,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DirectChatScreen(
                                otherUser: chat,
                                isTrainer: chat.isTrainerRelation,
                              ),
                            ),
                          );
                          _reload();
                        },
                      );
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/people'),
            tooltip: l10n.personalChatsNewChat,
            child: const Icon(Icons.edit),
          ),
        );
      },
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.chat,
    required this.formatTime,
    required this.onTap,
  });

  final DirectChatModel chat;
  final String Function(DateTime) formatTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials =
        chat.userName.isNotEmpty ? chat.userName[0].toUpperCase() : '?';

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 24,
        backgroundImage:
            chat.userAvatar != null ? NetworkImage(chat.userAvatar!) : null,
        child: chat.userAvatar == null ? Text(initials) : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              chat.userName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (chat.isTrainerRelation) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalizations.of(context)!.trainerBadge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: chat.lastMessageText != null
          ? Text(
              chat.lastMessageText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            )
          : null,
      trailing: chat.lastMessageAt != null
          ? Text(
              formatTime(chat.lastMessageAt!),
              style:
                  theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
            )
          : null,
    );
  }
}
