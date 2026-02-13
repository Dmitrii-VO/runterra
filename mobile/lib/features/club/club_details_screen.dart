import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_model.dart';
import '../../shared/models/club_member_model.dart';
import '../../shared/models/event_list_item_model.dart';
import '../../shared/ui/details_scaffold.dart';
import '../../shared/ui/error_display.dart';
import '../events/widgets/event_card.dart';

/// Р­РєСЂР°РЅ РґРµС‚Р°Р»РµР№ РєР»СѓР±Р°
///
/// РћС‚РѕР±СЂР°Р¶Р°РµС‚ РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ РєР»СѓР±Рµ, Р·Р°РіСЂСѓР¶Р°СЏ РґР°РЅРЅС‹Рµ С‡РµСЂРµР· ClubsService.
/// РСЃРїРѕР»СЊР·СѓРµС‚ FutureBuilder РґР»СЏ РѕС‚РѕР±СЂР°Р¶РµРЅРёСЏ СЃРѕСЃС‚РѕСЏРЅРёР№ loading/error/success.
/// 
/// РџСЂРёРЅРёРјР°РµС‚ clubId С‡РµСЂРµР· РїР°СЂР°РјРµС‚СЂ РјР°СЂС€СЂСѓС‚Р° Рё Р·Р°РіСЂСѓР¶Р°РµС‚ РґР°РЅРЅС‹Рµ РєР»СѓР±Р°.
class ClubDetailsScreen extends StatefulWidget {
  /// ID РєР»СѓР±Р° (РїРµСЂРµРґР°РµС‚СЃСЏ С‡РµСЂРµР· РїР°СЂР°РјРµС‚СЂ РјР°СЂС€СЂСѓС‚Р°)
  final String clubId;

  const ClubDetailsScreen({
    super.key,
    required this.clubId,
  });

  /// РЎРѕР·РґР°РµС‚ Future РґР»СЏ РїРѕР»СѓС‡РµРЅРёСЏ РґР°РЅРЅС‹С… Рѕ РєР»СѓР±Рµ
  /// 
  /// TODO: Backend URL РІС‹РЅРµСЃС‚Рё РІ РєРѕРЅС„РёРіСѓСЂР°С†РёСЋ
  /// 
  /// РџСЂРёРјРµС‡Р°РЅРёРµ: Р”Р»СЏ Android СЌРјСѓР»СЏС‚РѕСЂР° РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ 10.0.2.2 РІРјРµСЃС‚Рѕ localhost.
  /// Р”Р»СЏ С„РёР·РёС‡РµСЃРєРѕРіРѕ СѓСЃС‚СЂРѕР№СЃС‚РІР° РёСЃРїРѕР»СЊР·СѓР№С‚Рµ IP Р°РґСЂРµСЃ С…РѕСЃС‚-РјР°С€РёРЅС‹ РІ Р»РѕРєР°Р»СЊРЅРѕР№ СЃРµС‚Рё.
  @override
  State<ClubDetailsScreen> createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen> {
  /// Future for club details.
  late Future<ClubModel> _clubFuture;
  /// Members list
  List<ClubMemberModel>? _members;
  bool _membersLoading = false;
  /// True while join request is in progress.
  bool _isJoining = false;
  /// True while leave request is in progress.
  bool _isLeaving = false;
  /// Club events
  Future<List<EventListItemModel>>? _eventsFuture;
  /// Pending membership requests
  List<ClubMemberModel>? _pendingRequests;
  bool _pendingLoading = false;

  /// Creates Future for loading club data.
  Future<ClubModel> _fetchClub() async {
    return ServiceLocator.clubsService.getClubById(widget.clubId);
  }

  /// Reload data
  void _retry() {
    setState(() {
      _clubFuture = _fetchClub();
      _eventsFuture = null;
    });
    _loadMembers();
  }

  /// Load events for the club
  void _loadEvents(String? cityId) {
    if (cityId == null || cityId.isEmpty) return;
    setState(() {
      _eventsFuture = ServiceLocator.eventsService.getEvents(
        cityId: cityId,
        clubId: widget.clubId,
      );
    });
  }

  /// Load members list
  Future<void> _loadMembers() async {
    setState(() => _membersLoading = true);
    try {
      final members = await ServiceLocator.clubsService.getClubMembers(widget.clubId);
      if (mounted) setState(() => _members = members);
    } catch (_) {
      // Silently fail — members section will show error state
    } finally {
      if (mounted) setState(() => _membersLoading = false);
    }
  }

  /// Show role change dialog (leader only)
  Future<void> _showRoleChangeDialog(ClubMemberModel member) async {
    final l10n = AppLocalizations.of(context)!;
    final roles = ['member', 'trainer', 'leader'];
    final roleLabels = {
      'member': l10n.roleMember,
      'trainer': l10n.roleTrainer,
      'leader': l10n.roleLeader,
    };

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.clubMemberRoleChange,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...roles.map((role) => ListTile(
                    title: Text(roleLabels[role] ?? role),
                    trailing: role == member.role
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () => Navigator.pop(context, role),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == member.role || !mounted) return;

    try {
      await ServiceLocator.clubsService.updateMemberRole(
        widget.clubId,
        member.userId,
        selected,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clubMemberRoleChangeSuccess)),
        );
        _loadMembers();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clubMemberRoleChangeError(e.message))),
        );
      }
    }
  }

  Widget _buildMetricChip(BuildContext context, String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Join club and refresh on success; show SnackBar on error.
  Future<void> _onJoinClub() async {
    if (_isJoining) return;
    setState(() => _isJoining = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ServiceLocator.clubsService.joinClub(widget.clubId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clubRequestPending)),
      );
      _retry();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clubJoinError(e.message))),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _onLeaveClub() async {
    if (_isLeaving) return;
    final l10n = AppLocalizations.of(context)!;

    // Check if current user is leader via cached club data
    ClubModel? club;
    try {
      club = await _clubFuture;
    } catch (_) {}

    if (!mounted) return;
    if (club?.userRole == 'leader') {
      final membersCount = club?.membersCount ?? 1;
      if (membersCount > 1) {
        // Leader with other members — offer transfer or disband
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.leaderCannotLeave),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'transfer'),
                child: Text(l10n.transferLeadership),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'disband'),
                child: Text(l10n.disbandClub, style: const TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (action == null) return;
        if (action == 'transfer') {
          context.push('/club/${widget.clubId}/transfer-leadership');
          return;
        }
        if (action == 'disband') {
          await _disbandClub();
          return;
        }
        return;
      } else {
        // Leader is alone — confirm disband
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.disbandClub),
            content: Text(l10n.disbandConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.disbandClub, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (confirm == true) {
          await _disbandClub();
        }
        return;
      }
    }

    // Non-leader: regular leave
    setState(() => _isLeaving = true);
    try {
      await ServiceLocator.clubsService.leaveClub(widget.clubId);
      if (!mounted) return;
      if (ServiceLocator.currentClubService.currentClubId == widget.clubId) {
        await ServiceLocator.currentClubService.setCurrentClubId(null);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clubLeaveSuccess)),
      );
      _retry();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clubLeaveError(e.message))),
      );
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  Future<void> _disbandClub() async {
    setState(() => _isLeaving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ServiceLocator.clubsService.disbandClub(widget.clubId);
      if (!mounted) return;
      if (ServiceLocator.currentClubService.currentClubId == widget.clubId) {
        await ServiceLocator.currentClubService.setCurrentClubId(null);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.disbandSuccess)),
      );
      context.go('/');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clubLeaveError(e.message))),
      );
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  /// Load pending membership requests
  Future<void> _loadPendingRequests() async {
    setState(() => _pendingLoading = true);
    try {
      final requests = await ServiceLocator.clubsService.getMembershipRequests(widget.clubId);
      if (mounted) setState(() => _pendingRequests = requests);
    } catch (_) {
      // Silently fail — section will show empty state
    } finally {
      if (mounted) setState(() => _pendingLoading = false);
    }
  }

  Future<void> _approveRequest(String userId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ServiceLocator.clubsService.approveMembership(widget.clubId, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clubRequestApprove)),
      );
      _loadPendingRequests();
      _loadMembers();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _rejectRequest(String userId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ServiceLocator.clubsService.rejectMembership(widget.clubId, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clubRequestReject)),
      );
      _loadPendingRequests();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Widget _buildMembershipRequestsSection(AppLocalizations l10n) {
    // Lazy-load on first build
    if (_pendingRequests == null && !_pendingLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPendingRequests();
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.clubMembershipRequests,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_pendingLoading && _pendingRequests == null)
          const Center(child: CircularProgressIndicator())
        else if (_pendingRequests != null && _pendingRequests!.isNotEmpty)
          ..._pendingRequests!.map((request) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(
                    request.displayName.isNotEmpty
                        ? request.displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(request.displayName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveRequest(request.userId),
                      tooltip: l10n.clubRequestApprove,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectRequest(request.userId),
                      tooltip: l10n.clubRequestReject,
                    ),
                  ],
                ),
              ))
        else
          Text(
            '-',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
      ],
    );
  }

  /// Navigate to edit club screen and refresh data on success
  Future<void> _onEditClub(ClubModel club) async {
    final result = await context.push<bool>('/club/${club.id}/edit', extra: club);

    // If edit was successful, refresh club data
    if (result == true && mounted) {
      _retry();
    }
  }

  @override
  void initState() {
    super.initState();
    _clubFuture = _fetchClub();
    _loadMembers();
  }

  String _roleLabel(AppLocalizations l10n, String role) {
    switch (role) {
      case 'leader':
        return l10n.roleLeader;
      case 'trainer':
        return l10n.roleTrainer;
      default:
        return l10n.roleMember;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DetailsScaffold(
      title: AppLocalizations.of(context)!.clubDetailsTitle,
      body: FutureBuilder<ClubModel>(
        future: _clubFuture,
        builder: (context, snapshot) {
          // РЎРѕСЃС‚РѕСЏРЅРёРµ Р·Р°РіСЂСѓР·РєРё
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // РЎРѕСЃС‚РѕСЏРЅРёРµ РѕС€РёР±РєРё
          if (snapshot.hasError) {
            return ErrorDisplay(
              errorMessage: snapshot.error is ApiException ? (snapshot.error as ApiException).message : snapshot.error.toString(),
              onRetry: _retry,
            );
          }

          // РЎРѕСЃС‚РѕСЏРЅРёРµ СѓСЃРїРµС…Р° - РѕС‚РѕР±СЂР°Р¶РµРЅРёРµ РґР°РЅРЅС‹С… РєР»СѓР±Р°
          if (snapshot.hasData) {
            final club = snapshot.data!;
            final l10n = AppLocalizations.of(context)!;
            final cityDisplay = club.cityName ?? club.cityId ?? l10n.clubMetricPlaceholder;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // РќР°Р·РІР°РЅРёРµ РєР»СѓР±Р°
                    Text(
                      club.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    // City
                    Row(
                      children: [
                        Icon(Icons.location_city, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          cityDisplay,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    // Activation hint when club is pending and user is a member
                    if (club.status == 'pending' && club.isMember == true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.clubActivationHint,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // MVP metrics (СѓС‡Р°СЃС‚РЅРёРєРё, С‚РµСЂСЂРёС‚РѕСЂРёРё, СЂРµР№С‚РёРЅРі)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricChip(
                            context,
                            l10n.clubMembersLabel,
                            club.membersCount != null ? '${club.membersCount}' : l10n.clubMetricPlaceholder,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricChip(
                            context,
                            l10n.clubTerritoriesLabel,
                            club.territoriesCount != null ? '${club.territoriesCount}' : l10n.clubMetricPlaceholder,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricChip(
                            context,
                            l10n.clubCityRankLabel,
                            club.cityRank != null ? '${club.cityRank}' : l10n.clubMetricPlaceholder,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // РљРЅРѕРїРєР° В«Р§Р°С‚ РєР»СѓР±Р°В» вЂ” РїРµСЂРµС…РѕРґ РІ РЎРѕРѕР±С‰РµРЅРёСЏ, РІРєР»Р°РґРєР° РљР»СѓР±
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/messages?tab=club&clubId=${club.id}'),
                        icon: const Icon(Icons.chat),
                        label: Text(l10n.clubChatButton),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // РћРїРёСЃР°РЅРёРµ РєР»СѓР±Р° (РµСЃР»Рё РµСЃС‚СЊ)
                    if (club.description != null && club.description!.isNotEmpty) ...[
                      Text(
                        l10n.detailDescription,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        club.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Founder
                    if (club.creatorName != null && club.creatorName!.isNotEmpty) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.star),
                        title: Text(club.creatorName!),
                        subtitle: Text(l10n.clubFounder),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Members section
                    Text(
                      l10n.clubMembersTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_membersLoading && _members == null)
                      const Center(child: CircularProgressIndicator())
                    else if (_members != null && _members!.isNotEmpty)
                      ..._members!.map((member) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(
                                member.displayName.isNotEmpty
                                    ? member.displayName[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(member.displayName),
                            subtitle: Text(_roleLabel(l10n, member.role)),
                            onTap: club.userRole == 'leader'
                                ? () => _showRoleChangeDialog(member)
                                : null,
                          ))
                    else
                      Text(
                        l10n.clubMembersEmpty,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    const SizedBox(height: 24),
                    // Club events section
                    Builder(
                      builder: (context) {
                        // Lazy-load events on first build
                        if (_eventsFuture == null && club.cityId != null) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _loadEvents(club.cityId);
                          });
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.clubEventsTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            if (_eventsFuture != null)
                              FutureBuilder<List<EventListItemModel>>(
                                future: _eventsFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ));
                                  }
                                  if (snapshot.hasError) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: [
                                          Text(
                                            l10n.clubEventsError,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton(
                                            onPressed: () => _loadEvents(club.cityId),
                                            child: Text(l10n.retry),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  final events = snapshot.data ?? [];
                                  if (events.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        l10n.clubEventsEmpty,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                      ),
                                    );
                                  }
                                  final displayEvents = events.take(3).toList();
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ...displayEvents.map((event) => EventCard(event: event)),
                                      if (events.length > 3)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: TextButton(
                                            onPressed: () => context.push('/events?clubId=${widget.clubId}'),
                                            child: Text(l10n.clubEventsViewAll),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Edit button (leader only)
                    if (club.userRole == 'leader') ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _onEditClub(club),
                          icon: const Icon(Icons.edit),
                          label: Text(l10n.clubEditButton),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Membership section
                    if (club.isMember == true)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton(
                            onPressed: null,
                            child: Text(l10n.clubYouAreMember),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _isLeaving ? null : _onLeaveClub,
                            icon: _isLeaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.exit_to_app),
                            label: Text(l10n.clubLeave),
                          ),
                        ],
                      )
                    else if (club.membershipStatus == 'pending')
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: null,
                          child: Text(l10n.clubRequestPending),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isJoining ? null : _onJoinClub,
                          icon: _isJoining
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.person_add),
                          label: Text(l10n.clubRequestJoin),
                        ),
                      ),
                    // Membership requests section (leader/trainer only)
                    if (club.userRole == 'leader' || club.userRole == 'trainer') ...[
                      const SizedBox(height: 24),
                      _buildMembershipRequestsSection(l10n),
                    ],
                  ],
                ),
              ),
            );
          }

          // Fallback (РЅРµ РґРѕР»Р¶РЅРѕ РїСЂРѕРёР·РѕР№С‚Рё)
          return Center(
            child: Text(AppLocalizations.of(context)!.noData),
          );
        },
      ),
    );
  }
}
