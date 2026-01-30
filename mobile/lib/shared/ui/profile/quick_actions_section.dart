import 'package:flutter/material.dart';
import '../../navigation/user_action.dart';
import '../../navigation/navigation_handler.dart';
import 'package:go_router/go_router.dart';

/// Секция быстрых действий (CTA)
/// 
/// Отображает кнопки для быстрого доступа к ключевым функциям:
/// - Открыть карту (большая, основная)
/// - Найти тренировку
/// - Начать пробежку / Check-in
/// - Найти клуб / Создать клуб — только если !hasClub && !isMercantile (явная логика).
class ProfileQuickActionsSection extends StatelessWidget {
  /// true если profile.club != null
  final bool hasClub;
  final bool isMercantile;

  const ProfileQuickActionsSection({
    super.key,
    required this.hasClub,
    required this.isMercantile,
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
              label: const Text('Открыть карту'),
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
                  label: const Text('Найти тренировку'),
                ),
                OutlinedButton.icon(
                  onPressed: () => handler.handle(const StartRunAction()),
                  icon: const Icon(Icons.directions_run),
                  label: const Text('Начать пробежку'),
                ),
                // Действия для пользователей без клуба
                if (!hasClub && !isMercantile) ...[
                  OutlinedButton.icon(
                    onPressed: () => handler.handle(const FindClubAction()),
                    icon: const Icon(Icons.group),
                    label: const Text('Найти клуб'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => handler.handle(const CreateClubAction()),
                    icon: const Icon(Icons.add),
                    label: const Text('Создать клуб'),
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
