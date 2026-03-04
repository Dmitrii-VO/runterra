import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart';
import '../../shared/auth/auth_service.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/profile_model.dart';
import '../../shared/models/trainer_profile.dart';
import '../../shared/ui/profile/stats_section.dart';
import '../../shared/ui/profile/activity_section.dart';
import '../../shared/ui/profile/quick_actions_section.dart';
import '../../shared/ui/profile/personal_info_section.dart';
import '../../shared/ui/profile/notifications_section.dart';
import '../city/city_picker_dialog.dart';

/// Profile screen — personal account of the current user.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileModel> _profileFuture;
  TrainerProfile? _trainerProfile;

  Future<ProfileModel> _loadAll() {
    _loadTrainerProfile();
    return _fetchProfile();
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadAll();
  }

  Future<void> _loadTrainerProfile() async {
    try {
      final p = await ServiceLocator.trainerService.getMyProfile();
      if (mounted) setState(() => _trainerProfile = p);
    } on ApiException catch (_) {
      if (mounted) setState(() => _trainerProfile = null);
    } catch (_) {
      if (mounted) setState(() => _trainerProfile = null);
    }
  }

  Future<ProfileModel> _fetchProfile() async {
    try {
      final profile = await ServiceLocator.usersService.getProfile();

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
    } on ApiException catch (e) {
      if (e.code == 'unauthorized' && mounted) {
        try {
          await ServiceLocator.refreshAuthToken();
          return await ServiceLocator.usersService.getProfile();
        } on ApiException catch (retryErr) {
          if (retryErr.code == 'unauthorized' && mounted) {
            context.go('/login');
            rethrow;
          }
        }
      }
      rethrow;
    }
  }

  void _retry() {
    setState(() {
      _profileFuture = _loadAll();
    });
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (mounted) {
      context.go('/login');
    }
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
          body: _buildBody(context, snapshot, l10n, hasData, profile),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<ProfileModel> snapshot,
    AppLocalizations l10n,
    bool hasData,
    ProfileModel? profile,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      final err = snapshot.error;
      String userMessage;
      bool isUnauthorized = false;

      if (err is ApiException) {
        if (err.code == 'unauthorized') {
          isUnauthorized = true;
          userMessage = l10n.errorUnauthorizedMessage;
        } else {
          userMessage = '${err.code}\n\n${err.message}';
        }
      } else if (err is SocketException) {
        userMessage = l10n.profileConnectionError;
      } else {
        final s = err.toString();
        if (s.contains('connection refused')) {
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
                Icon(
                  isUnauthorized ? Icons.lock_outline : Icons.error_outline,
                  size: 48,
                  color: isUnauthorized ? Colors.orange : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  isUnauthorized ? l10n.errorUnauthorizedTitle : l10n.errorLoadTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  userMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: isUnauthorized ? _logout : _retry,
                  icon: Icon(isUnauthorized ? Icons.login : Icons.refresh),
                  label: Text(isUnauthorized ? l10n.errorUnauthorizedAction : l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!hasData || profile == null) {
      return Center(child: Text(l10n.profileNotFound));
    }

    final activeClubId = profile.club?.id ?? ServiceLocator.currentClubService.currentClubId;
    final activeClubName = profile.club?.name;
    final myClubLabel = l10n.profileMyClub;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          floating: false,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: _ProfileHeroHeader(user: profile.user),
          ),
          title: Text(l10n.profileTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.editProfileEditAction,
              onPressed: () async {
                final result = await context.push<bool>(
                  '/profile/edit',
                  extra: profile.user,
                );
                if (result == true && context.mounted) _retry();
              },
            ),
          ],
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            ProfileStatsSection(stats: profile.stats),
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
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(l10n.workouts),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/workouts'),
              ),
            ),
            if (_trainerProfile?.acceptsPrivateClients == true ||
                profile.club?.role == 'trainer' ||
                profile.club?.role == 'leader')
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.sports),
                  title: Text(l10n.trainerProfile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/trainer/${profile.user.id}'),
                ),
              ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.person_search_outlined),
                title: Text(l10n.findPeople),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/people'),
              ),
            ),
            ProfileNotificationsSection(notifications: profile.notifications),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }
}

/// Expandable hero header shown in SliverAppBar.flexibleSpace.
/// Displays avatar, display name, and optional status chip.
class _ProfileHeroHeader extends StatelessWidget {
  const _ProfileHeroHeader({required this.user});

  final ProfileUserData user;

  String get _displayName {
    final parts = <String>[];
    if (user.firstName != null && user.firstName!.isNotEmpty) parts.add(user.firstName!);
    if (user.lastName != null && user.lastName!.isNotEmpty) parts.add(user.lastName!);
    return parts.isNotEmpty ? parts.join(' ') : user.name;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Dark gradient overlay at the bottom for text legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
          // Content: avatar + name
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundImage:
                        user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    onForegroundImageError:
                        user.avatarUrl != null ? (_, __) {} : null,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 28,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (user.status.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(
                        user.status,
                        style: const TextStyle(fontSize: 11),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// City selection tile in the profile.
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
