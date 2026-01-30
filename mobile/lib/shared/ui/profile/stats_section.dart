import 'package:flutter/material.dart';
import '../../models/user_stats_model.dart';

/// Секция мини-статистики
/// 
/// Отображает 3 карточки с ключевыми метриками:
/// - Количество участий в тренировках
/// - Территории, в захвате которых участвовал
/// - Баллы личного вклада
class ProfileStatsSection extends StatelessWidget {
  final UserStatsModel stats;

  const ProfileStatsSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatCard(
              icon: Icons.check_circle,
              label: 'Тренировки',
              value: stats.trainingCount.toString(),
            ),
            _StatCard(
              icon: Icons.map,
              label: 'Территории',
              value: stats.territoriesParticipated.toString(),
            ),
            _StatCard(
              icon: Icons.star,
              label: 'Баллы',
              value: stats.contributionPoints.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
