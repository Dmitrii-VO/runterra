import 'package:flutter_test/flutter_test.dart';
import 'package:runterra/shared/models/event_details_model.dart';
import 'package:runterra/shared/models/event_start_location.dart';

void main() {
  group('EventDetailsModel', () {
    test('fromJson parses participant flags when present', () {
      final json = {
        'id': 'event-1',
        'name': 'Morning Run',
        'type': 'training',
        'status': 'open',
        'startDateTime': '2026-02-01T08:00:00.000Z',
        'startLocation': {'latitude': 55.7558, 'longitude': 37.6173},
        'organizerId': 'club-1',
        'organizerType': 'club',
        'participantCount': 5,
        'cityId': 'spb',
        'createdAt': '2026-02-01T07:00:00.000Z',
        'updatedAt': '2026-02-01T07:00:00.000Z',
        'isParticipant': true,
        'participantStatus': 'registered',
      };

      final event = EventDetailsModel.fromJson(json);

      expect(event.isParticipant, true);
      expect(event.participantStatus, 'registered');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'event-2',
        'name': 'Evening Run',
        'type': 'group_run',
        'status': 'open',
        'startDateTime': '2026-02-01T18:00:00.000Z',
        'startLocation': {'latitude': 55.0, 'longitude': 37.0},
        'organizerId': 'trainer-1',
        'organizerType': 'trainer',
        'participantCount': 0,
        'cityId': 'spb',
        'createdAt': '2026-02-01T17:00:00.000Z',
        'updatedAt': '2026-02-01T17:00:00.000Z',
      };

      final event = EventDetailsModel.fromJson(json);

      expect(event.locationName, isNull);
      expect(event.difficultyLevel, isNull);
      expect(event.description, isNull);
      expect(event.isParticipant, isNull);
      expect(event.participantStatus, isNull);
    });

    test('toJson includes participant flags when set', () {
      final event = EventDetailsModel(
        id: 'event-1',
        name: 'Test Event',
        type: 'training',
        status: 'open',
        startDateTime: DateTime.utc(2026, 2, 1, 8, 0, 0),
        startLocation: EventStartLocation(latitude: 55.0, longitude: 37.0),
        organizerId: 'club-1',
        organizerType: 'club',
        participantCount: 10,
        cityId: 'spb',
        createdAt: DateTime.utc(2026, 2, 1, 7, 0, 0),
        updatedAt: DateTime.utc(2026, 2, 1, 7, 0, 0),
        isParticipant: true,
        participantStatus: 'checked_in',
      );

      final json = event.toJson();

      expect(json['isParticipant'], true);
      expect(json['participantStatus'], 'checked_in');
    });
  });
}
