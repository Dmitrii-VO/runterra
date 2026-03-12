import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/trainer_profile.dart';

/// Screen showing the current user's active trainers
class MyTrainersScreen extends StatefulWidget {
  const MyTrainersScreen({super.key});

  @override
  State<MyTrainersScreen> createState() => _MyTrainersScreenState();
}

class _MyTrainersScreenState extends State<MyTrainersScreen> {
  late Future<List<MyTrainerEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = ServiceLocator.trainerService.getMyTrainers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTrainersScreen)),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = ServiceLocator.trainerService.getMyTrainers();
          });
        },
        child: FutureBuilder<List<MyTrainerEntry>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l10n.errorLoadTitle),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _future = ServiceLocator.trainerService.getMyTrainers();
                      }),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }
            final trainers = snap.data ?? [];
            if (trainers.isEmpty) {
              return Center(child: Text(l10n.myTrainersEmpty));
            }
            return ListView.builder(
              itemCount: trainers.length,
              itemBuilder: (context, index) {
                final entry = trainers[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(entry.trainerName.isNotEmpty
                        ? entry.trainerName[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(entry.trainerName),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/trainer/${entry.trainerId}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
