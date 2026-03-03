import 'package:flutter_test/flutter_test.dart';
import 'package:runterra/shared/models/workout.dart';

void main() {
  group('Workout', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'id': 'w-1',
        'authorId': 'u-1',
        'clubId': 'c-1',
        'name': 'Tempo Run',
        'description': 'Hard tempo',
        'type': 'TEMPO',
        'difficulty': 'ADVANCED',
        'distanceM': 5000,
        'heartRateTarget': 160,
        'paceTarget': 270,
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final workout = Workout.fromJson(json);

      expect(workout.id, 'w-1');
      expect(workout.distanceM, 5000);
      expect(workout.heartRateTarget, 160);
      expect(workout.paceTarget, 270);
    });

    test('toJson produces correct output with type-specific fields', () {
      final workout = Workout(
        id: 'w-1',
        authorId: 'u-1',
        name: 'Tempo',
        type: 'TEMPO',
        difficulty: 'INTERMEDIATE',
        distanceM: 10000,
        paceTarget: 240,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final json = workout.toJson();

      expect(json['distanceM'], 10000);
      expect(json['paceTarget'], 240);
      expect(json.containsKey('heartRateTarget'), false);
    });

    test('fromJson handles FUNCTIONAL type fields', () {
      final json = {
        'id': 'w-2',
        'authorId': 'u-1',
        'name': 'Squats',
        'type': 'FUNCTIONAL',
        'difficulty': 'BEGINNER',
        'exerciseName': 'Squat',
        'exerciseInstructions': 'Feet shoulder-width apart',
        'repCount': 20,
        'createdAt': '2026-01-01T00:00:00.000Z',
      };

      final workout = Workout.fromJson(json);

      expect(workout.exerciseName, 'Squat');
      expect(workout.repCount, 20);
    });
  });
}
