import 'dart:convert';
import 'api_client.dart';
import 'users_service.dart' show ApiException;
import '../models/club_model.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ РєР»СѓР±Р°РјРё
/// 
/// РџСЂРµРґРѕСЃС‚Р°РІР»СЏРµС‚ РјРµС‚РѕРґС‹ РґР»СЏ РІС‹РїРѕР»РЅРµРЅРёСЏ Р·Р°РїСЂРѕСЃРѕРІ Рє API РєР»СѓР±РѕРІ.
/// РСЃРїРѕР»СЊР·СѓРµС‚ ApiClient РґР»СЏ РІС‹РїРѕР»РЅРµРЅРёСЏ HTTP Р·Р°РїСЂРѕСЃРѕРІ.
class ClubsService {
  final ApiClient _apiClient;

  /// РЎРѕР·РґР°РµС‚ ClubsService СЃ СѓРєР°Р·Р°РЅРЅС‹Рј ApiClient
  ClubsService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Р’С‹РїРѕР»РЅСЏРµС‚ GET /api/clubs Р·Р°РїСЂРѕСЃ Рє backend
  /// 
  /// Р’РѕР·РІСЂР°С‰Р°РµС‚ СЃРїРёСЃРѕРє РєР»СѓР±РѕРІ (List<ClubModel>).
  /// РџР°СЂСЃРёС‚ JSON РѕС‚РІРµС‚ Рё РїСЂРµРѕР±СЂР°Р·СѓРµС‚ РµРіРѕ РІ С‚РёРїРёР·РёСЂРѕРІР°РЅРЅС‹Рµ РјРѕРґРµР»Рё.
  Future<List<ClubModel>> getClubs({required String cityId}) async {
    final uri = Uri(
      path: '/api/clubs',
      queryParameters: {'cityId': cityId},
    );
    final response = await _apiClient.get(uri.toString());

    if (response.statusCode != 200) {
      throw Exception(
        'РћС€РёР±РєР° СЃРµСЂРІРµСЂР°: ${response.statusCode}\n'
        'РЈР±РµРґРёС‚РµСЃСЊ, С‡С‚Рѕ backend СЃРµСЂРІРµСЂ Р·Р°РїСѓС‰РµРЅ (npm run dev РІ РїР°РїРєРµ backend)',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        throw FormatException(
          'РџРѕР»СѓС‡РµРЅ HTML РІРјРµСЃС‚Рѕ JSON. Backend СЃРµСЂРІРµСЂ РЅРµ Р·Р°РїСѓС‰РµРЅ РёР»Рё СЂРѕСѓС‚РµСЂ РЅРµ Р·Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°РЅ.',
          response.body.substring(0, response.body.length > 200 ? 200 : response.body.length),
        );
      }
      throw FormatException(
        'РћР¶РёРґР°Р»СЃСЏ JSON, РЅРѕ РїРѕР»СѓС‡РµРЅ $contentType',
        response.body.substring(0, response.body.length > 100 ? 100 : response.body.length),
      );
    }

    try {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData.map((json) => ClubModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is FormatException && response.body.trim().startsWith('<!DOCTYPE')) {
        throw FormatException(
          'РџРѕР»СѓС‡РµРЅ HTML РІРјРµСЃС‚Рѕ JSON. Backend СЃРµСЂРІРµСЂ РЅРµ Р·Р°РїСѓС‰РµРЅ РёР»Рё СЂРѕСѓС‚РµСЂ РЅРµ Р·Р°СЂРµРіРёСЃС‚СЂРёСЂРѕРІР°РЅ.',
          response.body.substring(0, 200),
        );
      }
      rethrow;
    }
  }

  /// Р’С‹РїРѕР»РЅСЏРµС‚ GET /api/clubs/:id Р·Р°РїСЂРѕСЃ Рє backend
  /// 
  /// Р’РѕР·РІСЂР°С‰Р°РµС‚ РєР»СѓР± РїРѕ СѓРєР°Р·Р°РЅРЅРѕРјСѓ id (ClubModel).
  /// РџР°СЂСЃРёС‚ JSON РѕС‚РІРµС‚ Рё РїСЂРµРѕР±СЂР°Р·СѓРµС‚ РµРіРѕ РІ С‚РёРїРёР·РёСЂРѕРІР°РЅРЅСѓСЋ РјРѕРґРµР»СЊ.
  /// 
  /// [id] - СѓРЅРёРєР°Р»СЊРЅС‹Р№ РёРґРµРЅС‚РёС„РёРєР°С‚РѕСЂ РєР»СѓР±Р°
  Future<ClubModel> getClubById(String id) async {
    final response = await _apiClient.get('/api/clubs/${Uri.encodeComponent(id)}');

    if (response.statusCode != 200) {
      String errorCode = 'club_fetch_error';
      String errorMessage = 'Failed to load club (${response.statusCode})';
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

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw ApiException('invalid_response', 'Server returned non-JSON response');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return ClubModel.fromJson(jsonData);
  }

  /// Р’С‹РїРѕР»РЅСЏРµС‚ POST /api/clubs вЂ” СЃРѕР·РґР°РЅРёРµ РєР»СѓР±Р°.
  ///
  /// Р’РѕР·РІСЂР°С‰Р°РµС‚ СЃРѕР·РґР°РЅРЅС‹Р№ РєР»СѓР± (ClubModel).
  /// Р‘СЂРѕСЃР°РµС‚ [ApiException] РїСЂРё 4xx/5xx РёР»Рё РЅРµ-JSON РѕС‚РІРµС‚Рµ.
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
      } on FormatException {
        // Non-JSON response
      }
      throw ApiException(errorCode, errorMessage);
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw ApiException(
        'invalid_response',
        'Server returned non-JSON. Status: ${response.statusCode}',
      );
    }
    try {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return ClubModel.fromJson(jsonData);
    } catch (e) {
      if (e is ApiException) rethrow;
      rethrow;
    }
  }

  /// Р’С‹РїРѕР»РЅСЏРµС‚ POST /api/clubs/:id/join вЂ” РїСЂРёСЃРѕРµРґРёРЅРµРЅРёРµ С‚РµРєСѓС‰РµРіРѕ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ Рє РєР»СѓР±Сѓ.
  /// Р‘СЂРѕСЃР°РµС‚ [ApiException] РїСЂРё 4xx/5xx СЃ code Рё message РёР· РѕС‚РІРµС‚Р°.
  Future<void> joinClub(String clubId) async {
    final response = await _apiClient.post('/api/clubs/$clubId/join');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String errorCode = 'join_club_error';
    String errorMessage = 'Failed to join club (${response.statusCode})';
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

  /// Р’С‹РїРѕР»РЅСЏРµС‚ POST /api/clubs/:id/leave вЂ” РІС‹С…РѕРґ РёР· РєР»СѓР±Р°.
  /// Р‘СЂРѕСЃР°РµС‚ [ApiException] РїСЂРё 4xx/5xx СЃ code Рё message РёР· РѕС‚РІРµС‚Р°.
  Future<void> leaveClub(String clubId) async {
    final response = await _apiClient.post('/api/clubs/$clubId/leave');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String errorCode = 'leave_club_error';
    String errorMessage = 'Failed to leave club (${response.statusCode})';
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
