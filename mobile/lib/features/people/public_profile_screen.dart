import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/public_profile_model.dart';
import '../../shared/models/user_search_result_model.dart';

/// Public profile of another user.
///
/// If [preload] is provided (from search result), avatar/name are shown
/// immediately while the full profile loads in the background.
class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final UserSearchResult? preload;

  const PublicProfileScreen({
    super.key,
    required this.userId,
    this.preload,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late Future<PublicProfileModel> _future;

  @override
  void initState() {
    super.initState();
    _future = ServiceLocator.usersService.getPublicProfile(widget.userId);
  }

  String _formatPace(int paceSecPerKm) {
    final min = paceSecPerKm ~/ 60;
    final sec = paceSecPerKm % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final preload = widget.preload;
    final preloadName = preload?.name ?? '';

    return FutureBuilder<PublicProfileModel>(
      future: _future,
      builder: (context, snapshot) {
        final name = snapshot.data?.user.name ?? preloadName;
        final l10n = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(
            title: Text(name.isNotEmpty ? name : l10n.profileTitle),
          ),
          body: _buildBody(context, snapshot, preload, l10n),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<PublicProfileModel> snapshot,
    UserSearchResult? preload,
    AppLocalizations l10n,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      // Show preloaded header while waiting for full data
      if (preload != null) {
        return _buildContent(
          context,
          l10n,
          name: preload.name,
          avatarUrl: preload.avatarUrl,
          cityName: preload.cityName,
          clubName: preload.clubName,
          stats: null,
          recentRuns: null,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(l10n.errorLoadTitle),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => setState(
                () => _future =
                    ServiceLocator.usersService.getPublicProfile(widget.userId),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (!snapshot.hasData) {
      return Center(child: Text(l10n.profileNotFound));
    }

    final profile = snapshot.data!;
    final subtitle = [profile.user.cityName, profile.club?.name]
        .where((s) => s != null && s.isNotEmpty)
        .join(' • ');

    return _buildContent(
      context,
      l10n,
      name: profile.user.name,
      avatarUrl: profile.user.avatarUrl,
      cityName: profile.user.cityName,
      clubName: profile.club?.name,
      subtitle: subtitle,
      stats: profile.stats,
      recentRuns: profile.recentRuns,
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n, {
    required String name,
    String? avatarUrl,
    String? cityName,
    String? clubName,
    String? subtitle,
    PublicProfileStats? stats,
    List<PublicRunSummary>? recentRuns,
  }) {
    final effectiveSubtitle = subtitle ??
        [cityName, clubName].where((s) => s != null && s.isNotEmpty).join(' • ');
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(initials, style: const TextStyle(fontSize: 32))
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (effectiveSubtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              effectiveSubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          if (stats != null) ...[
            _StatsRow(stats: stats, l10n: l10n),
            const SizedBox(height: 32),
            _RecentRunsSection(
              runs: recentRuns ?? [],
              l10n: l10n,
              formatPace: _formatPace,
              formatDate: _formatDate,
            ),
          ] else
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final PublicProfileStats stats;
  final AppLocalizations l10n;

  const _StatsRow({required this.stats, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.directions_run,
            value: stats.totalRuns.toString(),
            label: l10n.publicProfileRuns,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.straighten,
            value: stats.totalDistanceKm.toStringAsFixed(1),
            label: l10n.publicProfileKm,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.star_outline,
            value: '${stats.contributionPoints}',
            label: l10n.publicProfilePoints,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRunsSection extends StatelessWidget {
  final List<PublicRunSummary> runs;
  final AppLocalizations l10n;
  final String Function(int) formatPace;
  final String Function(DateTime) formatDate;

  const _RecentRunsSection({
    required this.runs,
    required this.l10n,
    required this.formatPace,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.publicProfileRecentRuns,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (runs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.publicProfileNoRuns,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
            ),
          )
        else
          ...runs.map(
            (run) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.directions_run),
              title: Text(formatDate(run.startedAt)),
              subtitle: Text(
                '${(run.distance / 1000).toStringAsFixed(1)} km  •  '
                '${formatPace(run.pace)}/km',
              ),
            ),
          ),
      ],
    );
  }
}
