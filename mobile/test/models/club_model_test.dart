import 'package:flutter_test/flutter_test.dart';
import 'package:runterra/shared/models/club_model.dart';

void main() {
  group('ClubModel', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'id': 'club-1',
        'name': 'Running Club',
        'description': 'A club for runners',
        'status': 'active',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-15T12:00:00.000Z',
      };

      final club = ClubModel.fromJson(json);

      expect(club.id, 'club-1');
      expect(club.name, 'Running Club');
      expect(club.description, 'A club for runners');
      expect(club.status, 'active');
    });

    test('fromJson handles null description', () {
      final json = {
        'id': 'club-2',
        'name': 'Simple Club',
        'status': 'active',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };

      final club = ClubModel.fromJson(json);

      expect(club.description, isNull);
    });

    test('toJson produces correct output', () {
      final club = ClubModel(
        id: 'club-1',
        name: 'Test Club',
        description: 'Test description',
        status: 'active',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final json = club.toJson();

      expect(json['id'], 'club-1');
      expect(json['name'], 'Test Club');
      expect(json['description'], 'Test description');
      expect(json['status'], 'active');
    });

    test('toJson excludes null description', () {
      final club = ClubModel(
        id: 'club-1',
        name: 'Test Club',
        status: 'active',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final json = club.toJson();

      expect(json.containsKey('description'), false);
    });
  });
}
