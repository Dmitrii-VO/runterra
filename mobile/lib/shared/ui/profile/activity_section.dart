import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/profile_activity_model.dart';
import '../../navigation/navigation_handler.dart';
import '../../navigation/user_action.dart';
import 'package:go_router/go_router.dart';

/// Секция активностей
/// 
/// Отображает:
/// - Ближайшую активность (тренировку)
/// - Последнюю активность
/// 
/// TODO: Add i18n/l10n support - all hardcoded strings (status labels, result labels) should be localized
class ProfileActivitySection extends StatelessWidget {
  final ProfileActivityModel? nextActivity;
  final ProfileActivityModel? lastActivity;

  const ProfileActivitySection({
    super.key,
    this.nextActivity,
    this.lastActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ближайшая активность
        if (nextActivity != null)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ближайшая тренировка',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nextActivity!.name ?? 'Тренировка',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (nextActivity!.dateTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(nextActivity!.dateTime!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusChip(
                        status: nextActivity!.status,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          final router = GoRouter.of(context);
                          final handler = NavigationHandler(router: router);
                          handler.handle(const OpenMapAction());
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('Открыть на карте'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        // Последняя активность
        if (lastActivity != null)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Последняя активность',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lastActivity!.name ?? 'Активность',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (lastActivity!.result != null) ...[
                    const SizedBox(height: 8),
                    _ResultChip(result: lastActivity!.result!),
                  ],
                  if (lastActivity!.message != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      lastActivity!.message!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      // TODO: Add i18n/l10n support for date formatting
      final dateFormat = DateFormat('d.M.y H:mm');
      return dateFormat.format(dateTime);
    } catch (e) {
      return isoString;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (status) {
      case 'planned':
        label = 'Записан';
        color = Colors.blue;
        break;
      case 'in_progress':
        label = 'В процессе';
        color = Colors.orange;
        break;
      case 'completed':
        label = 'Завершено';
        color = Colors.green;
        break;
      case 'cancelled':
        label = 'Отменено';
        color = Colors.grey;
        break;
      default:
        label = status;
        color = Colors.grey;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color, fontSize: 12),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String result;

  const _ResultChip({required this.result});

  @override
  Widget build(BuildContext context) {
    final isCounted = result == 'counted';
    return Chip(
      label: Text(isCounted ? 'Засчитано' : 'Не засчитано'),
      backgroundColor: isCounted
          ? const Color.fromRGBO(76, 175, 80, 0.1) // Colors.green
          : const Color.fromRGBO(244, 67, 54, 0.1), // Colors.red
      labelStyle: TextStyle(
        color: isCounted ? Colors.green : Colors.red,
        fontSize: 12,
      ),
    );
  }
}
