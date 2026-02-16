import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/trainer_profile.dart';

/// Screen to view a trainer's public profile
class TrainerProfileScreen extends StatefulWidget {
  final String userId;

  const TrainerProfileScreen({super.key, required this.userId});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  late Future<TrainerProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ServiceLocator.trainerService.getProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerProfile)),
      body: FutureBuilder<TrainerProfile?>(
        future: _profileFuture,
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
                    onPressed: () {
                      setState(() {
                        _profileFuture = ServiceLocator.trainerService
                            .getProfile(widget.userId);
                      });
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          final profile = snapshot.data;
          if (profile == null) {
            return Center(child: Text(l10n.trainerProfileNotAvailable));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bio
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  Text(l10n.trainerBio,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(profile.bio!),
                  const SizedBox(height: 16),
                ],

                // Specialization chips
                Text(l10n.trainerSpecialization,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: profile.specialization
                      .map((s) => Chip(label: Text(_localizeSpec(l10n, s))))
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Experience
                Text(l10n.trainerExperience,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('${profile.experienceYears}'),
                const SizedBox(height: 16),

                // Certificates
                if (profile.certificates.isNotEmpty) ...[
                  Text(l10n.trainerCertificates,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...profile.certificates.map((cert) => Card(
                        child: ListTile(
                          title: Text(cert.name),
                          subtitle: Text([
                            if (cert.organization != null) cert.organization!,
                            if (cert.date != null) cert.date!,
                          ].join(' · ')),
                        ),
                      )),
                ],
              ],
            ),
          );
        },
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
