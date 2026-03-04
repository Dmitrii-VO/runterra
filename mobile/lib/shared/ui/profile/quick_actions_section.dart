import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../navigation/user_action.dart';
import '../../navigation/navigation_handler.dart';
import 'package:go_router/go_router.dart';

/// Секция быстрых действий (CTA) — только для новых пользователей без клуба.
///
/// Показывает "Найти клуб" и "Создать клуб".
/// Скрывается если пользователь уже в клубе или является наёмником.
class ProfileQuickActionsSection extends StatelessWidget {
  /// true если profile.club != null
  final bool hasClub;
  final bool isMercenary;

  const ProfileQuickActionsSection({
    super.key,
    required this.hasClub,
    required this.isMercenary,
  });

  @override
  Widget build(BuildContext context) {
    if (hasClub || isMercenary) return const SizedBox.shrink();

    final router = GoRouter.of(context);
    final handler = NavigationHandler(router: router);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => handler.handle(const FindClubAction()),
              icon: const Icon(Icons.group),
              label: Text(l10n.quickFindClub),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => handler.handle(const CreateClubAction()),
              icon: const Icon(Icons.add),
              label: Text(l10n.quickCreateClub),
            ),
          ],
        ),
      ),
    );
  }
}
