import 'package:flutter_test/flutter_test.dart';
import 'package:runterra/shared/models/run_model.dart';

void main() {
  group('RunModel', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'id': 'run-1',
        'userId': 'user-1',
        'activityId': 'activity-1',
        'startedAt': '2026-01-31T08:00:00.000Z',
        'endedAt': '2026-01-31T08:30:00.000Z',
        'duration': 1800,
        'distance': 5000.0,
        'status': 'completed',
        'createdAt': '2026-01-31T08:30:00.000Z',
        'updatedAt': '2026-01-31T08:30:00.000Z',
      };

      final run = RunModel.fromJson(json);

      expect(run.id, 'run-1');
      expect(run.userId, 'user-1');
      expect(run.activityId, 'activity-1');
      expect(run.duration.inSeconds, 1800);
      expect(run.distance, 5000.0);
      expect(run.status, RunModelStatus.completed);
    });

    test('fromJson handles null activityId', () {
      final json = {
        'id': 'run-2',
        'userId': 'user-1',
        'startedAt': '2026-01-31T08:00:00.000Z',
        'endedAt': '2026-01-31T08:30:00.000Z',
        'duration': 1800,
        'distance': 5000.0,
        'status': 'completed',
        'createdAt': '2026-01-31T08:30:00.000Z',
        'updatedAt': '2026-01-31T08:30:00.000Z',
      };

      final run = RunModel.fromJson(json);

      expect(run.activityId, isNull);
    });

    test('fromJson handles unknown status as completed (safe default)', () {
      final json = {
        'id': 'run-3',
        'userId': 'user-1',
        'startedAt': '2026-01-31T08:00:00.000Z',
        'endedAt': '2026-01-31T08:30:00.000Z',
        'duration': 1800,
        'distance': 5000.0,
        'status': 'unknown_status',
        'createdAt': '2026-01-31T08:30:00.000Z',
        'updatedAt': '2026-01-31T08:30:00.000Z',
      };

      final run = RunModel.fromJson(json);

      // Unknown status defaults to completed (safe fallback)
      expect(run.status, RunModelStatus.completed);
    });

    test('fromJson parses invalid status correctly', () {
      final json = {
        'id': 'run-3',
        'userId': 'user-1',
        'startedAt': '2026-01-31T08:00:00.000Z',
        'endedAt': '2026-01-31T08:30:00.000Z',
        'duration': 1800,
        'distance': 5000.0,
        'status': 'invalid',
        'createdAt': '2026-01-31T08:30:00.000Z',
        'updatedAt': '2026-01-31T08:30:00.000Z',
      };

      final run = RunModel.fromJson(json);

      expect(run.status, RunModelStatus.invalid);
    });

    test('duration is correctly converted from seconds', () {
      final json = {
        'id': 'run-4',
        'userId': 'user-1',
        'startedAt': '2026-01-31T08:00:00.000Z',
        'endedAt': '2026-01-31T09:30:00.000Z',
        'duration': 5400, // 1.5 hours
        'distance': 10000.0,
        'status': 'completed',
        'createdAt': '2026-01-31T09:30:00.000Z',
        'updatedAt': '2026-01-31T09:30:00.000Z',
      };

      final run = RunModel.fromJson(json);

      expect(run.duration.inMinutes, 90);
      expect(run.duration.inHours, 1);
    });
  });
}
