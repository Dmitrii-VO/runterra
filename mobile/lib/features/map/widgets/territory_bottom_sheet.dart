import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/territory_map_model.dart';
import '../../../shared/models/territory_league_models.dart';
import '../../../shared/theme/tier_colors.dart';
import '../../../shared/api/users_service.dart' show ApiException;
import 'leaderboard_sheet.dart';

/// Bottom sheet for territory info — League Tactics design.
///
/// Lazy-loads full territory details (leaderboard, myClubProgress) via
/// GET /api/territories/:id when opened. Shows loading/error states.
class TerritoryBottomSheet extends StatefulWidget {
  final TerritoryMapModel territory;

  const TerritoryBottomSheet({
    super.key,
    required this.territory,
  });

  @override
  State<TerritoryBottomSheet> createState() => _TerritoryBottomSheetState();
}

class _TerritoryBottomSheetState extends State<TerritoryBottomSheet> {
  TerritoryMapModel? _fullTerritory;
  bool _isLoading = true;
  String? _error;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await ServiceLocator.mapService
          .getTerritoryDetails(widget.territory.id);
      if (mounted) {
        setState(() {
          _fullTerritory = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  TerritoryMapModel get _territory => _fullTerritory ?? widget.territory;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading(context);
    }

    if (_error != null) {
      return _buildError(context);
    }

    final leagueInfo = _territory.leagueInfo;

    if (leagueInfo == null) {
      return _buildFallback(context);
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTierHeader(context, leagueInfo),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRulesGrid(context, leagueInfo),
                  const SizedBox(height: 16),
                  _buildBattleProgress(context, leagueInfo),
                  const SizedBox(height: 16),
                  _buildActionBar(context, leagueInfo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Loading state with skeleton placeholders
  Widget _buildLoading(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.territory.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Error state with retry button
  Widget _buildError(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.territory.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Icon(Icons.error_outline, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            l10n.loadError,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadDetails,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  /// Gradient header with tier badge and capture status
  Widget _buildTierHeader(BuildContext context, TerritoryLeagueInfo info) {
    final l10n = AppLocalizations.of(context)!;
    final gradient = TierColors.gradientForTier(info.tier);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Territory name
          Text(
            _territory.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          // Tier badge + capture status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_tierName(l10n, info.tier)} • ${_tierLabel(l10n, info.tier)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
              const Spacer(),
              _buildCaptureStatusBadge(context, l10n, info),
            ],
          ),
        ],
      ),
    );
  }

  /// Capture status badge with club count for contested
  Widget _buildCaptureStatusBadge(
    BuildContext context,
    AppLocalizations l10n,
    TerritoryLeagueInfo info,
  ) {
    final String statusText;
    final Color bgColor;

    if (info.leaderboard.isEmpty) {
      statusText = l10n.zoneOpenSeason;
      bgColor = Colors.white.withOpacity(0.15);
    } else if (info.leaderboard.length >= 2) {
      statusText = '${l10n.zoneContested} (${info.leaderboard.length})';
      bgColor = Colors.orange.withOpacity(0.3);
    } else {
      statusText = l10n.zoneCaptured(info.leaderboard.first.clubName);
      bgColor = Colors.white.withOpacity(0.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  /// Three cards: pace threshold, zone bounty, season reset
  Widget _buildRulesGrid(BuildContext context, TerritoryLeagueInfo info) {
    final l10n = AppLocalizations.of(context)!;
    final daysLeft = info.seasonEndsAt.difference(DateTime.now()).inDays;

    return Row(
      children: [
        Expanded(
          child: _RuleCard(
            icon: Icons.timer_outlined,
            text: l10n.paceBonus(info.paceThreshold, info.pointMultiplier.toString()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RuleCard(
            icon: Icons.star_outline,
            text: l10n.zoneBountyLabel(info.zoneBounty.toString()),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _RuleCard(
            icon: Icons.hourglass_bottom,
            text: l10n.seasonResetIn(daysLeft < 0 ? 0 : daysLeft),
          ),
        ),
      ],
    );
  }

  /// Battle progress section with different states
  Widget _buildBattleProgress(BuildContext context, TerritoryLeagueInfo info) {
    final l10n = AppLocalizations.of(context)!;

    // State: empty leaderboard (new season)
    if (info.leaderboard.isEmpty) {
      return _InfoCard(
        icon: Icons.emoji_events_outlined,
        text: l10n.seasonStarted,
      );
    }

    // State: user has no club
    if (info.myClubProgress == null) {
      return _InfoCard(
        icon: Icons.group_outlined,
        text: l10n.joinClubCta,
        action: TextButton(
          onPressed: () {
            Navigator.pop(context);
            context.push('/clubs?cityId=spb');
          },
          child: Text(l10n.findClub),
        ),
      );
    }

    // State: full battle progress
    final leader = info.leaderboard.first;
    final myClub = info.myClubProgress!;
    final isLeading = myClub.position == 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leader row
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  leader.clubName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                l10n.leaderKm(leader.totalKm.toStringAsFixed(1)),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // My club progress
          if (isLeading)
            Text(
              l10n.clubLeading(myClub.gapToLeader.abs().toStringAsFixed(1)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
            )
          else ...[
            // Progress bar (clamped to 0.0-1.0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: leader.totalKm > 0
                    ? (myClub.totalKm / leader.totalKm).clamp(0.0, 1.0)
                    : 0,
                backgroundColor: Colors.grey[200],
                color: TierColors.forTier(info.tier),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.clubPosition(
                myClub.totalKm.toStringAsFixed(1),
                myClub.position.toString(),
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            Text(
              '−${l10n.gapToLeader(myClub.gapToLeader.toStringAsFixed(1))}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[400],
                  ),
            ),
          ],
        ],
      ),
    );
  }

  /// Action bar: run for zone + leaderboard button
  Widget _buildActionBar(BuildContext context, TerritoryLeagueInfo info) {
    final l10n = AppLocalizations.of(context)!;

    // If user has no club, show "find club" CTA instead
    if (info.myClubProgress == null && info.leaderboard.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            context.push('/clubs?cityId=spb');
          },
          icon: const Icon(Icons.group_add),
          label: Text(l10n.findClub),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/run');
            },
            style: FilledButton.styleFrom(
              backgroundColor: TierColors.forTier(info.tier),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              l10n.runForZone(info.zoneBounty.toString()),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        if (info.myClubProgress != null) ...[
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isCapturing ? null : () => _captureTerritory(info),
            icon: _isCapturing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.flag),
            tooltip: l10n.captureButton,
            style: IconButton.styleFrom(
              backgroundColor: TierColors.forTier(info.tier).withOpacity(0.15),
              foregroundColor: TierColors.forTier(info.tier),
            ),
          ),
        ],
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: () => _showLeaderboard(context, info),
          icon: const Icon(Icons.leaderboard),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  /// Fallback simple view when league data is not available
  Widget _buildFallback(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _territory.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            _territory.status == 'captured'
                ? l10n.territoryCaptured
                : l10n.territoryFree,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/territory/${_territory.id}');
              },
              child: Text(l10n.territoryMore),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureTerritory(TerritoryLeagueInfo info) async {
    final l10n = AppLocalizations.of(context)!;
    final clubId = info.myClubProgress!.clubId;

    setState(() => _isCapturing = true);
    try {
      await ServiceLocator.territoriesService
          .captureTerritory(_territory.id, clubId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.captureSuccess)),
        );
        _loadDetails();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.captureError(e.message))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.captureError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showLeaderboard(BuildContext context, TerritoryLeagueInfo info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => LeaderboardSheet(
        zoneName: _territory.name,
        tier: info.tier,
        leaderboard: info.leaderboard,
        myClubProgress: info.myClubProgress,
      ),
    );
  }

  String _tierName(AppLocalizations l10n, ZoneTier tier) {
    switch (tier) {
      case ZoneTier.green:
        return l10n.tierGreen;
      case ZoneTier.blue:
        return l10n.tierBlue;
      case ZoneTier.red:
        return l10n.tierRed;
      case ZoneTier.black:
        return l10n.tierBlack;
    }
  }

  String _tierLabel(AppLocalizations l10n, ZoneTier tier) {
    switch (tier) {
      case ZoneTier.green:
        return l10n.tierLabelNovice;
      case ZoneTier.blue:
        return l10n.tierLabelAdvanced;
      case ZoneTier.red:
        return l10n.tierLabelSpecialist;
      case ZoneTier.black:
        return l10n.tierLabelElite;
    }
  }
}

/// Small card for the rules grid
class _RuleCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

/// Info card with icon, text and optional action button
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _InfoCard({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          if (action != null) ...[
            const SizedBox(height: 8),
            action!,
          ],
        ],
      ),
    );
  }
}
