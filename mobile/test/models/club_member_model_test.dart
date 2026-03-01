import 'package:flutter_test/flutter_test.dart';
import 'package:runterra/shared/models/club_member_model.dart';

void main() {
  group('ClubMemberModel', () {
    test('fromJson parses valid JSON with totalDistance correctly', () {
      final json = {
        'userId': 'u-1',
        'displayName': 'Lucky Lee',
        'role': 'member',
        'joinedAt': '2026-01-01T00:00:00.000Z',
        'planType': 'personal',
        'totalDistance': 15400,
      };

      final member = ClubMemberModel.fromJson(json);

      expect(member.userId, 'u-1');
      expect(member.totalDistance, 15400);
    });

    test('fromJson handles missing totalDistance', () {
      final json = {
        'userId': 'u-2',
        'displayName': 'Newbie',
        'role': 'member',
        'joinedAt': '2026-01-01T00:00:00.000Z',
        'planType': 'club',
      };

      final member = ClubMemberModel.fromJson(json);

      expect(member.totalDistance, 0);
    });
  });
}
