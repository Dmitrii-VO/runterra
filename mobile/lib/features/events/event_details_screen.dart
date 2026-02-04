import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
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
  /// True while join/check-in request is in progress.
  bool _isJoining = false;

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

  /// Join event and refresh on success; show SnackBar on error.
  Future<void> _onJoinEvent() async {
    if (_isJoining) return;
    setState(() => _isJoining = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ServiceLocator.eventsService.joinEvent(widget.eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventJoinSuccess)),
      );
      _retry();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventJoinError(e.message))),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _eventFuture = _fetchEvent();
  }

  String _getEventTypeText(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'training':
        return l10n.eventTypeTraining;
      case 'group_run':
        return l10n.eventTypeGroupRun;
      case 'club_event':
        return l10n.eventTypeClubEvent;
      case 'open_event':
        return l10n.eventTypeOpenEvent;
      default:
        return type;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'open':
        return l10n.eventStatusOpen;
      case 'full':
        return l10n.eventStatusFull;
      case 'cancelled':
        return l10n.eventStatusCancelled;
      case 'completed':
        return l10n.eventStatusCompleted;
      default:
        return status;
    }
  }

  String? _getDifficultyText(BuildContext context, String? level) {
    final l10n = AppLocalizations.of(context)!;
    switch (level) {
      case 'beginner':
        return l10n.eventDifficultyBeginner;
      case 'intermediate':
        return l10n.eventDifficultyIntermediate;
      case 'advanced':
        return l10n.eventDifficultyAdvanced;
      default:
        return level;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('d.M.y H:mm');
    return dateFormat.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return DetailsScaffold(
      title: AppLocalizations.of(context)!.eventDetailsTitle,
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
                        _getStatusText(context, event.status),
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
                        AppLocalizations.of(context)!.eventDescription,
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
                      AppLocalizations.of(context)!.eventInfo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      Icons.event,
                      AppLocalizations.of(context)!.eventType,
                      _getEventTypeText(context, event.type),
                    ),
                    _buildInfoRow(
                      context,
                      Icons.access_time,
                      AppLocalizations.of(context)!.eventDateTime,
                      _formatDateTime(event.startDateTime),
                    ),
                    if (event.locationName != null)
                      _buildInfoRow(
                        context,
                        Icons.location_on,
                        AppLocalizations.of(context)!.eventLocation,
                        event.locationName!,
                      ),
                    _buildInfoRow(
                      context,
                      event.organizerType == 'club' ? Icons.group : Icons.person,
                      AppLocalizations.of(context)!.eventOrganizer,
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
                        AppLocalizations.of(context)!.eventDifficulty,
                        _getDifficultyText(context, event.difficultyLevel)!,
                      ),
                    if (event.territoryId != null)
                      _buildInfoRow(
                        context,
                        Icons.map,
                        AppLocalizations.of(context)!.eventTerritory,
                        AppLocalizations.of(context)!.eventTerritoryLinked,
                        onTap: () {
                          // TODO: Переход на детальный экран территории
                          context.push('/territory/${event.territoryId}');
                        },
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Точка старта на карте (placeholder)
                    Text(
                      AppLocalizations.of(context)!.eventStartPoint,
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
                              AppLocalizations.of(context)!.eventMapTodo,
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
                      AppLocalizations.of(context)!.eventParticipation,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (event.status == 'open')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isJoining ? null : _onJoinEvent,
                          icon: _isJoining
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.person_add),
                          label: Text(
                            _isJoining
                                ? AppLocalizations.of(context)!.eventJoinTodo
                                : AppLocalizations.of(context)!.eventJoin,
                          ),
                        ),
                      )
                    else if (event.status == 'full')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: null,
                          child: Text(AppLocalizations.of(context)!.eventNoPlaces),
                        ),
                      )
                    else if (event.status == 'cancelled')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: null,
                          child: Text(AppLocalizations.of(context)!.eventCancelled),
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
          return Center(
            child: Text(AppLocalizations.of(context)!.noData),
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
