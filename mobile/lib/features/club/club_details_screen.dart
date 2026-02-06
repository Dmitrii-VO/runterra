import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_model.dart';
import '../../shared/ui/details_scaffold.dart';
import '../../shared/ui/error_display.dart';

/// Экран деталей клуба
///
/// Отображает информацию о клубе, загружая данные через ClubsService.
/// Использует FutureBuilder для отображения состояний loading/error/success.
/// 
/// Принимает clubId через параметр маршрута и загружает данные клуба.
class ClubDetailsScreen extends StatefulWidget {
  /// ID клуба (передается через параметр маршрута)
  final String clubId;

  const ClubDetailsScreen({
    super.key,
    required this.clubId,
  });

  /// Создает Future для получения данных о клубе
  /// 
  /// TODO: Backend URL вынести в конфигурацию
  /// 
  /// Примечание: Для Android эмулятора используется 10.0.2.2 вместо localhost.
  /// Для физического устройства используйте IP адрес хост-машины в локальной сети.
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
          // Состояние загрузки
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Состояние ошибки
          if (snapshot.hasError) {
            return ErrorDisplay(
              errorMessage: snapshot.error.toString(),
              onRetry: _retry,
            );
          }

          // Состояние успеха - отображение данных клуба
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
                    // Название клуба
                    Text(
                      club.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    // Город
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
                    // Метрики MVP (участники, территории, рейтинг)
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
                    // Кнопка «Чат клуба» — переход в Сообщения, вкладка Клуб
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/messages?tab=club'),
                        icon: const Icon(Icons.chat),
                        label: Text(l10n.clubChatButton),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Описание клуба (если есть)
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
                    // Участие в клубе
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

          // Fallback (не должно произойти)
          return Center(
            child: Text(AppLocalizations.of(context)!.noData),
          );
        },
      ),
    );
  }
}
