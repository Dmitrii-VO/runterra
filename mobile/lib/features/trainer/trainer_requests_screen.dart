import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/trainer_profile.dart';

/// Screen for the trainer: incoming pending requests + active clients list
class TrainerRequestsScreen extends StatefulWidget {
  const TrainerRequestsScreen({super.key});

  @override
  State<TrainerRequestsScreen> createState() => _TrainerRequestsScreenState();
}

class _TrainerRequestsScreenState extends State<TrainerRequestsScreen> {
  late Future<List<TrainerClientRequest>> _requestsFuture;
  late Future<List<TrainerClientRequest>> _clientsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _requestsFuture = ServiceLocator.trainerService.getTrainerRequests();
    _clientsFuture = ServiceLocator.trainerService.getTrainerClients();
  }

  Future<void> _respond(String id, String action) async {
    try {
      await ServiceLocator.trainerService.respondToRequest(id, action);
      if (mounted) {
        setState(_load);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(action == 'accept'
              ? l10n.trainerRequestAccepted
              : l10n.trainerRequestRejectedMsg),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerRequestsScreen)),
      body: RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: CustomScrollView(
          slivers: [
            // Pending requests section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(l10n.trainerIncomingRequests,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            FutureBuilder<List<TrainerClientRequest>>(
              future: _requestsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final requests = snap.data ?? [];
                if (requests.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(l10n.trainerNoRequests,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final req = requests[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(req.clientName.isNotEmpty
                              ? req.clientName[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(req.clientName),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              tooltip: l10n.trainerAccept,
                              onPressed: () => _respond(req.id, 'accept'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              tooltip: l10n.trainerReject,
                              onPressed: () => _respond(req.id, 'reject'),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/user/${req.clientId}'),
                      );
                    },
                    childCount: requests.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: Divider()),

            // Active clients section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(l10n.trainerActiveClients,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            FutureBuilder<List<TrainerClientRequest>>(
              future: _clientsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final clients = snap.data ?? [];
                if (clients.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(l10n.trainerNoClientsYet,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final client = clients[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(client.clientName.isNotEmpty
                              ? client.clientName[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(client.clientName),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '/trainer/clients/${client.clientId}/runs',
                          extra: <String, String>{
                            'clientName': client.clientName,
                          },
                        ),
                      );
                    },
                    childCount: clients.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
