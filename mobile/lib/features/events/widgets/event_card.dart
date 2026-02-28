import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/event_list_item_model.dart';

/// Event card widget for events list.
class EventCard extends StatelessWidget {
  final EventListItemModel event;

  const EventCard({
    super.key,
    required this.event,
  });

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

  String _effectiveStatus(EventListItemModel event) {
    // Backend may still return `open` for past events; for UX we treat past
    // non-cancelled events as completed.
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

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final dateFormat = DateFormat('d.M.y H:mm');
    return '${dateFormat.format(local)} ${local.timeZoneName}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _effectiveStatus(event);
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          context.push('/event/${event.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(context, status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    _getEventTypeText(context, event.type),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
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
                      (event.organizerDisplayName?.trim().isNotEmpty == true)
                          ? event.organizerDisplayName!.trim()
                          : AppLocalizations.of(context)!
                              .eventOrganizerLabel(event.organizerId),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (event.difficultyLevel != null)
                Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _getDifficultyText(context, event.difficultyLevel)!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              if (event.difficultyLevel != null) const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${event.participantCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (event.territoryId != null)
                    Row(
                      children: [
                        const Icon(Icons.map, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.eventTerritoryLabel,
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
