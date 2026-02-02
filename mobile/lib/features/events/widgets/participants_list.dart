import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Виджет списка участников события
/// 
/// Отображает список участников события с их именами и аватарами.
/// На текущей стадии (skeleton) использует mock-данные.
class ParticipantsList extends StatelessWidget {
  /// Количество участников
  final int participantCount;

  const ParticipantsList({
    super.key,
    required this.participantCount,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Загружать реальные данные участников из API
    // Mock-данные для skeleton
    final l10n = AppLocalizations.of(context)!;
    final mockParticipants = List.generate(
      participantCount > 10 ? 10 : participantCount,
      (index) => l10n.participantN(index + 1),
    );

    if (mockParticipants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(l10n.participantsNone),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            l10n.participantsTitle(participantCount),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mockParticipants.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: CircleAvatar(
                // TODO: Загружать реальные аватары
                child: Text(
                  mockParticipants[index][0].toUpperCase(),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              title: Text(mockParticipants[index]),
              // TODO: Добавить переход на профиль участника
            );
          },
        ),
        if (participantCount > 10)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n.participantsMore(participantCount - 10),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
