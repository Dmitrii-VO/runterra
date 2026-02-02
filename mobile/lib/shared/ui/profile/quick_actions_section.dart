import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../navigation/user_action.dart';
import '../../navigation/navigation_handler.dart';

/// Секция быстрых действий (CTA)
/// 
/// Отображает кнопки для быстрого доступа к ключевым функциям:
/// - Открыть карту (большая, основная)
/// - Найти тренировку
/// - Начать пробежку / Check-in
/// - Найти клуб / Создать клуб — только если !hasClub && !isMercenary (явная логика).
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
    final router = GoRouter.of(context);
    final handler = NavigationHandler(router: router);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Основная кнопка - Открыть карту
            ElevatedButton.icon(
              onPressed: () => handler.handle(const OpenMapAction()),
              icon: const Icon(Icons.map),
              label: Text(AppLocalizations.of(context)!.quickOpenMap),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            // Вторичные действия
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => handler.handle(const FindTrainingAction()),
                  icon: const Icon(Icons.search),
                  label: Text(AppLocalizations.of(context)!.quickFindTraining),
                ),
                OutlinedButton.icon(
                  onPressed: () => handler.handle(const StartRunAction()),
                  icon: const Icon(Icons.directions_run),
                  label: Text(AppLocalizations.of(context)!.quickStartRun),
                ),
                if (!hasClub && !isMercenary) ...[
                  OutlinedButton.icon(
                    onPressed: () => handler.handle(const FindClubAction()),
                    icon: const Icon(Icons.group),
                    label: Text(AppLocalizations.of(context)!.quickFindClub),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => handler.handle(const CreateClubAction()),
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.quickCreateClub),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
