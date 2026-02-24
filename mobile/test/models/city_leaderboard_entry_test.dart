import 'package:flutter_test/flutter_test.dart';
import 'package:runterra/shared/models/city_leaderboard_entry.dart';

void main() {
  group('CityLeaderboardEntry', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'c-1',
        'name': 'Speedy Club',
        'membersCount': 10,
        'territoriesCount': 5,
        'points': 60,
        'rank': 1,
      };

      final entry = CityLeaderboardEntry.fromJson(json);

      expect(entry.name, 'Speedy Club');
      expect(entry.points, 60);
      expect(entry.rank, 1);
    });
  });

  group('CityLeaderboardResponse', () {
    test('fromJson parses correctly', () {
      final json = {
        'leaderboard': [
          {
            'id': 'c-1',
            'name': 'Club 1',
            'membersCount': 5,
            'territoriesCount': 1,
            'points': 15,
            'rank': 1,
          }
        ],
        'myClub': {
          'id': 'c-1',
          'name': 'Club 1',
          'membersCount': 5,
          'territoriesCount': 1,
          'points': 15,
          'rank': 1,
        }
      };

      final response = CityLeaderboardResponse.fromJson(json);

      expect(response.leaderboard, hasLength(1));
      expect(response.myClub?.id, 'c-1');
    });
  });
}