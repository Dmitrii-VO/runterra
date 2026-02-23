import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/profile_model.dart';
import '../../shared/ui/profile/header_section.dart';
import '../../shared/ui/profile/stats_section.dart';
import '../../shared/ui/profile/activity_section.dart';
import '../../shared/ui/profile/quick_actions_section.dart';
import '../../shared/ui/profile/personal_info_section.dart';
import '../../shared/ui/profile/notifications_section.dart';
import '../city/city_picker_dialog.dart';

/// Profile screen - Личный кабинет пользователя
///
/// Отображает все данные личного кабинета согласно требованиям MVP:
/// 1. Идентификация пользователя (имя, фото, статус, клуб)
/// 2. Мини-статистика (тренировки, территории, баллы)
/// 3. Ближайшая и последняя активности
/// 4. Быстрые действия (CTA)
/// 5. Уведомления
/// Настройки (геолокация, видимость, выход, удаление) — в «Редактирование профиля».
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileModel> _profileFuture;
  bool? _hasTrainerProfile;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _loadTrainerProfile();
  }

  Future<void> _loadTrainerProfile() async {
    try {
      final p = await ServiceLocator.trainerService.getMyProfile();
      if (mounted) setState(() => _hasTrainerProfile = p != null);
    } catch (_) {
      if (mounted) setState(() => _hasTrainerProfile = false);
    }
  }

  /// Создает Future для получения данных профиля
  Future<ProfileModel> _fetchProfile() async {
    final profile = await ServiceLocator.usersService.getProfile();

    // Keep local currentClubId in sync with backend profile contract:
    // if backend does not return club object, user is considered not in a club.
    final currentClubId = ServiceLocator.currentClubService.currentClubId;
    if (profile.club != null &&
        (currentClubId == null || currentClubId != profile.club!.id)) {
      await ServiceLocator.currentClubService.setCurrentClubId(profile.club!.id);
    }
    if (profile.club == null &&
        currentClubId != null &&
        currentClubId.isNotEmpty) {
      await ServiceLocator.currentClubService.setCurrentClubId(null);
    }

    return profile;
  }
  
  /// Reload profile data
  void _retry() {
    setState(() {
      _profileFuture = _fetchProfile();
    });
    _loadTrainerProfile();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<ProfileModel>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final hasData = snapshot.hasData;
        final profile = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.profileTitle),
            actions: [
              if (hasData && profile != null)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.editProfileEditAction,
                  onPressed: () async {
                    final result = await context.push<bool>(
                      '/profile/edit',
                      extra: profile,
                    );
                    if (result == true && context.mounted) _retry();
                  },
                ),
            ],
          ),
          body: _buildBody(context, snapshot, l10n),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<ProfileModel> snapshot,
    AppLocalizations l10n,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      final err = snapshot.error;
      String userMessage;
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
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!snapshot.hasData) {
      return Center(child: Text(l10n.profileNotFound));
    }

    final profile = snapshot.data!;
    final activeClubId = profile.club?.id ?? ServiceLocator.currentClubService.currentClubId;
    final activeClubName = profile.club?.name;
    final myClubLabel = l10n.filtersMyClub.replaceAll('🏃', '').trim();

    return ListView(
      children: [
        ProfileHeaderSection(user: profile.user),
        ProfilePersonalInfoSection(user: profile.user),
        if (activeClubId != null && activeClubId.isNotEmpty)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.groups),
              title: Text(myClubLabel),
              subtitle: activeClubName != null && activeClubName.isNotEmpty
                  ? Text(activeClubName)
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/club/$activeClubId'),
            ),
          ),
        ProfileStatsSection(stats: profile.stats),
        _CitySection(
          currentCityId: profile.user.cityId,
          currentCityName: profile.user.cityName ?? profile.user.cityId,
          onCitySelected: () => _retry(),
        ),
        ProfileActivitySection(
          nextActivity: profile.nextActivity,
          lastActivity: profile.lastActivity,
        ),
        ProfileQuickActionsSection(
          hasClub: profile.club != null,
          isMercenary: profile.user.isMercenary,
        ),
        if (_hasTrainerProfile == true)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sports),
                  title: Text(l10n.trainerProfile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/trainer/${profile.user.id}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: Text(l10n.trainerEditProfile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/trainer/edit'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(l10n.workouts),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/workouts'),
                ),
              ],
            ),
          ),
        // Find Trainers entry
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.search),
            title: Text(l10n.findTrainers),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/trainers'),
          ),
        ),
        ProfileNotificationsSection(notifications: profile.notifications),
      ],
    );
  }

}

/// Блок «Город» в личном кабинете: отображает текущий город, по нажатию — выбор города.
class _CitySection extends StatelessWidget {
  const _CitySection({
    required this.currentCityId,
    this.currentCityName,
    required this.onCitySelected,
  });

  final String? currentCityId;
  final String? currentCityName;
  final VoidCallback onCitySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayText = (currentCityName != null && currentCityName!.isNotEmpty)
        ? currentCityName!
        : (currentCityId != null && currentCityId!.isNotEmpty
            ? currentCityId!
            : l10n.cityNotSelected);
    return ListTile(
      leading: const Icon(Icons.location_city),
      title: Text(l10n.cityLabel),
      subtitle: Text(displayText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final selected = await showCityPickerDialog(context);
        if (selected == null || !context.mounted) return;
        try {
          await ServiceLocator.usersService.updateProfile(currentCityId: selected);
          await ServiceLocator.currentCityService.setCurrentCityId(selected);
          if (context.mounted) onCitySelected();
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.profileCityRequired)),
            );
          }
        }
      },
    );
  }
}
