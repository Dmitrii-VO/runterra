import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_model.dart';
import '../../shared/ui/details_scaffold.dart';
import '../../shared/ui/error_display.dart';

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
  /// True while join request is in progress.
  bool _isJoining = false;
  /// True while leave request is in progress.
  bool _isLeaving = false;

  /// Creates Future for loading club data.
  Future<ClubModel> _fetchClub() async {
    return ServiceLocator.clubsService.getClubById(widget.clubId);
  }

  /// Reload data
  void _retry() {
    setState(() {
      _clubFuture = _fetchClub();
    });
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
      await ServiceLocator.currentClubService.setCurrentClubId(widget.clubId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clubJoinSuccess)),
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
    setState(() => _isLeaving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ServiceLocator.clubsService.leaveClub(widget.clubId);
      if (!mounted) return;
      if (ServiceLocator.currentClubService.currentClubId == widget.clubId) {
        await ServiceLocator.currentClubService.setCurrentClubId(null);
      }
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
                    // Р“РѕСЂРѕРґ
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
                    const SizedBox(height: 16),
                    // РњРµС‚СЂРёРєРё MVP (СѓС‡Р°СЃС‚РЅРёРєРё, С‚РµСЂСЂРёС‚РѕСЂРёРё, СЂРµР№С‚РёРЅРі)
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
                    // РљРЅРѕРїРєР° СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёСЏ (С‚РѕР»СЊРєРѕ РґР»СЏ Р»РёРґРµСЂРѕРІ)
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
                    // РЈС‡Р°СЃС‚РёРµ РІ РєР»СѓР±Рµ
                    if (club.isMember == true)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton(
                            onPressed: null,
                            child: Text(AppLocalizations.of(context)!.clubYouAreMember),
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
                            label: Text(AppLocalizations.of(context)!.clubLeave),
                          ),
                        ],
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
                          label: Text(AppLocalizations.of(context)!.clubJoin),
                        ),
                      ),
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
