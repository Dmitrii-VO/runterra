import 'dart:convert';
import 'api_client.dart';
import 'users_service.dart' show ApiException;
import '../models/workout.dart';

/// Service for workouts API
class WorkoutsService {
  final ApiClient _apiClient;

  WorkoutsService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /api/workouts?clubId=
  Future<List<Workout>> getWorkouts({String? clubId}) async {
    final params = <String, String>{};
    if (clubId != null) params['clubId'] = clubId;

    final endpoint = params.isEmpty
        ? '/api/workouts'
        : '/api/workouts?${Uri(queryParameters: params).query}';

    final response = await _apiClient.get(endpoint);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((json) => Workout.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    _throwApiException(response, 'get_workouts_error');
  }

  /// GET /api/workouts/:id
  Future<Workout> getWorkout(String id) async {
    final response = await _apiClient.get('/api/workouts/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Workout.fromJson(json);
    }
    _throwApiException(response, 'get_workout_error');
  }

  /// POST /api/workouts
  Future<Workout> createWorkout({
    String? clubId,
    required String name,
    String? description,
    required String type,
    required String difficulty,
    required String targetMetric,
    int? targetValue,
    String? targetZone,
  }) async {
    final response = await _apiClient.post(
      '/api/workouts',
      body: {
        if (clubId != null) 'clubId': clubId,
        'name': name,
        if (description != null) 'description': description,
        'type': type,
        'difficulty': difficulty,
        'targetMetric': targetMetric,
        if (targetValue != null) 'targetValue': targetValue,
        if (targetZone != null) 'targetZone': targetZone,
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Workout.fromJson(json);
    }
    _throwApiException(response, 'create_workout_error');
  }

  /// PATCH /api/workouts/:id
  Future<Workout> updateWorkout(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/api/workouts/$id', body: data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Workout.fromJson(json);
    }
    _throwApiException(response, 'update_workout_error');
  }

  /// DELETE /api/workouts/:id
  Future<void> deleteWorkout(String id) async {
    final response = await _apiClient.delete('/api/workouts/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwApiException(response, 'delete_workout_error');
  }

  Never _throwApiException(dynamic response, String fallbackCode) {
    String errorCode = fallbackCode;
    String errorMessage = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded != null) {
        errorCode = (decoded['code'] as String?) ?? errorCode;
        errorMessage = (decoded['message'] as String?) ?? errorMessage;
      }
    } on FormatException {
      // Non-JSON response
    }
    throw ApiException(errorCode, errorMessage);
  }
}
