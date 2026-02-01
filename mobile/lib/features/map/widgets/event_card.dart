import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/event_list_item_model.dart';

/// Карточка события для отображения на карте
/// 
/// Показывается при тапе на маркер события.
/// Содержит: когда, где, организатор, кнопка "Присоединиться".
class EventCard extends StatelessWidget {
  final EventListItemModel event;

  const EventCard({
    super.key,
    required this.event,
  });

  /// Получает иконку по типу события
  IconData _getEventIcon(String type) {
    switch (type) {
      case 'training':
        return Icons.directions_run;
      case 'group_run':
        return Icons.group;
      case 'club_event':
        return Icons.event;
      case 'open_event':
        return Icons.public;
      default:
        return Icons.event;
    }
  }

  /// Получает цвет по типу события
  Color _getEventColor(String type) {
    switch (type) {
      case 'training':
        return Colors.blue;
      case 'group_run':
        return Colors.green;
      case 'club_event':
        return Colors.orange;
      case 'open_event':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM, HH:mm');
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с иконкой
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getEventColor(event.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getEventIcon(event.type),
                  color: _getEventColor(event.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Когда
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(event.startDateTime),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Где
          if (event.locationName != null)
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.locationName!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          
          // Организатор
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                event.organizerType == 'club'
                    ? 'Клуб: ${event.organizerId}'
                    : 'Тренер: ${event.organizerId}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Кнопка "Присоединиться"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push('/event/${event.id}');
              },
              child: const Text('Присоединиться'),
            ),
          ),
        ],
      ),
    );
  }
}
