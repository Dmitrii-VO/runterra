import 'package:flutter_test/flutter_test.dart';
import 'package:runterra/shared/models/my_club_model.dart';

void main() {
  group('MyClubModel', () {
    test('parses model from backend json', () {
      final model = MyClubModel.fromJson({
        'id': '550e8400-e29b-41d4-a716-446655440001',
        'name': 'Runterra Club',
        'description': 'Morning runs',
        'cityId': 'spb',
        'cityName': 'Санкт‑Петербург',
        'status': 'active',
        'role': 'leader',
        'joinedAt': '2026-02-08T10:00:00.000Z',
      });

      expect(model.id, '550e8400-e29b-41d4-a716-446655440001');
      expect(model.name, 'Runterra Club');
      expect(model.description, 'Morning runs');
      expect(model.cityId, 'spb');
      expect(model.cityName, 'Санкт‑Петербург');
      expect(model.status, 'active');
      expect(model.role, 'leader');
      expect(model.joinedAt.toUtc().toIso8601String(), '2026-02-08T10:00:00.000Z');
    });
  });
}
