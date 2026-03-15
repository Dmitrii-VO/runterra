import 'dart:convert';
import '../models/workout_plan.dart';
import 'api_client.dart';
import 'users_service.dart' show ApiException;

/// Service for personal workout plan CRUD and sharing
class WorkoutPlanService {
  final ApiClient _apiClient;

  WorkoutPlanService(this._apiClient);

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<WorkoutPlan> createWorkout(WorkoutPlan plan) async {
    final response = await _apiClient.post('/api/workouts', body: plan.toJson());
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return WorkoutPlan.fromJson(data);
    }
    throw ApiException('create_failed', 'Failed to create workout: ${response.statusCode}');
  }

  Future<List<WorkoutPlan>> getMyWorkouts() async {
    final response = await _apiClient.get('/api/workouts/my');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => WorkoutPlan.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('fetch_failed', 'Failed to load workouts: ${response.statusCode}');
  }

  Future<List<WorkoutPlan>> getTemplates() async {
    final response = await _apiClient.get('/api/workouts/templates');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => WorkoutPlan.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('fetch_failed', 'Failed to load templates: ${response.statusCode}');
  }

  Future<WorkoutPlan> getWorkout(String id) async {
    final response = await _apiClient.get('/api/workouts/$id');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return WorkoutPlan.fromJson(data);
    }
    throw ApiException('not_found', 'Workout not found: ${response.statusCode}');
  }

  Future<WorkoutPlan> updateWorkout(String id, WorkoutPlan plan) async {
    final response = await _apiClient.patch('/api/workouts/$id', body: plan.toJson());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return WorkoutPlan.fromJson(data);
    }
    throw ApiException('update_failed', 'Failed to update workout: ${response.statusCode}');
  }

  Future<void> deleteWorkout(String id) async {
    final response = await _apiClient.delete('/api/workouts/$id');
    if (response.statusCode != 200) {
      throw ApiException('delete_failed', 'Failed to delete workout: ${response.statusCode}');
    }
  }

  // ── Favorite ─────────────────────────────────────────────────────────────

  Future<WorkoutPlan> toggleFavorite(String id) async {
    final response = await _apiClient.patch('/api/workouts/$id/favorite');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return WorkoutPlan.fromJson(data);
    }
    throw ApiException('favorite_failed', 'Failed to toggle favorite: ${response.statusCode}');
  }

  // ── Sharing ──────────────────────────────────────────────────────────────

  Future<void> shareWorkout(String id, List<String> recipientIds) async {
    final response = await _apiClient.post(
      '/api/workouts/$id/share',
      body: {'recipientIds': recipientIds},
    );
    if (response.statusCode != 201) {
      throw ApiException('share_failed', 'Failed to share workout: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> getReceivedShares() async {
    final response = await _apiClient.get('/api/workouts/shares/received');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw ApiException('fetch_failed', 'Failed to load shares: ${response.statusCode}');
  }

  Future<WorkoutPlan> acceptShare(String shareId) async {
    final response = await _apiClient.post('/api/workouts/shares/$shareId/accept');
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return WorkoutPlan.fromJson(data);
    }
    throw ApiException('accept_failed', 'Failed to accept share: ${response.statusCode}');
  }

  // ── Save as template ──────────────────────────────────────────────────────

  /// Mark workout as template. Updates in place if it already exists, otherwise creates new.
  Future<WorkoutPlan> saveAsTemplate(WorkoutPlan plan) async {
    if (plan.id != null) {
      return updateWorkout(plan.id!, plan.copyWith(isTemplate: true));
    }
    return createWorkout(plan.copyWith(isTemplate: true));
  }
}
