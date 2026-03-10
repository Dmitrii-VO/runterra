import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../shared/models/my_club_model.dart';

class MyClubsScreen extends StatefulWidget {
  const MyClubsScreen({super.key});

  @override
  State<MyClubsScreen> createState() => _MyClubsScreenState();
}

class _MyClubsScreenState extends State<MyClubsScreen> {
  late Future<List<MyClubModel>> _myClubsFuture;

  @override
  void initState() {
    super.initState();
    _myClubsFuture = _loadMyClubs();
  }

  Future<List<MyClubModel>> _loadMyClubs() {
    return ServiceLocator.clubsService.getMyClubs();
  }

  void _retry() {
    setState(() {
      _myClubsFuture = _loadMyClubs();
    });
  }

  String _roleLabel(AppLocalizations l10n, String role) {
    switch (role) {
      case 'leader':
        return l10n.roleLeader;
      case 'trainer':
        return l10n.roleTrainer;
      default:
        return l10n.roleMember;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cityId = ServiceLocator.currentCityService.currentCityId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileMyClubsTitle),
      ),
      body: FutureBuilder<List<MyClubModel>>(
        future: _myClubsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final err = snapshot.error;
            final message = err is ApiException
                ? l10n.profileMyClubsLoadError(err.message)
                : l10n.errorGeneric(err.toString());
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final allClubs = snapshot.data ?? const <MyClubModel>[];
          // Section A: member/leader clubs; Section C: trainer clubs
          final memberClubs =
              allClubs.where((c) => c.role != 'trainer').toList();
          final trainerClubs =
              allClubs.where((c) => c.role == 'trainer').toList();

          return ListView(
            children: [
              // Section A — my clubs
              _SectionHeader(title: l10n.myClubsMySection),
              if (memberClubs.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    l10n.profileMyClubsEmpty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...memberClubs.map((club) => _ClubTile(
                      club: club,
                      roleLabel: _roleLabel(l10n, club.role),
                    )),

              // Section B — find a club
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.search),
                title: Text(l10n.myClubsFind),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (cityId != null && cityId.isNotEmpty) {
                    context.push('/clubs?cityId=$cityId');
                  } else {
                    context.push('/clubs');
                  }
                },
              ),

              // Section C — clubs where I'm a trainer (only shown if non-empty)
              if (trainerClubs.isNotEmpty) ...[
                const Divider(height: 1),
                _SectionHeader(title: l10n.myClubsAsTrainer),
                ...trainerClubs.map((club) => _ClubTile(
                      club: club,
                      roleLabel: _roleLabel(l10n, club.role),
                    )),
              ],

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ClubTile extends StatelessWidget {
  const _ClubTile({required this.club, required this.roleLabel});
  final MyClubModel club;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final city = (club.cityName?.isNotEmpty == true)
        ? club.cityName!
        : club.cityId;
    final l10n = AppLocalizations.of(context)!;
    final subtitle =
        '${city.isNotEmpty ? city : l10n.profileNotSpecified} • $roleLabel';

    return ListTile(
      leading: const Icon(Icons.groups),
      title: Text(club.name),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/club/${club.id}'),
    );
  }
}
