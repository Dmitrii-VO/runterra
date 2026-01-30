import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/event_list_item_model.dart';

/// Виджет карточки события
/// 
/// Отображает основную информацию о событии в списке.
/// Только отображение данных, без интерактивности (кроме перехода на детальный экран).
/// 
/// TODO: Add i18n/l10n support - all hardcoded strings (event types, statuses) should be localized
class EventCard extends StatelessWidget {
  /// Модель события для отображения (упрощённая версия для списка)
  final EventListItemModel event;

  const EventCard({
    super.key,
    required this.event,
  });

  /// Получает текст типа события
  String _getEventTypeText(String type) {
    switch (type) {
      case 'training':
        return 'Тренировка';
      case 'group_run':
        return 'Совместный бег';
      case 'club_event':
        return 'Клубное событие';
      case 'open_event':
        return 'Открытое событие';
      default:
        return type;
    }
  }

  /// Получает цвет статуса события
  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'full':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Получает текст статуса события
  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'Открыто';
      case 'full':
        return 'Нет мест';
      case 'cancelled':
        return 'Отменено';
      case 'completed':
        return 'Завершено';
      default:
        return status;
    }
  }

  /// Получает текст уровня подготовки
  String? _getDifficultyText(String? level) {
    switch (level) {
      case 'beginner':
        return 'Новичок';
      case 'intermediate':
        return 'Любитель';
      case 'advanced':
        return 'Опытный';
      default:
        return level;
    }
  }

  /// Форматирует дату и время
  String _formatDateTime(DateTime dateTime) {
    // TODO: Add i18n/l10n support for date formatting
    final dateFormat = DateFormat('d.M.y H:mm');
    return dateFormat.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Переход на детальный экран события
          context.push('/event/${event.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с названием и статусом
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(
                        _getStatusColor(event.status).red,
                        _getStatusColor(event.status).green,
                        _getStatusColor(event.status).blue,
                        0.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(event.status),
                      style: TextStyle(
                        color: _getStatusColor(event.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Тип события
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    _getEventTypeText(event.type),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Дата и время
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(event.startDateTime),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Локация
              if (event.locationName != null)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.locationName!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              if (event.locationName != null) const SizedBox(height: 4),
              
              // Организатор
              Row(
                children: [
                  Icon(
                    event.organizerType == 'club' ? Icons.group : Icons.person,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Организатор: ${event.organizerId}', // TODO: Получить название клуба/тренера
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Уровень подготовки
              if (event.difficultyLevel != null)
                Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _getDifficultyText(event.difficultyLevel)!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              if (event.difficultyLevel != null) const SizedBox(height: 8),
              
              // Нижняя строка: участники и территория
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Количество участников
                  Row(
                    children: [
                      const Text('👥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '${event.participantCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  
                  // Привязка к территории
                  if (event.territoryId != null)
                    Row(
                      children: [
                        const Text('🗺', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          'Территория',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
