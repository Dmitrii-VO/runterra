import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/trainer_profile.dart';
import '../../shared/models/profile_model.dart';

/// Screen to view a trainer's public profile
class TrainerProfileScreen extends StatefulWidget {
  final String userId;

  const TrainerProfileScreen({super.key, required this.userId});

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  late Future<TrainerProfile?> _profileFuture;
  late Future<ProfileModel> _meFuture;
  late Future<String> _statusFuture;
  bool _statusLoading = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = ServiceLocator.trainerService.getProfile(widget.userId);
    _meFuture = ServiceLocator.usersService.getProfile();
    _statusFuture = ServiceLocator.trainerService.getRequestStatus(widget.userId);
  }

  void _reloadStatus() {
    setState(() {
      _statusFuture = ServiceLocator.trainerService.getRequestStatus(widget.userId);
    });
  }

  Future<void> _handleRequest(String currentStatus) async {
    setState(() => _statusLoading = true);
    try {
      if (currentStatus == 'none' || currentStatus == 'rejected') {
        await ServiceLocator.trainerService.requestToJoin(widget.userId);
      } else if (currentStatus == 'pending') {
        await ServiceLocator.trainerService.cancelRequest(widget.userId);
      }
      if (mounted) _reloadStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainerProfile),
        actions: [
          FutureBuilder<ProfileModel>(
            future: _meFuture,
            builder: (context, meSnap) {
              final meId = meSnap.data?.user.id;
              final isMe = meId != null && meId == widget.userId;
              if (!isMe) return const SizedBox.shrink();

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.people),
                    tooltip: l10n.trainerRequestsScreen,
                    onPressed: () => context.push('/trainer/requests'),
                  ),
                  FutureBuilder<TrainerProfile?>(
                    future: _profileFuture,
                    builder: (context, profileSnap) {
                      final profile = profileSnap.data;
                      if (profile == null) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: l10n.trainerEditProfile,
                        onPressed: () async {
                          final result = await context.push<bool>(
                            '/trainer/edit',
                            extra: profile,
                          );
                          if (result == true && mounted) {
                            setState(() {
                              _profileFuture = ServiceLocator.trainerService
                                  .getProfile(widget.userId);
                            });
                          }
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
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
            return FutureBuilder<ProfileModel>(
              future: _meFuture,
              builder: (context, meSnap) {
                final meId = meSnap.data?.user.id;
                final isMe = meId != null && meId == widget.userId;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.trainerProfileNotAvailable, textAlign: TextAlign.center),
                        if (isMe) ...[
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.push('/trainer/edit'),
                            child: Text(l10n.trainerEditProfile),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return FutureBuilder<ProfileModel>(
            future: _meFuture,
            builder: (context, meSnap) {
              final meId = meSnap.data?.user.id;
              final isMe = meId != null && meId == widget.userId;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Private trainer badge
                if (profile.acceptsPrivateClients) ...[
                  Chip(
                    avatar: const Icon(Icons.person, size: 16),
                    label: Text(l10n.trainerPrivateBadge),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  const SizedBox(height: 12),
                ],

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

                // CTA: Become a student (only if acceptsPrivateClients and not own profile)
                if (!isMe && profile.acceptsPrivateClients) ...[
                  const SizedBox(height: 24),
                  FutureBuilder<String>(
                    future: _statusFuture,
                    builder: (context, statusSnap) {
                      final status = statusSnap.data ?? 'none';
                      return _buildCtaButton(l10n, status);
                    },
                  ),
                ],
              ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCtaButton(AppLocalizations l10n, String status) {
    if (_statusLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (status) {
      case 'active':
        return Center(
          child: Chip(
            avatar: const Icon(Icons.check_circle, size: 18),
            label: Text(l10n.trainerYouAreStudent),
            backgroundColor:
                Colors.green.withValues(alpha: 0.15),
          ),
        );
      case 'pending':
        return Column(
          children: [
            Chip(
              avatar: const Icon(Icons.hourglass_top, size: 18),
              label: Text(l10n.trainerRequestSent),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _handleRequest('pending'),
              child: Text(l10n.trainerCancelRequest),
            ),
          ],
        );
      case 'rejected':
        return Center(
          child: ElevatedButton(
            onPressed: () => _handleRequest('rejected'),
            child: Text(l10n.trainerReapply),
          ),
        );
      default: // none
        return Center(
          child: ElevatedButton.icon(
            onPressed: () => _handleRequest('none'),
            icon: const Icon(Icons.school),
            label: Text(l10n.trainerBecomeStudent),
          ),
        );
    }
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
