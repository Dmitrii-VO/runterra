import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/territory_league_models.dart';
import '../../../shared/theme/tier_colors.dart';

/// Maximum number of leaderboard entries to display
const _maxLeaderboardEntries = 10;

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

    // Limit visible entries to top 10
    final visibleEntries = leaderboard.length > _maxLeaderboardEntries
        ? leaderboard.sublist(0, _maxLeaderboardEntries)
        : leaderboard;

    // Check if my club is outside visible entries and needs separate row
    final myClubOutsideTop = _isMyClubOutsideVisible(visibleEntries);
    final extraRows = myClubOutsideTop ? 2 : 0; // ellipsis + my club row

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
              gradient:
                  LinearGradient(colors: TierColors.gradientForTier(tier)),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
                    itemCount: visibleEntries.length + extraRows,
                    itemBuilder: (context, index) {
                      if (index < visibleEntries.length) {
                        final entry = visibleEntries[index];
                        final isMyClub = myClubProgress != null &&
                            entry.clubId == myClubProgress!.clubId;
                        return _buildRow(
                            context, l10n, entry, isMyClub, tierColor);
                      }

                      // Ellipsis separator
                      if (index == visibleEntries.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Center(
                            child: Text(
                              '...',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }

                      // My club outside top
                      return _buildRow(
                        context,
                        l10n,
                        LeaderboardEntry(
                          clubId: myClubProgress!.clubId,
                          clubName: myClubProgress!.clubName,
                          totalKm: myClubProgress!.totalKm,
                          position: myClubProgress!.position,
                        ),
                        true,
                        tierColor,
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Returns true if my club exists but is not in the visible entries list
  bool _isMyClubOutsideVisible(List<LeaderboardEntry> visibleEntries) {
    if (myClubProgress == null) return false;
    return !visibleEntries.any((e) => e.clubId == myClubProgress!.clubId);
  }

  Widget _buildRow(
    BuildContext context,
    AppLocalizations l10n,
    LeaderboardEntry entry,
    bool isMyClub,
    Color tierColor,
  ) {
    return Container(
      color: isMyClub ? tierColor.withValues(alpha: 0.08) : null,
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
            backgroundColor: tierColor.withValues(alpha: 0.15),
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
          // Km (using i18n)
          Text(
            l10n.leaderKm(entry.totalKm.toStringAsFixed(1)),
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
