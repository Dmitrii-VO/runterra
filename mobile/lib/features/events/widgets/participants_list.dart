import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/event_participant_model.dart';
import '../../../shared/ui/error_display.dart';

/// Виджет списка участников события
/// 
/// Отображает список участников события с их именами и аватарами.
/// На текущей стадии (skeleton) использует mock-данные.
class ParticipantsList extends StatefulWidget {
  /// ID события
  final String eventId;

  /// Количество участников
  final int participantCount;

  const ParticipantsList({
    super.key,
    required this.eventId,
    required this.participantCount,
  });

  @override
  State<ParticipantsList> createState() => _ParticipantsListState();
}

class _ParticipantsListState extends State<ParticipantsList> {
  late Future<List<EventParticipantModel>> _participantsFuture;

  Future<List<EventParticipantModel>> _fetchParticipants() async {
    return ServiceLocator.eventsService.getEventParticipants(widget.eventId);
  }

  void _retry() {
    setState(() {
      _participantsFuture = _fetchParticipants();
    });
  }

  @override
  void initState() {
    super.initState();
    _participantsFuture = _fetchParticipants();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.participantCount == 0) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(l10n.participantsNone),
      );
    }

    return FutureBuilder<List<EventParticipantModel>>(
      future: _participantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return ErrorDisplay(
            errorMessage: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final participants = snapshot.data ?? [];
        if (participants.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(l10n.participantsNone),
          );
        }

        final visibleParticipants = participants.take(10).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.participantsTitle(widget.participantCount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleParticipants.length,
              itemBuilder: (context, index) {
                final participant = visibleParticipants[index];
                final displayName = participant.name ?? l10n.participantN(index + 1);
                final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
                return ListTile(
                  leading: CircleAvatar(
                    // TODO: Загружать реальные аватары
                    child: Text(
                      initial,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: Text(displayName),
                  // TODO: Добавить переход на профиль участника
                );
              },
            ),
            if (widget.participantCount > visibleParticipants.length)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.participantsMore(widget.participantCount - visibleParticipants.length),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }
}
