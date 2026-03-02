import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/user_search_result_model.dart';

/// Public profile of another user.
///
/// If [preload] is provided (from search result), it is shown immediately.
/// Otherwise, falls back to GET /api/users/:id.
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
  late Future<_PublicUser> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_PublicUser> _load() async {
    if (widget.preload != null) {
      final p = widget.preload!;
      return _PublicUser(
        id: p.id,
        name: p.name,
        avatarUrl: p.avatarUrl,
        cityName: p.cityName,
        clubName: p.clubName,
      );
    }
    return _fetchFromApi();
  }

  Future<_PublicUser> _fetchFromApi() async {
    final response = await ServiceLocator.usersService.getRawUserById(widget.userId);
    return _PublicUser(
      id: response['id'] as String,
      name: response['name'] as String,
      avatarUrl: response['avatarUrl'] as String?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<_PublicUser>(
      future: _future,
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? '';
        return Scaffold(
          appBar: AppBar(
            title: Text(name.isNotEmpty ? name : l10n.profileTitle),
          ),
          body: _buildBody(context, snapshot, l10n),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<_PublicUser> snapshot,
    AppLocalizations l10n,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
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
              onPressed: () => setState(() => _future = _fetchFromApi()),
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

    final user = snapshot.data!;
    final subtitle = [user.cityName, user.clubName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' • ');
    final initials = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(initials, style: const TextStyle(fontSize: 32))
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          // Disabled placeholder for future DM
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(l10n.messageComingSoon),
          ),
        ],
      ),
    );
  }
}

class _PublicUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? cityName;
  final String? clubName;

  const _PublicUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.cityName,
    this.clubName,
  });
}
