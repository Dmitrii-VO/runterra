import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/users_service.dart';
import '../models/profile_model.dart';

/// Сервис для хранения текущего (основного) клуба пользователя.
///
/// Источники правды:
/// - backend профиль (`ProfileUserData.primaryClubId`);
/// - локальное хранилище (SharedPreferences);
/// - обновляется при присоединении к клубу (ClubDetailsScreen после join).
class CurrentClubService extends ChangeNotifier {
  static const _storageKeyCurrentClubId = 'currentClubId';

  final UsersService _usersService;

  String? _currentClubId;
  bool _initialized = false;

  CurrentClubService({required UsersService usersService}) : _usersService = usersService;

  bool get isInitialized => _initialized;

  String? get currentClubId => _currentClubId;

  /// Загружает текущий клуб из хранилища и синхронизирует с профилем.
  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _currentClubId = prefs.getString(_storageKeyCurrentClubId);

    try {
      final ProfileModel profile = await _usersService.getProfile();
      final String? profileClubId = profile.user.primaryClubId;
      if (profileClubId != null && profileClubId.isNotEmpty) {
        _currentClubId = profileClubId;
        await prefs.setString(_storageKeyCurrentClubId, profileClubId);
      }
    } catch (_) {
      // Профиль может быть недоступен — используем только локальное значение.
    }

    _initialized = true;
    notifyListeners();
  }

  /// Устанавливает текущий клуб (например после присоединения к клубу).
  Future<void> setCurrentClubId(String? clubId) async {
    _currentClubId = clubId;
    final prefs = await SharedPreferences.getInstance();
    if (clubId != null) {
      await prefs.setString(_storageKeyCurrentClubId, clubId);
    } else {
      await prefs.remove(_storageKeyCurrentClubId);
    }
    notifyListeners();
  }
}
