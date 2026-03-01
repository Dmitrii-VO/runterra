import 'package:flutter/material.dart';
import '../models/user_nav_status.dart';
import '../di/service_locator.dart';
import '../auth/auth_service.dart';

/// Notifier to manage dynamic navigation status (visibility of tabs).
/// 
/// Fetches [UserNavStatus] from backend when user is authenticated
/// and provides it to the [BottomNav] widget.
class UserNavStatusNotifier extends ValueNotifier<UserNavStatus> {
  static final UserNavStatusNotifier _instance = UserNavStatusNotifier._internal();

  factory UserNavStatusNotifier() => _instance;

  UserNavStatusNotifier._internal() : super(UserNavStatus.initial()) {
    // Refresh status when auth state changes (e.g. login)
    AuthService.instance.authStateChanges.listen((user) {
      if (user != null) {
        refresh();
      } else {
        value = UserNavStatus.initial();
      }
    });
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Fetch latest status from backend.
  Future<void> refresh() async {
    if (!AuthService.instance.isAuthenticated) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final status = await ServiceLocator.usersService.getNavigationStatus();
      value = status;
    } catch (e) {
      debugPrint('Error refreshing NavStatus: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manually update status (e.g. after joining a club or hiring a coach)
  /// to provide immediate UI feedback without backend roundtrip.
  void update({bool? hasClubs, bool? hasTrainers}) {
    value = UserNavStatus(
      hasClubs: hasClubs ?? value.hasClubs,
      hasTrainers: hasTrainers ?? value.hasTrainers,
    );
  }
}
