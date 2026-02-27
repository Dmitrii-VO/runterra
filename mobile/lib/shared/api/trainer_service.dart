import 'dart:convert';
import 'api_client.dart';
import 'users_service.dart' show ApiException;
import '../models/trainer_profile.dart';

/// Service for trainer profile API
class TrainerService {
  final ApiClient _apiClient;

  TrainerService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /api/trainer — public trainer discovery (accepts_private_clients=true)
  Future<List<PublicTrainerEntry>> getTrainers({
    String? cityId,
    String? specialization,
  }) async {
    final params = <String, String>{};
    if (cityId != null) params['cityId'] = cityId;
    if (specialization != null) params['specialization'] = specialization;
    final query = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';
    final response = await _apiClient.get('/api/trainer$query');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => PublicTrainerEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwApiException(response, 'get_trainers_error');
  }

  /// GET /api/trainer/profile — own profile
  Future<TrainerProfile?> getMyProfile() async {
    final response = await _apiClient.get('/api/trainer/profile');
    if (response.statusCode == 404) return null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return TrainerProfile.fromJson(json);
    }
    _throwApiException(response, 'get_trainer_profile_error');
  }

  /// GET /api/trainer/profile/:userId — public profile
  Future<TrainerProfile?> getProfile(String userId) async {
    final response = await _apiClient.get('/api/trainer/profile/$userId');
    if (response.statusCode == 404) return null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return TrainerProfile.fromJson(json);
    }
    _throwApiException(response, 'get_trainer_profile_error');
  }

  /// POST /api/trainer/profile — create profile
  Future<TrainerProfile> createProfile({
    String? bio,
    required List<String> specialization,
    required int experienceYears,
    List<Map<String, dynamic>>? certificates,
    bool acceptsPrivateClients = false,
  }) async {
    final response = await _apiClient.post(
      '/api/trainer/profile',
      body: {
        if (bio != null) 'bio': bio,
        'specialization': specialization,
        'experienceYears': experienceYears,
        if (certificates != null) 'certificates': certificates,
        'acceptsPrivateClients': acceptsPrivateClients,
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return TrainerProfile.fromJson(json);
    }
    _throwApiException(response, 'create_trainer_profile_error');
  }

  /// PATCH /api/trainer/profile — update profile
  Future<TrainerProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/api/trainer/profile', body: data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return TrainerProfile.fromJson(json);
    }
    _throwApiException(response, 'update_trainer_profile_error');
  }

  /// POST /api/trainer/clients/:userId — add a client
  Future<void> addClient(String userId) async {
    final response = await _apiClient.post('/api/trainer/clients/$userId', body: {});
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwApiException(response, 'add_client_error');
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
