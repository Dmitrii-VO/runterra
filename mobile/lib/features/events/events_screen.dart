import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/event_list_item_model.dart';
import 'widgets/event_card.dart';
import '../../main.dart' show DevRemoteLogger;

/// Экран списка событий.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<EventListItemModel>> _eventsFuture;

  // Filter state — proxied to EventsService.getEvents and then backend (where supported).
  String? _selectedDateFilter;
  String? _selectedClubId;
  String? _selectedDifficultyLevel;
  String? _selectedEventType;
  bool _onlyOpen = true;
  bool _participantOnly = false;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _fetchEvents();
  }

  Future<List<EventListItemModel>> _fetchEvents() async {
    final eventsService = ServiceLocator.eventsService;
    final cityId = ServiceLocator.currentCityService.currentCityId;
    if (cityId == null || cityId.isEmpty) {
      throw Exception('Current city is not selected');
    }

    final events = await eventsService.getEvents(
      cityId: cityId,
      dateFilter: _selectedDateFilter,
      clubId: _selectedClubId,
      difficultyLevel: _selectedDifficultyLevel,
      eventType: _selectedEventType,
      onlyOpen: _onlyOpen,
      participantOnly: _participantOnly,
    );

    // Client-side safety net: even if backend still marks past events as `open`,
    // exclude them from "Only open" list.
    if (!_onlyOpen) return events;
    final now = DateTime.now();
    return events
        .where((e) => e.status == 'open' && !e.startDateTime.isBefore(now))
        .toList();
  }

  Future<void> _refreshEvents() async {
    final future = _fetchEvents();
    setState(() {
      _eventsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.eventsTitle),
      ),
      body: Column(
        children: [
          _buildFiltersPanel(),
          Expanded(
            child: FutureBuilder<List<EventListItemModel>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  DevRemoteLogger.logError(
                    'Error loading events list',
                    error: snapshot.error ?? 'unknown',
                    stackTrace: snapshot.stackTrace,
                  );

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.eventsLoadError,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _refreshEvents,
                            child: Text(AppLocalizations.of(context)!.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.eventsEmpty,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.eventsEmptyHint,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final events = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: _refreshEvents,
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return EventCard(event: events[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/event/create');
        },
        tooltip: AppLocalizations.of(context)!.eventsCreateTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFiltersPanel() {
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _buildDateFilterChip(
              AppLocalizations.of(context)!.filterToday,
              'today',
            ),
            const SizedBox(width: 8),
            _buildDateFilterChip(
              AppLocalizations.of(context)!.filterTomorrow,
              'tomorrow',
            ),
            const SizedBox(width: 8),
            _buildDateFilterChip(
              AppLocalizations.of(context)!.filter7days,
              'next7days',
            ),
            const SizedBox(width: 16),
            FilterChip(
              label: Text(AppLocalizations.of(context)!.filterOnlyOpen),
              selected: _onlyOpen,
              onSelected: (selected) {
                setState(() {
                  _onlyOpen = selected;
                  _eventsFuture = _fetchEvents();
                });
              },
            ),
            const SizedBox(width: 16),
            FilterChip(
              label: Text(AppLocalizations.of(context)!.filtersMyClub),
              selected:
                  ServiceLocator.currentClubService.currentClubId != null &&
                      _selectedClubId ==
                          ServiceLocator.currentClubService.currentClubId,
              onSelected: (selected) {
                setState(() {
                  _selectedClubId = selected
                      ? ServiceLocator.currentClubService.currentClubId
                      : null;
                  _eventsFuture = _fetchEvents();
                });
              },
            ),
            const SizedBox(width: 16),
            FilterChip(
              label: Text(AppLocalizations.of(context)!.filterParticipantOnly),
              selected: _participantOnly,
              onSelected: (selected) {
                setState(() {
                  _participantOnly = selected;
                  _eventsFuture = _fetchEvents();
                });
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedDateFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedDateFilter = selected ? value : null;
          _eventsFuture = _fetchEvents();
        });
      },
    );
  }
}

