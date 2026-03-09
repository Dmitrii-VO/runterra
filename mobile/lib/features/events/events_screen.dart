import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/event_list_item_model.dart';
import 'widgets/event_card.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<EventListItemModel>> _eventsFuture;
  String? _selectedDateFilter;
  String? _selectedClubId;
  bool _onlyOpen = true;
  bool _participantOnly = false;
  String? _selectedEventType;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _fetchCityEvents();
  }

  Future<List<EventListItemModel>> _fetchCityEvents() async {
    final cityId = ServiceLocator.currentCityService.currentCityId;
    if (cityId == null || cityId.isEmpty) return [];

    final events = await ServiceLocator.eventsService.getEvents(
      cityId: cityId,
      dateFilter: _selectedDateFilter,
      clubId: _selectedClubId,
      onlyOpen: _onlyOpen,
      participantOnly: _participantOnly,
      eventType: _selectedEventType,
      difficultyLevel: _selectedDifficulty,
    );

    if (!_onlyOpen) return events;
    final now = DateTime.now();
    return events
        .where((event) =>
            event.status == 'open' && !event.startDateTime.isBefore(now))
        .toList();
  }

  void _refresh() {
    setState(() => _eventsFuture = _fetchCityEvents());
  }

  Future<void> _onRefresh() async {
    setState(() => _eventsFuture = _fetchCityEvents());
    await _eventsFuture;
  }

  void _resetFilters() {
    setState(() {
      _selectedDateFilter = null;
      _selectedClubId = null;
      _onlyOpen = true;
      _participantOnly = false;
      _selectedEventType = null;
      _selectedDifficulty = null;
      _eventsFuture = _fetchCityEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventsTitle),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/event/create?type=open_event'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFiltersPanel(l10n),
          Expanded(child: _buildEventsList(l10n)),
        ],
      ),
    );
  }

  Widget _buildEventsList(AppLocalizations l10n) {
    final hasActiveFilters = _selectedDateFilter != null ||
        _selectedClubId != null ||
        _participantOnly ||
        _selectedEventType != null ||
        _selectedDifficulty != null;

    return FutureBuilder<List<EventListItemModel>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            hasActiveFilters
                                ? l10n.eventsEmptyFiltered
                                : l10n.eventsEmpty,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          if (hasActiveFilters) ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _resetFilters,
                              child: Text(l10n.eventsResetFilters),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.eventsEmptyHint,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) => EventCard(event: events[index]),
          ),
        );
      },
    );
  }

  Widget _buildFiltersPanel(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: date, open, club, participant
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildDateFilterChip(l10n.filterToday, 'today'),
                const SizedBox(width: 8),
                _buildDateFilterChip(l10n.filterTomorrow, 'tomorrow'),
                const SizedBox(width: 8),
                _buildDateFilterChip(l10n.filter7days, 'next7days'),
                const SizedBox(width: 16),
                FilterChip(
                  label: Text(l10n.filterOnlyOpen),
                  selected: _onlyOpen,
                  onSelected: (selected) {
                    setState(() {
                      _onlyOpen = selected;
                      _eventsFuture = _fetchCityEvents();
                    });
                  },
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: Text(l10n.filtersMyClub),
                  selected:
                      _selectedClubId != null && _selectedClubId!.isNotEmpty,
                  onSelected: (selected) async {
                    if (!selected) {
                      setState(() {
                        _selectedClubId = null;
                        _eventsFuture = _fetchCityEvents();
                      });
                      return;
                    }
                    // Try cache first; fall back to API if cache is empty.
                    String? clubId =
                        ServiceLocator.currentClubService.currentClubId;
                    if (clubId == null || clubId.isEmpty) {
                      try {
                        final myClubs =
                            await ServiceLocator.clubsService.getMyClubs();
                        if (myClubs.isNotEmpty) clubId = myClubs.first.id;
                      } catch (_) {}
                    }
                    if (!mounted) return;
                    setState(() {
                      _selectedClubId = clubId;
                      _eventsFuture = _fetchCityEvents();
                    });
                  },
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: Text(l10n.filterParticipantOnly),
                  selected: _participantOnly,
                  onSelected: (selected) {
                    setState(() {
                      _participantOnly = selected;
                      _eventsFuture = _fetchCityEvents();
                    });
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          // Row 2: event type
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                _buildEventTypeChip(l10n.filterAll, null),
                const SizedBox(width: 8),
                _buildEventTypeChip(l10n.eventTypeTraining, 'training'),
                const SizedBox(width: 8),
                _buildEventTypeChip(l10n.eventTypeGroupRun, 'group_run'),
                const SizedBox(width: 8),
                _buildEventTypeChip(l10n.eventTypeClubEvent, 'club_event'),
                const SizedBox(width: 8),
                _buildEventTypeChip(l10n.eventTypeOpenEvent, 'open_event'),
                const SizedBox(width: 16),
              ],
            ),
          ),
          // Row 3: difficulty
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              children: [
                _buildDifficultyChip(l10n.filterAll, null),
                const SizedBox(width: 8),
                _buildDifficultyChip(l10n.eventDifficultyBeginner, 'beginner'),
                const SizedBox(width: 8),
                _buildDifficultyChip(
                    l10n.eventDifficultyIntermediate, 'intermediate'),
                const SizedBox(width: 8),
                _buildDifficultyChip(l10n.eventDifficultyAdvanced, 'advanced'),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventTypeChip(String label, String? value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedEventType == value,
      onSelected: (selected) {
        setState(() {
          _selectedEventType = selected ? value : null;
          _eventsFuture = _fetchCityEvents();
        });
      },
    );
  }

  Widget _buildDifficultyChip(String label, String? value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedDifficulty == value,
      onSelected: (selected) {
        setState(() {
          _selectedDifficulty = selected ? value : null;
          _eventsFuture = _fetchCityEvents();
        });
      },
    );
  }

  Widget _buildDateFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedDateFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedDateFilter = selected ? value : null;
          _eventsFuture = _fetchCityEvents();
        });
      },
    );
  }
}
