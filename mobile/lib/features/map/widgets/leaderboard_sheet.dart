import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/territory_league_models.dart';
import '../../../shared/theme/tier_colors.dart';

/// Bottom sheet displaying the territory leaderboard (top clubs)
class LeaderboardSheet extends StatelessWidget {
  final String zoneName;
  final ZoneTier tier;
  final List<LeaderboardEntry> leaderboard;
  final ClubProgress? myClubProgress;

  const LeaderboardSheet({
    super.key,
    required this.zoneName,
    required this.tier,
    required this.leaderboard,
    this.myClubProgress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tierColor = TierColors.forTier(tier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: TierColors.gradientForTier(tier)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Text(
              l10n.leaderboardTitle(zoneName),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // List
          Flexible(
            child: leaderboard.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.seasonStarted,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: leaderboard.length + _showMyClubSeparately(),
                    itemBuilder: (context, index) {
                      if (index < leaderboard.length) {
                        final entry = leaderboard[index];
                        final isMyClub = myClubProgress != null &&
                            entry.clubId == myClubProgress!.clubId;
                        return _buildRow(context, entry, isMyClub, tierColor);
                      }
                      // My club outside top list
                      return Column(
                        children: [
                          const Divider(),
                          _buildRow(
                            context,
                            LeaderboardEntry(
                              clubId: myClubProgress!.clubId,
                              clubName: myClubProgress!.clubName,
                              totalKm: myClubProgress!.totalKm,
                              position: myClubProgress!.position,
                            ),
                            true,
                            tierColor,
                          ),
                        ],
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Returns 1 if my club is not already in the leaderboard list
  int _showMyClubSeparately() {
    if (myClubProgress == null) return 0;
    final inList = leaderboard.any((e) => e.clubId == myClubProgress!.clubId);
    return inList ? 0 : 1;
  }

  Widget _buildRow(
    BuildContext context,
    LeaderboardEntry entry,
    bool isMyClub,
    Color tierColor,
  ) {
    return Container(
      color: isMyClub ? tierColor.withOpacity(0.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.position}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isMyClub ? tierColor : Colors.grey[700],
                  ),
            ),
          ),
          const SizedBox(width: 8),
          // Club initial circle
          CircleAvatar(
            radius: 16,
            backgroundColor: tierColor.withOpacity(0.15),
            child: Text(
              entry.clubName.isNotEmpty ? entry.clubName[0].toUpperCase() : '?',
              style: TextStyle(
                color: tierColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Club name
          Expanded(
            child: Text(
              entry.clubName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isMyClub ? FontWeight.bold : FontWeight.normal,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Km
          Text(
            '${entry.totalKm.toStringAsFixed(1)} km',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
          ),
        ],
      ),
    );
  }
}
