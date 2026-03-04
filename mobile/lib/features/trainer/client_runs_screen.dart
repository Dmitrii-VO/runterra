import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/client_run_model.dart';

/// Screen showing a client's completed runs, accessible by the trainer
class ClientRunsScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const ClientRunsScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<ClientRunsScreen> createState() => _ClientRunsScreenState();
}

class _ClientRunsScreenState extends State<ClientRunsScreen> {
  late Future<List<ClientRunModel>> _runsFuture;

  @override
  void initState() {
    super.initState();
    _runsFuture = ServiceLocator.trainerService.getClientRuns(widget.clientId);
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '$meters m';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.clientName} — ${l10n.clientRunsTitle}'),
      ),
      body: FutureBuilder<List<ClientRunModel>>(
        future: _runsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.errorLoadTitle),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _runsFuture = ServiceLocator.trainerService
                          .getClientRuns(widget.clientId);
                    }),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          final runs = snapshot.data ?? [];
          if (runs.isEmpty) {
            return Center(child: Text(l10n.clientRunsEmpty));
          }

          return ListView.builder(
            itemCount: runs.length,
            itemBuilder: (context, index) {
              final run = runs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_run, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(run.startedAt),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const Spacer(),
                          Text(
                            _formatDuration(run.duration),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        children: [
                          _Stat(
                            label: l10n.clientRunsDistance,
                            value: _formatDistance(run.distance),
                          ),
                          if (run.rpe != null)
                            _Stat(
                              label: l10n.clientRunsRpe,
                              value: '${run.rpe}/10',
                            ),
                        ],
                      ),
                      if (run.workoutTitle != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.fitness_center, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${l10n.clientRunsAssignment}: ${run.workoutTitle}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.blue),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (run.notes != null && run.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          run.notes!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
