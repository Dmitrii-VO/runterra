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
                    Text(
                      message,
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
            );
          }

          final clubs = snapshot.data ?? const <MyClubModel>[];
          if (clubs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.profileMyClubsEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: clubs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final club = clubs[index];
              final city = club.cityName?.isNotEmpty == true
                  ? club.cityName!
                  : club.cityId;
              final subtitle =
                  '${city.isNotEmpty ? city : l10n.profileNotSpecified} • ${_roleLabel(l10n, club.role)}';
              return ListTile(
                leading: const Icon(Icons.groups),
                title: Text(club.name),
                subtitle: Text(subtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/club/${club.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
