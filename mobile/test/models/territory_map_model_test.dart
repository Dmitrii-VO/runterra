import 'package:flutter_test/flutter_test.dart';
import 'package:runterra/shared/models/territory_map_model.dart';

void main() {
  group('TerritoryMapModel', () {
    test('fromJson parses valid JSON with geometry', () {
      final json = {
        'id': 'spb-park-1',
        'name': 'Test Park',
        'status': 'free',
        'coordinates': {'latitude': 59.97, 'longitude': 30.24},
        'cityId': 'spb',
        'geometry': [
          {'latitude': 59.965, 'longitude': 30.235},
          {'latitude': 59.965, 'longitude': 30.245},
          {'latitude': 59.975, 'longitude': 30.245},
          {'latitude': 59.975, 'longitude': 30.235},
        ],
        'createdAt': '2026-01-01T12:00:00.000Z',
        'updatedAt': '2026-01-01T12:00:00.000Z',
      };

      final model = TerritoryMapModel.fromJson(json);

      expect(model.id, 'spb-park-1');
      expect(model.name, 'Test Park');
      expect(model.status, 'free');
      expect(model.coordinates.latitude, 59.97);
      expect(model.coordinates.longitude, 30.24);
      expect(model.geometry, isNotNull);
      expect(model.geometry!.length, 4);
      expect(model.geometry![0].latitude, 59.965);
      expect(model.geometry![0].longitude, 30.235);
    });

    test('fromJson handles missing geometry (fallback to circle)', () {
      final json = {
        'id': 'spb-park-1',
        'name': 'Test Park',
        'status': 'captured',
        'coordinates': {'latitude': 59.97, 'longitude': 30.24},
        'cityId': 'spb',
        'createdAt': '2026-01-01T12:00:00.000Z',
        'updatedAt': '2026-01-01T12:00:00.000Z',
      };

      final model = TerritoryMapModel.fromJson(json);

      expect(model.geometry, isNull);
    });
  });
}
