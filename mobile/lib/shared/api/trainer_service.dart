import 'dart:convert';
import 'api_client.dart';
import 'users_service.dart' show ApiException;
import '../models/trainer_profile.dart';
import '../models/trainer_group_model.dart';
import '../models/client_run_model.dart';
import '../models/run_model.dart';
import '../navigation/nav_status_provider.dart';

export '../models/trainer_profile.dart' show TrainerClientRequest, MyTrainerEntry;

/// Service for trainer profile API
class TrainerService {
  final ApiClient _apiClient;

  TrainerService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// GET /api/trainer/groups — list own groups in a club
  Future<List<TrainerGroupModel>> getGroups(String clubId) async {
    final response = await _apiClient.get('/api/trainer/groups?clubId=$clubId');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => TrainerGroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwApiException(response, 'get_trainer_groups_error');
  }

  /// POST /api/trainer/groups — create a group
  Future<TrainerGroupModel> createGroup({
    required String clubId,
    required String name,
    List<String> memberIds = const [],
    String? trainerId,
  }) async {
    final response = await _apiClient.post(
      '/api/trainer/groups',
      body: {
        'clubId': clubId,
        'name': name,
        'memberIds': memberIds,
        if (trainerId != null) 'trainerId': trainerId,
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final group = TrainerGroupModel.fromJson(json);
      UserNavStatusNotifier().refresh();
      return group;
    }
    _throwApiException(response, 'create_trainer_group_error');
  }

  /// GET /api/trainer/groups/:groupId/members — get member IDs
  Future<List<String>> getGroupMemberIds(String groupId) async {
    final response = await _apiClient.get('/api/trainer/groups/$groupId/members');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.cast<String>();
    }
    _throwApiException(response, 'get_group_members_error');
  }

  /// PATCH /api/trainer/groups/:groupId — update group
  Future<void> updateGroup(String groupId, {String? name, List<String>? memberIds}) async {
    final response = await _apiClient.patch(
      '/api/trainer/groups/$groupId',
      body: {
        if (name != null) 'name': name,
        if (memberIds != null) 'memberIds': memberIds,
      },
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwApiException(response, 'update_group_error');
  }

  /// DELETE /api/trainer/groups/:groupId — delete group
  Future<void> deleteGroup(String groupId) async {
    final response = await _apiClient.delete('/api/trainer/groups/$groupId');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      UserNavStatusNotifier().refresh();
      return;
    }
    _throwApiException(response, 'delete_group_error');
  }

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
      final profile = TrainerProfile.fromJson(json);
      UserNavStatusNotifier().refresh();
      return profile;
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

  /// GET /api/trainer/clients/:clientId/runs — view client's completed runs
  Future<List<ClientRunModel>> getClientRuns(String clientId, {int limit = 50, int offset = 0}) async {
    final response = await _apiClient.get(
      '/api/trainer/clients/$clientId/runs?limit=$limit&offset=$offset',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => ClientRunModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwApiException(response, 'get_client_runs_error');
  }

  /// GET /api/trainer/clients/:clientId/runs/:runId — run detail with GPS for a client run
  Future<RunDetailModel> getClientRunDetail(String clientId, String runId) async {
    final response = await _apiClient.get(
      '/api/trainer/clients/$clientId/runs/$runId',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return RunDetailModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    _throwApiException(response, 'get_client_run_detail_error');
  }

  /// POST /api/trainer/clients/:userId — add a client
  Future<void> addClient(String userId) async {
    final response = await _apiClient.post('/api/trainer/clients/$userId', body: {});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      UserNavStatusNotifier().refresh();
      return;
    }
    _throwApiException(response, 'add_client_error');
  }

  // ---------------------------------------------------------------------------
  // Trainer-client relationship (CTA flow)
  // ---------------------------------------------------------------------------

  /// POST /api/trainer/:userId/request — submit a join request
  Future<void> requestToJoin(String trainerId) async {
    final response = await _apiClient.post('/api/trainer/$trainerId/request', body: {});
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwApiException(response, 'request_to_join_error');
  }

  /// DELETE /api/trainer/:userId/request — withdraw pending request
  Future<void> cancelRequest(String trainerId) async {
    final response = await _apiClient.delete('/api/trainer/$trainerId/request');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwApiException(response, 'cancel_request_error');
  }

  /// GET /api/trainer/:userId/request-status — current relationship status
  Future<String> getRequestStatus(String trainerId) async {
    final response = await _apiClient.get('/api/trainer/$trainerId/request-status');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['status'] as String? ?? 'none';
    }
    _throwApiException(response, 'get_request_status_error');
  }

  /// GET /api/trainer/requests — trainer sees incoming pending requests
  Future<List<TrainerClientRequest>> getTrainerRequests() async {
    final response = await _apiClient.get('/api/trainer/requests');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => TrainerClientRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwApiException(response, 'get_trainer_requests_error');
  }

  /// PATCH /api/trainer/requests/:id — accept or reject a request
  Future<void> respondToRequest(String id, String action) async {
    final response = await _apiClient.patch(
      '/api/trainer/requests/$id',
      body: {'action': action},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwApiException(response, 'respond_to_request_error');
  }

  /// GET /api/trainer/clients — trainer's active clients
  Future<List<TrainerClientRequest>> getTrainerClients() async {
    final response = await _apiClient.get('/api/trainer/clients');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => TrainerClientRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwApiException(response, 'get_trainer_clients_error');
  }

  /// GET /api/trainer/my-trainers — client's active trainers
  Future<List<MyTrainerEntry>> getMyTrainers() async {
    final response = await _apiClient.get('/api/trainer/my-trainers');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => MyTrainerEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    _throwApiException(response, 'get_my_trainers_error');
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
