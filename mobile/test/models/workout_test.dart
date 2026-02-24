import 'package:flutter_test/flutter_test.dart';
import 'package:runterra/shared/models/workout.dart';

void main() {
  group('Workout', () {
    test('fromJson parses valid JSON with target fields correctly', () {
      final json = {
        'id': 'w-1',
        'authorId': 'u-1',
        'clubId': 'c-1',
        'name': 'Tempo Run',
        'description': 'Hard tempo',
        'type': 'TEMPO',
        'difficulty': 'ADVANCED',
        'targetMetric': 'DISTANCE',
        'targetValue': 5000,
        'targetZone': 'Z3',
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final workout = Workout.fromJson(json);

      expect(workout.id, 'w-1');
      expect(workout.targetValue, 5000);
      expect(workout.targetZone, 'Z3');
    });

    test('toJson produces correct output with target fields', () {
      final workout = Workout(
        id: 'w-1',
        authorId: 'u-1',
        name: 'Tempo',
        type: 'TEMPO',
        difficulty: 'INTERMEDIATE',
        targetMetric: 'DISTANCE',
        targetValue: 10000,
        targetZone: 'Z2',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final json = workout.toJson();

      expect(json['targetValue'], 10000);
      expect(json['targetZone'], 'Z2');
    });
  });
}