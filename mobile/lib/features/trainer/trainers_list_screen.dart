import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/trainer_profile.dart';

/// Discovery screen for finding private trainers
class TrainersListScreen extends StatefulWidget {
  const TrainersListScreen({super.key});

  @override
  State<TrainersListScreen> createState() => _TrainersListScreenState();
}

class _TrainersListScreenState extends State<TrainersListScreen> {
  late Future<List<PublicTrainerEntry>> _trainersFuture;
  String? _selectedSpec;

  static const _allSpecs = [
    'MARATHON',
    'SPRINT',
    'TRAIL',
    'RECOVERY',
    'GENERAL',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final cityId = ServiceLocator.currentCityService.currentCityId;
    _trainersFuture = ServiceLocator.trainerService.getTrainers(
      cityId: cityId,
      specialization: _selectedSpec,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.findTrainers)),
      body: Column(
        children: [
          // Specialization filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.filterAll),
                  selected: _selectedSpec == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedSpec = null;
                      _load();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ..._allSpecs.map((spec) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_localizeSpec(l10n, spec)),
                        selected: _selectedSpec == spec,
                        onSelected: (_) {
                          setState(() {
                            _selectedSpec = _selectedSpec == spec ? null : spec;
                            _load();
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<PublicTrainerEntry>>(
              future: _trainersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.trainersLoadError),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(_load),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }
                final trainers = snapshot.data ?? [];
                if (trainers.isEmpty) {
                  return Center(child: Text(l10n.trainersEmpty));
                }
                return ListView.builder(
                  itemCount: trainers.length,
                  itemBuilder: (context, index) {
                    final trainer = trainers[index];
                    return _TrainerCard(
                      trainer: trainer,
                      onTap: () => context.push('/trainer/${trainer.userId}'),
                      l10n: l10n,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _localizeSpec(AppLocalizations l10n, String spec) {
    switch (spec) {
      case 'MARATHON':
        return l10n.specMarathon;
      case 'SPRINT':
        return l10n.specSprint;
      case 'TRAIL':
        return l10n.specTrail;
      case 'RECOVERY':
        return l10n.specRecovery;
      case 'GENERAL':
        return l10n.specGeneral;
      default:
        return spec;
    }
  }
}

class _TrainerCard extends StatelessWidget {
  final PublicTrainerEntry trainer;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _TrainerCard({
    required this.trainer,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(
                  trainer.name.isNotEmpty ? trainer.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trainer.name,
                        style: Theme.of(context).textTheme.titleSmall),
                    if (trainer.bio != null && trainer.bio!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        trainer.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: trainer.specialization
                          .map((s) => Chip(
                                label: Text(_localizeSpec(s),
                                    style:
                                        const TextStyle(fontSize: 11)),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _localizeSpec(String spec) {
    switch (spec) {
      case 'MARATHON':
        return l10n.specMarathon;
      case 'SPRINT':
        return l10n.specSprint;
      case 'TRAIL':
        return l10n.specTrail;
      case 'RECOVERY':
        return l10n.specRecovery;
      case 'GENERAL':
        return l10n.specGeneral;
      default:
        return spec;
    }
  }
}
