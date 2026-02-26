import 'dart:convert';
import 'api_client.dart';
import 'users_service.dart' show ApiException;
import '../models/club_model.dart';
import '../models/club_member_model.dart';
import '../models/my_club_model.dart';
import '../models/schedule_model.dart';
import '../models/calendar_model.dart';
import '../models/city_leaderboard_entry.dart';

class ClubsService {
  final ApiClient _apiClient;

  ClubsService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /api/clubs/leaderboard/:cityId
  Future<CityLeaderboardResponse> getCityLeaderboard(String cityId,
      {String? clubId}) async {
    final query =
        clubId != null ? '?clubId=${Uri.encodeComponent(clubId)}' : '';
    final response = await _apiClient
        .get('/api/clubs/leaderboard/${Uri.encodeComponent(cityId)}$query');
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return CityLeaderboardResponse.fromJson(jsonData);
    }
    throw ApiException('leaderboard_fetch_error',
        'Failed to load leaderboard (${response.statusCode})');
  }

  /// GET /api/clubs/:id/calendar — aggregated calendar.
  Future<List<CalendarItemModel>> getCalendar(
      String clubId, String yearMonth) async {
    final response = await _apiClient.get(
        '/api/clubs/${Uri.encodeComponent(clubId)}/calendar?month=$yearMonth');
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((item) =>
              CalendarItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('calendar_fetch_error', 'Failed to load calendar');
  }

  /// GET /api/clubs/:id/schedule — weekly schedule template.
  Future<List<WeeklyScheduleItemModel>> getWeeklySchedule(String clubId) async {
    final response = await _apiClient
        .get('/api/clubs/${Uri.encodeComponent(clubId)}/schedule');
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((item) =>
              WeeklyScheduleItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('schedule_fetch_error',
        'Failed to load schedule (${response.statusCode})');
  }

  /// POST /api/clubs/:id/schedule — create template item.
  Future<WeeklyScheduleItemModel> createWeeklyItem(
      String clubId, Map<String, dynamic> data) async {
    final response = await _apiClient
        .post('/api/clubs/${Uri.encodeComponent(clubId)}/schedule', body: data);
    if (response.statusCode == 201) {
      return WeeklyScheduleItemModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException('schedule_create_error',
        'Failed to create item (${response.statusCode})');
  }

  /// PATCH /api/clubs/:id/schedule/:itemId — update template item.
  Future<WeeklyScheduleItemModel> updateWeeklyItem(
      String clubId, String itemId, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
        '/api/clubs/${Uri.encodeComponent(clubId)}/schedule/${Uri.encodeComponent(itemId)}',
        body: data);
    if (response.statusCode == 200) {
      return WeeklyScheduleItemModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException('schedule_update_error',
        'Failed to update item (${response.statusCode})');
  }

  /// DELETE /api/clubs/:id/schedule/:itemId — delete template item.
  Future<void> deleteWeeklyItem(String clubId, String itemId) async {
    final response = await _apiClient.delete(
        '/api/clubs/${Uri.encodeComponent(clubId)}/schedule/${Uri.encodeComponent(itemId)}');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException('schedule_delete_error',
        'Failed to delete item (${response.statusCode})');
  }

  /// GET /api/clubs/:id/members/:userId/personal-schedule
  Future<List<PersonalScheduleItemModel>> getMemberPersonalSchedule(
      String clubId, String userId) async {
    final response = await _apiClient.get(
        '/api/clubs/${Uri.encodeComponent(clubId)}/members/${Uri.encodeComponent(userId)}/personal-schedule');
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((item) =>
              PersonalScheduleItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException(
        'personal_schedule_fetch_error', 'Failed to load personal schedule');
  }

  /// POST /api/clubs/:id/members/:userId/personal-schedule
  Future<void> setMemberPersonalSchedule(
      String clubId, String userId, List<Map<String, dynamic>> items) async {
    final response = await _apiClient.post(
      '/api/clubs/${Uri.encodeComponent(clubId)}/members/${Uri.encodeComponent(userId)}/personal-schedule',
      body: {'items': items},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(
        'personal_schedule_update_error', 'Failed to update personal schedule');
  }

  /// GET /api/clubs — list of clubs by city.
  Future<List<ClubModel>> getClubs({required String cityId}) async {
    final uri = Uri(
      path: '/api/clubs',
      queryParameters: {'cityId': cityId},
    );
    final response = await _apiClient.get(uri.toString());

    if (response.statusCode != 200) {
      String errorCode = 'clubs_fetch_error';
      String errorMessage = 'Failed to load clubs (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        if (decoded != null) {
          errorCode = (decoded['code'] as String?) ?? errorCode;
          errorMessage = (decoded['message'] as String?) ?? errorMessage;
        }
      } on FormatException {/* ignore */}
      throw ApiException(errorCode, errorMessage);
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw ApiException(
          'invalid_response', 'Server returned non-JSON response');
    }

    final jsonData = jsonDecode(response.body) as List<dynamic>;
    return jsonData
        .map((json) => ClubModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/clubs/my — active clubs where current user is a member.
  Future<List<MyClubModel>> getMyClubs() async {
    final response = await _apiClient.get('/api/clubs/my');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((item) => MyClubModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    String errorCode = 'my_clubs_fetch_error';
    String errorMessage = 'Failed to load my clubs (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded != null) {
        errorCode = (decoded['code'] as String?) ?? errorCode;
        errorMessage = (decoded['message'] as String?) ?? errorMessage;
      }
    } on FormatException {/* ignore */}
    throw ApiException(errorCode, errorMessage);
  }

  /// GET /api/clubs/:id — club by ID.
  Future<ClubModel> getClubById(String id) async {
    final response =
        await _apiClient.get('/api/clubs/${Uri.encodeComponent(id)}');

    if (response.statusCode != 200) {
      String errorCode = 'club_fetch_error';
      String errorMessage = 'Failed to load club (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        if (decoded != null) {
          errorCode = (decoded['code'] as String?) ?? errorCode;
          errorMessage = (decoded['message'] as String?) ?? errorMessage;
        }
      } on FormatException {/* ignore */}
      throw ApiException(errorCode, errorMessage);
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw ApiException(
          'invalid_response', 'Server returned non-JSON response');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return ClubModel.fromJson(jsonData);
  }

  /// GET /api/clubs/:id/members — list of active members.
  Future<List<ClubMemberModel>> getClubMembers(String clubId) async {
    final response = await _apiClient
        .get('/api/clubs/${Uri.encodeComponent(clubId)}/members');
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((item) => ClubMemberModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    String errorCode = 'members_fetch_error';
    String errorMessage = 'Failed to load members (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded != null) {
        errorCode = (decoded['code'] as String?) ?? errorCode;
        errorMessage = (decoded['message'] as String?) ?? errorMessage;
      }
    } on FormatException {/* ignore */}
    throw ApiException(errorCode, errorMessage);
  }

  /// PATCH /api/clubs/:id/members/:userId/role
  Future<void> updateMemberRole(
      String clubId, String userId, String role) async {
    final response = await _apiClient.patch(
      '/api/clubs/${Uri.encodeComponent(clubId)}/members/${Uri.encodeComponent(userId)}/role',
      body: {'role': role},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String errorCode = 'update_role_error';
    String errorMessage = 'Failed to update role (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded != null) {
        errorCode = (decoded['code'] as String?) ?? errorCode;
        errorMessage = (decoded['message'] as String?) ?? errorMessage;
      }
    } on FormatException {/* ignore */}
    throw ApiException(errorCode, errorMessage);
  }

  /// POST /api/clubs — create club.
  Future<ClubModel> createClub({
    required String name,
    String? description,
    required String cityId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'cityId': cityId,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final response = await _apiClient.post('/api/clubs', body: body);

    if (response.statusCode != 201) {
      String errorMessage = 'Failed to create club (${response.statusCode})';
      String errorCode = 'create_club_error';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        if (decoded != null) {
          errorCode = (decoded['code'] as String?) ?? errorCode;
          errorMessage = (decoded['message'] as String?) ?? errorMessage;
        }
      } on FormatException {/* ignore */}
      throw ApiException(errorCode, errorMessage);
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw ApiException('invalid_response', 'Server returned non-JSON');
    }
    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return ClubModel.fromJson(jsonData);
  }

  /// POST /api/clubs/:id/join
  Future<void> joinClub(String clubId) async {
    final response =
        await _apiClient.post('/api/clubs/${Uri.encodeComponent(clubId)}/join');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String errorCode = 'join_club_error';
    String errorMessage = 'Failed to join club (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded != null) {
        errorCode = (decoded['code'] as String?) ?? errorCode;
        errorMessage = (decoded['message'] as String?) ?? errorMessage;
      }
    } on FormatException {/* ignore */}
    throw ApiException(errorCode, errorMessage);
  }

  /// POST /api/clubs/:id/leave
  Future<void> leaveClub(String clubId) async {
    final response = await _apiClient
        .post('/api/clubs/${Uri.encodeComponent(clubId)}/leave');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String errorCode = 'leave_club_error';
    String errorMessage = 'Failed to leave club (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded != null) {
        errorCode = (decoded['code'] as String?) ?? errorCode;
        errorMessage = (decoded['message'] as String?) ?? errorMessage;
      }
    } on FormatException {/* ignore */}
    throw ApiException(errorCode, errorMessage);
  }

  /// GET /api/clubs/:id/membership-requests
  Future<List<ClubMemberModel>> getMembershipRequests(String clubId) async {
    final response = await _apiClient
        .get('/api/clubs/${Uri.encodeComponent(clubId)}/membership-requests');
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((item) => ClubMemberModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('requests_fetch_error', 'Failed to load requests');
  }

  /// POST /api/clubs/:id/membership-requests/:userId/approve
  Future<void> approveMembership(String clubId, String userId) async {
    final response = await _apiClient.post(
        '/api/clubs/${Uri.encodeComponent(clubId)}/membership-requests/${Uri.encodeComponent(userId)}/approve');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException('approve_error', 'Failed to approve');
  }

  /// POST /api/clubs/:id/membership-requests/:userId/reject
  Future<void> rejectMembership(String clubId, String userId) async {
    final response = await _apiClient.post(
        '/api/clubs/${Uri.encodeComponent(clubId)}/membership-requests/${Uri.encodeComponent(userId)}/reject');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException('reject_error', 'Failed to reject');
  }

  /// DELETE /api/clubs/:id — disband club.
  Future<void> disbandClub(String clubId) async {
    final response =
        await _apiClient.delete('/api/clubs/${Uri.encodeComponent(clubId)}');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException('disband_club_error', 'Failed to disband club');
  }

  /// PATCH /api/clubs/:id — update club.
  Future<ClubModel> updateClub(String clubId,
      {String? name, String? description}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    final response = await _apiClient
        .patch('/api/clubs/${Uri.encodeComponent(clubId)}', body: body);
    if (response.statusCode == 200) {
      return ClubModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException('update_club_error', 'Failed to update club');
  }
}
