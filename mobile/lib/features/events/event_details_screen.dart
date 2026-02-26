import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../shared/models/event_details_model.dart';
import '../../shared/ui/error_display.dart';
import 'widgets/event_mini_map.dart';
import 'widgets/participants_list.dart';
import 'widgets/swipe_to_run_card.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Future<EventDetailsModel> _eventFuture;
  bool _isJoining = false;
  bool _isLeaving = false;

  Future<EventDetailsModel> _fetchEvent() async {
    return ServiceLocator.eventsService.getEventById(widget.eventId);
  }

  void _retry() {
    setState(() {
      _eventFuture = _fetchEvent();
    });
  }

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

  Future<void> _onLeaveEvent() async {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ServiceLocator.eventsService.leaveEvent(widget.eventId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventLeaveSuccess)),
      );
      _retry();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventLeaveError(e.message))),
      );
    } finally {
      if (mounted) setState(() => _isLeaving = false);
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

  String _effectiveStatus(EventDetailsModel event) {
    final now = DateTime.now();
    if (!event.startDateTime.isBefore(now)) return event.status;
    if (event.status == 'cancelled' || event.status == 'completed') {
      return event.status;
    }
    return 'completed';
  }

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

  String _getWorkoutTypeText(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'RECOVERY':
        return l10n.typeRecovery;
      case 'TEMPO':
        return l10n.typeTempo;
      case 'INTERVAL':
        return l10n.typeInterval;
      case 'FARTLEK':
        return l10n.typeFartlek;
      case 'LONG_RUN':
        return l10n.typeLongRun;
      default:
        return type;
    }
  }

  String _getWorkoutDifficultyText(BuildContext context, String difficulty) {
    final l10n = AppLocalizations.of(context)!;
    switch (difficulty) {
      case 'BEGINNER':
        return l10n.diffBeginner;
      case 'INTERMEDIATE':
        return l10n.diffIntermediate;
      case 'ADVANCED':
        return l10n.diffAdvanced;
      case 'PRO':
        return l10n.diffPro;
      default:
        return difficulty;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('d.M.y H:mm');
    return dateFormat.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.eventDetailsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          FutureBuilder<EventDetailsModel>(
            future: _eventFuture,
            builder: (context, snapshot) {
              final event = snapshot.data;
              if (event == null) return const SizedBox.shrink();
              final effectiveStatus = _effectiveStatus(event);
              if (event.isOrganizer != true) return const SizedBox.shrink();
              if (effectiveStatus == 'completed' ||
                  effectiveStatus == 'cancelled') {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await context.push('/event/${event.id}/edit');
                  _retry();
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<EventDetailsModel>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorDisplay(
              errorMessage: snapshot.error.toString(),
              onRetry: _retry,
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noData),
            );
          }

          final event = snapshot.data!;
          final effectiveStatus = _effectiveStatus(event);
          final isParticipant = event.isParticipant == true ||
              event.participantStatus == 'registered' ||
              event.participantStatus == 'checked_in';

          final statusColor = _getStatusColor(effectiveStatus);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(context, effectiveStatus),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    (event.organizerDisplayName?.trim().isNotEmpty == true)
                        ? event.organizerDisplayName!.trim()
                        : event.organizerId,
                    onTap: () {
                      if (event.organizerType == 'club') {
                        context.push('/club/${event.organizerId}');
                      }
                    },
                  ),
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
                        context.push('/territory/${event.territoryId}');
                      },
                    ),
                  if (event.workoutId != null || event.workoutName != null)
                    _buildInfoRow(
                      context,
                      Icons.fitness_center,
                      AppLocalizations.of(context)!.eventWorkout,
                      event.workoutName ??
                          AppLocalizations.of(context)!.eventNoWorkout,
                    ),
                  if (event.workoutType != null)
                    _buildInfoRow(
                      context,
                      Icons.flag,
                      AppLocalizations.of(context)!.workoutType,
                      _getWorkoutTypeText(context, event.workoutType!),
                    ),
                  if (event.workoutDifficulty != null)
                    _buildInfoRow(
                      context,
                      Icons.speed,
                      AppLocalizations.of(context)!.workoutDifficulty,
                      _getWorkoutDifficultyText(
                          context, event.workoutDifficulty!),
                    ),
                  if (event.workoutDescription != null &&
                      event.workoutDescription!.trim().isNotEmpty)
                    _buildInfoRow(
                      context,
                      Icons.notes,
                      AppLocalizations.of(context)!.workoutDescription,
                      event.workoutDescription!,
                    ),
                  if (event.trainerId != null || event.trainerName != null)
                    _buildInfoRow(
                      context,
                      Icons.person_outline,
                      AppLocalizations.of(context)!.eventTrainer,
                      event.trainerName ?? event.trainerId!,
                      onTap: event.trainerId == null
                          ? null
                          : () {
                              context.push('/trainer/${event.trainerId}');
                            },
                    ),
                  if (event.startLocation != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.eventStartPoint,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    EventMiniMap(
                      latitude: event.startLocation!.latitude,
                      longitude: event.startLocation!.longitude,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.eventParticipation,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (isParticipant) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null,
                        child: Text(
                            AppLocalizations.of(context)!.eventYouParticipate),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwipeToRunCard(
                      event: event,
                      onRefresh: _retry,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLeaving ? null : _onLeaveEvent,
                        icon: _isLeaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.close),
                        label: Text(AppLocalizations.of(context)!.eventLeave),
                      ),
                    ),
                  ] else if (effectiveStatus == 'open') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isJoining ? null : _onJoinEvent,
                        icon: _isJoining
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add),
                        label: Text(
                          _isJoining
                              ? AppLocalizations.of(context)!
                                  .eventJoinInProgress
                              : AppLocalizations.of(context)!.eventJoin,
                        ),
                      ),
                    ),
                  ] else if (effectiveStatus == 'full') ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: null,
                        child:
                            Text(AppLocalizations.of(context)!.eventNoPlaces),
                      ),
                    ),
                  ] else if (effectiveStatus == 'cancelled') ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: null,
                        child:
                            Text(AppLocalizations.of(context)!.eventCancelled),
                      ),
                    ),
                  ] else if (effectiveStatus == 'completed') ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text(
                            AppLocalizations.of(context)!.eventStatusCompleted),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ParticipantsList(
                    eventId: widget.eventId,
                    participantCount: event.participantCount,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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
                      decoration:
                          onTap != null ? TextDecoration.underline : null,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
