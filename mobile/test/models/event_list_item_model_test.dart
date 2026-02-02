import 'package:flutter_test/flutter_test.dart';
import 'package:runterra/shared/models/event_list_item_model.dart';
import 'package:runterra/shared/models/event_start_location.dart';

void main() {
  group('EventListItemModel', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'id': 'event-1',
        'name': 'Morning Run',
        'type': 'training',
        'status': 'open',
        'startDateTime': '2026-02-01T08:00:00.000Z',
        'startLocation': {
          'latitude': 55.7558,
          'longitude': 37.6173,
        },
        'locationName': 'Central Park',
        'organizerId': 'club-1',
        'organizerType': 'club',
        'difficultyLevel': 'beginner',
        'participantCount': 5,
        'territoryId': 'territory-1',
        'cityId': 'spb',
      };

      final event = EventListItemModel.fromJson(json);

      expect(event.id, 'event-1');
      expect(event.name, 'Morning Run');
      expect(event.type, 'training');
      expect(event.status, 'open');
      expect(event.startDateTime, DateTime.utc(2026, 2, 1, 8, 0, 0));
      expect(event.startLocation.latitude, 55.7558);
      expect(event.startLocation.longitude, 37.6173);
      expect(event.locationName, 'Central Park');
      expect(event.organizerId, 'club-1');
      expect(event.organizerType, 'club');
      expect(event.difficultyLevel, 'beginner');
      expect(event.participantCount, 5);
      expect(event.territoryId, 'territory-1');
      expect(event.cityId, 'spb');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'event-2',
        'name': 'Evening Run',
        'type': 'group_run',
        'status': 'open',
        'startDateTime': '2026-02-01T18:00:00.000Z',
        'startLocation': {
          'latitude': 55.0,
          'longitude': 37.0,
        },
        'organizerId': 'trainer-1',
        'organizerType': 'trainer',
        'participantCount': 0,
      };

      final event = EventListItemModel.fromJson(json);

      expect(event.locationName, isNull);
      expect(event.difficultyLevel, isNull);
      expect(event.territoryId, isNull);
      expect(event.cityId, ''); // defaults to '' when missing
    });

    test('toJson produces correct output', () {
      final event = EventListItemModel(
        id: 'event-1',
        name: 'Test Event',
        type: 'training',
        status: 'open',
        startDateTime: DateTime.utc(2026, 2, 1, 8, 0, 0),
        startLocation: EventStartLocation(
          latitude: 55.0,
          longitude: 37.0,
        ),
        organizerId: 'club-1',
        organizerType: 'club',
        participantCount: 10,
        cityId: 'spb',
      );

      final json = event.toJson();

      expect(json['id'], 'event-1');
      expect(json['name'], 'Test Event');
      expect(json['type'], 'training');
      expect(json['startDateTime'], '2026-02-01T08:00:00.000Z');
      expect(json['participantCount'], 10);
      expect(json.containsKey('locationName'), false);
      expect(json.containsKey('difficultyLevel'), false);
      expect(json.containsKey('territoryId'), false);
    });

    test('fromJson handles participantCount as int or double', () {
      final jsonWithInt = {
        'id': 'event-1',
        'name': 'Test',
        'type': 'training',
        'status': 'open',
        'startDateTime': '2026-02-01T08:00:00.000Z',
        'startLocation': {'latitude': 55.0, 'longitude': 37.0},
        'organizerId': 'club-1',
        'organizerType': 'club',
        'participantCount': 5,
      };

      final jsonWithDouble = {
        ...jsonWithInt,
        'participantCount': 5.0,
      };

      final eventFromInt = EventListItemModel.fromJson(jsonWithInt);
      final eventFromDouble = EventListItemModel.fromJson(jsonWithDouble);

      expect(eventFromInt.participantCount, 5);
      expect(eventFromDouble.participantCount, 5);
    });
  });
}
