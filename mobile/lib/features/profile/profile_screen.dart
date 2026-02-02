import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart';
import '../../shared/auth/auth_service.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/profile_model.dart';
import '../../shared/ui/profile/header_section.dart';
import '../../shared/ui/profile/stats_section.dart';
import '../../shared/ui/profile/activity_section.dart';
import '../../shared/ui/profile/quick_actions_section.dart';
import '../../shared/ui/profile/notifications_section.dart';
import '../../shared/ui/profile/settings_section.dart';
import '../../app.dart';

/// Profile screen - Личный кабинет пользователя
/// 
/// Отображает все данные личного кабинета согласно требованиям MVP:
/// 1. Идентификация пользователя (имя, фото, статус, клуб)
/// 2. Мини-статистика (тренировки, территории, баллы)
/// 3. Ближайшая и последняя активности
/// 4. Быстрые действия (CTA)
/// 5. Уведомления
/// 6. Настройки
/// 
/// Минимальная реализация без state management, использует FutureBuilder.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileModel> _profileFuture;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _checkLocationPermission();
  }

  /// Создает Future для получения данных профиля
  Future<ProfileModel> _fetchProfile() async {
    return ServiceLocator.usersService.getProfile();
  }
  
  /// Reload profile data
  void _retry() {
    setState(() {
      _profileFuture = _fetchProfile();
    });
  }

  /// Проверяет статус разрешения геолокации
  Future<void> _checkLocationPermission() async {
    final locationService = ServiceLocator.locationService;
    final permission = await locationService.checkPermission();
    setState(() {
      _locationPermissionGranted = permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profileTitle),
      ),
      body: FutureBuilder<ProfileModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            final err = snapshot.error;
            String userMessage;

            final l10n = AppLocalizations.of(context)!;
            if (err is ApiException) {
              userMessage = '${err.code}\n\n${err.message}';
            } else {
              final s = err.toString();
              if (s.contains('SocketException') ||
                  s.contains('connection refused') ||
                  s.contains('отклонил это сетевое подключение')) {
                userMessage = l10n.profileConnectionError;
              } else {
                userMessage = l10n.errorGeneric(s);
              }
            }

            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        userMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(AppLocalizations.of(context)!.profileNotFound),
            );
          }

          final profile = snapshot.data!;

          return ListView(
            children: [
              // 1. Заголовок профиля
              ProfileHeaderSection(
                user: profile.user,
                club: profile.club,
              ),

              // 2. Мини-статистика
              ProfileStatsSection(stats: profile.stats),

              // 3. Ближайшая и последняя активности
              ProfileActivitySection(
                nextActivity: profile.nextActivity,
                lastActivity: profile.lastActivity,
              ),

              // 4. Быстрые действия (CTA)
              ProfileQuickActionsSection(
                hasClub: profile.club != null,
                isMercenary: profile.user.isMercenary,
              ),

              // 5. Уведомления
              ProfileNotificationsSection(
                notifications: profile.notifications,
              ),

              // 6. Настройки
              ProfileSettingsSection(
                locationPermissionGranted: _locationPermissionGranted,
                profileVisible: true, // TODO: Загружать из профиля
                onLogout: () async {
                  // Показываем диалог подтверждения
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return AlertDialog(
                        title: Text(l10n.logoutTitle),
                        content: Text(l10n.logoutConfirm),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(l10n.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(l10n.logout),
                          ),
                        ],
                      );
                    },
                  );
                  
                  if (confirm == true && context.mounted) {
                    await AuthService.instance.signOut();
                    ServiceLocator.updateAuthToken(null);
                    authRefreshNotifier.refresh();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
                onDeleteAccount: () {
                  // TODO: Реализовать удаление аккаунта
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
