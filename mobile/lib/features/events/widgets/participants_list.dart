import 'package:flutter/material.dart';

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
    final mockParticipants = List.generate(
      participantCount > 10 ? 10 : participantCount, // Показываем максимум 10
      (index) => 'Участник ${index + 1}',
    );

    if (mockParticipants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Пока нет участников'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Участники ($participantCount)',
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
              'И ещё ${participantCount - 10} участников',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
