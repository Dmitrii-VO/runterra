import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/event_details_model.dart';
import '../../shared/ui/details_scaffold.dart';
import '../../shared/ui/error_display.dart';
import 'widgets/participants_list.dart';

/// Экран деталей события
///
/// Отображает полную информацию о событии:
/// - основная информация
/// - описание
/// - точка старта на карте (placeholder)
/// - организатор
/// - участие (кнопки - TODO)
/// - список участников
/// - check-in секция (TODO)
/// 
/// TODO: Add i18n/l10n support - all hardcoded strings (event types, statuses, labels) should be localized
class EventDetailsScreen extends StatefulWidget {
  /// ID события (передается через параметр маршрута)
  final String eventId;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
  });

  /// Создает Future для получения данных о событии
  /// 
  /// Загружает данные по eventId через EventsService.
  /// Это обеспечивает loose coupling между списком и детальным экраном.
  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  /// Future for event details.
  late Future<EventDetailsModel> _eventFuture;

  /// Creates Future for loading event data.
  Future<EventDetailsModel> _fetchEvent() async {
    return ServiceLocator.eventsService.getEventById(widget.eventId);
  }
  
  /// Reload data
  void _retry() {
    setState(() {
      _eventFuture = _fetchEvent();
    });
  }

  @override
  void initState() {
    super.initState();
    _eventFuture = _fetchEvent();
  }

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
    return DetailsScaffold(
      title: 'Событие',
      body: FutureBuilder<EventDetailsModel>(
        future: _eventFuture,
        builder: (context, snapshot) {
          // Состояние загрузки
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Состояние ошибки
          if (snapshot.hasError) {
            return ErrorDisplay(
              errorMessage: snapshot.error.toString(),
              onRetry: _retry,
            );
          }

          // Состояние успеха - отображение данных события
          if (snapshot.hasData) {
            final event = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название события
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    // Статус
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: event.status == 'open'
                            ? const Color.fromRGBO(76, 175, 80, 0.2) // Colors.green
                            : event.status == 'cancelled'
                                ? const Color.fromRGBO(244, 67, 54, 0.2) // Colors.red
                                : const Color.fromRGBO(158, 158, 158, 0.2), // Colors.grey
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(event.status),
                        style: TextStyle(
                          color: event.status == 'open'
                              ? Colors.green
                              : event.status == 'cancelled'
                                  ? Colors.red
                                  : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Описание
                    if (event.description != null) ...[
                      Text(
                        'Описание',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Основная информация
                    Text(
                      'Информация',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    // Тип события
                    _buildInfoRow(
                      context,
                      Icons.event,
                      'Тип',
                      _getEventTypeText(event.type),
                    ),
                    
                    // Дата и время
                    _buildInfoRow(
                      context,
                      Icons.access_time,
                      'Дата и время',
                      _formatDateTime(event.startDateTime),
                    ),
                    
                    // Локация
                    if (event.locationName != null)
                      _buildInfoRow(
                        context,
                        Icons.location_on,
                        'Локация',
                        event.locationName!,
                      ),
                    
                    // Организатор
                    _buildInfoRow(
                      context,
                      event.organizerType == 'club' ? Icons.group : Icons.person,
                      'Организатор',
                      event.organizerId, // TODO: Получить название клуба/тренера
                      onTap: () {
                        // TODO: Переход на профиль клуба/тренера
                        if (event.organizerType == 'club') {
                          context.push('/club/${event.organizerId}');
                        }
                      },
                    ),
                    
                    // Уровень подготовки
                    if (event.difficultyLevel != null)
                      _buildInfoRow(
                        context,
                        Icons.trending_up,
                        'Уровень подготовки',
                        _getDifficultyText(event.difficultyLevel)!,
                      ),
                    
                    // Территория
                    if (event.territoryId != null)
                      _buildInfoRow(
                        context,
                        Icons.map,
                        'Территория',
                        'Привязано к территории', // TODO: Получить название территории
                        onTap: () {
                          // TODO: Переход на детальный экран территории
                          context.push('/territory/${event.territoryId}');
                        },
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Точка старта на карте (placeholder)
                    Text(
                      'Точка старта',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'Карта (TODO: Mapbox)',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '${event.startLocation.latitude}, ${event.startLocation.longitude}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Участие
                    Text(
                      'Участие',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    // Кнопка участия
                    if (event.status == 'open')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Реализовать запись на событие
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Запись на событие - TODO'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Присоединиться'),
                        ),
                      )
                    else if (event.status == 'full')
                      const SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: null,
                          child: Text('Нет свободных мест'),
                        ),
                      )
                    else if (event.status == 'cancelled')
                      const SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: null,
                          child: Text('Событие отменено'),
                        ),
                      ),
                    
                    // TODO: Кнопка "Вы записаны" если пользователь уже записан
                    
                    const SizedBox(height: 24),
                    
                    // Check-in секция (TODO: показывается за 15 минут до старта)
                    // TODO: Проверить время и показать секцию check-in
                    
                    // Список участников
                    ParticipantsList(participantCount: event.participantCount),
                  ],
                ),
              ),
            );
          }

          // Fallback
          return const Center(
            child: Text('Нет данных'),
          );
        },
      ),
    );
  }

  /// Строит строку информации
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onTap != null ? Colors.blue : null,
                      decoration: onTap != null ? TextDecoration.underline : null,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
