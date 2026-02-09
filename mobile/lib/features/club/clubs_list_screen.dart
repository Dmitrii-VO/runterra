import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_model.dart';

/// Screen showing all clubs for a given city.
class ClubsListScreen extends StatefulWidget {
  final String cityId;

  const ClubsListScreen({super.key, required this.cityId});

  @override
  State<ClubsListScreen> createState() => _ClubsListScreenState();
}

class _ClubsListScreenState extends State<ClubsListScreen> {
  late Future<List<ClubModel>> _clubsFuture;

  @override
  void initState() {
    super.initState();
    _clubsFuture = ServiceLocator.clubsService.getClubs(cityId: widget.cityId);
  }

  void _retry() {
    setState(() {
      _clubsFuture = ServiceLocator.clubsService.getClubs(cityId: widget.cityId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clubsListTitle),
      ),
      body: FutureBuilder<List<ClubModel>>(
        future: _clubsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final err = snapshot.error;
            final message = err is ApiException
                ? err.message
                : err.toString();
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

          final clubs = snapshot.data ?? [];
          if (clubs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.clubsListEmpty,
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
              return ListTile(
                leading: const Icon(Icons.groups),
                title: Text(club.name),
                subtitle: club.description != null && club.description!.isNotEmpty
                    ? Text(
                        club.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
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
