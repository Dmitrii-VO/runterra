import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/event_list_item_model.dart';
import '../../shared/models/calendar_model.dart';
import '../../shared/models/my_club_model.dart';
import 'widgets/event_card.dart';
import 'package:intl/intl.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tab 1: Training Plan
  DateTime _selectedDate = DateTime.now();
  late Future<String?> _trainingClubIdFuture;
  late Future<List<CalendarItemModel>> _calendarFuture;
  
  // Tab 2: City Events
  late Future<List<EventListItemModel>> _eventsFuture;
  String? _selectedDateFilter;
  String? _selectedClubId;
  bool _onlyOpen = true;
  bool _participantOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _trainingClubIdFuture = _resolveTrainingClubId();
    _calendarFuture = _fetchCalendar();
    _eventsFuture = _fetchCityEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _resolveTrainingClubId() async {
    final cachedClubId = ServiceLocator.currentClubService.currentClubId;
    if (cachedClubId != null && cachedClubId.isNotEmpty) return cachedClubId;

    try {
      final myClubs = await ServiceLocator.clubsService.getMyClubs();
      if (myClubs.isEmpty) return null;

      final List<MyClubModel> activeClubs = myClubs
          .where((club) => club.status == 'active')
          .toList();
      final selectedClub = activeClubs.isNotEmpty ? activeClubs.first : myClubs.first;

      await ServiceLocator.currentClubService.setCurrentClubId(selectedClub.id);
      return selectedClub.id;
    } catch (_) {
      return null;
    }
  }

  Future<List<CalendarItemModel>> _fetchCalendar() async {
    final clubId = await _trainingClubIdFuture;
    if (clubId == null || clubId.isEmpty) return [];
    
    final yearMonth = DateFormat('yyyy-MM').format(_selectedDate);
    return ServiceLocator.clubsService.getCalendar(clubId, yearMonth);
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
    );

    // Safety net: if backend still returns stale open events in the past.
    if (!_onlyOpen) return events;
    final now = DateTime.now();
    return events
        .where((event) => event.status == 'open' && !event.startDateTime.isBefore(now))
        .toList();
  }

  void _refresh() {
    setState(() {
      _trainingClubIdFuture = _resolveTrainingClubId();
      _calendarFuture = _fetchCalendar();
      _eventsFuture = _fetchCityEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.statsTrainings), // "Тренировки"
            Tab(text: l10n.eventsTitle),    // "События"
          ],
        ),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrainingPlanTab(l10n),
          _buildCityEventsTab(l10n),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/event/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTrainingPlanTab(AppLocalizations l10n) {
    return FutureBuilder<String?>(
      future: _trainingClubIdFuture,
      builder: (context, clubSnapshot) {
        if (clubSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final clubId = clubSnapshot.data;
        if (clubId == null || clubId.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.center,
                children: [
                  const Icon(Icons.group_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noClubChats,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/map?showClubs=true'),
                    child: Text(l10n.quickFindClub),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            _buildCalendarStrip(),
            Expanded(
              child: FutureBuilder<List<CalendarItemModel>>(
                future: _calendarFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }
                  
                  final allItems = snapshot.data ?? [];
                  final dayItems = allItems.where((item) => 
                    item.date.year == _selectedDate.year &&
                    item.date.month == _selectedDate.month &&
                    item.date.day == _selectedDate.day
                  ).toList();

                  if (dayItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.weekend_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(l10n.noData, style: TextStyle(color: Colors.grey.shade400)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: dayItems.length,
                    itemBuilder: (context, index) {
                      final item = dayItems[index];
                      final isEvent = item.type == CalendarItemType.event;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isEvent ? () => context.push('/event/${item.id}') : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: item.isPersonal 
                                        ? Colors.purple.shade50 
                                        : (isEvent ? Colors.blue.shade50 : Colors.orange.shade50),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isEvent ? Icons.directions_run : Icons.note_alt_outlined,
                                    color: item.isPersonal 
                                        ? Colors.purple 
                                        : (isEvent ? Colors.blue : Colors.orange),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (item.startTime != null)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: Text(
                                                item.startTime!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          if (item.isPersonal)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                l10n.tabPersonal.toUpperCase(),
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.purple,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (item.description != null && item.description!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            item.description!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (item.isCompleted)
                                  const Icon(Icons.check_circle, color: Colors.green)
                                else if (isEvent)
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarStrip() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        // Range: 14 days back, 30 days forward
        itemCount: 45,
        itemBuilder: (context, index) {
          final day = DateTime.now().subtract(const Duration(days: 14)).add(Duration(days: index));
          final isSelected = day.year == _selectedDate.year && 
                             day.month == _selectedDate.month && 
                             day.day == _selectedDate.day;
          final isToday = day.year == DateTime.now().year && 
                          day.month == DateTime.now().month && 
                          day.day == DateTime.now().day;
          
          return GestureDetector(
            onTap: () {
              final oldMonth = _selectedDate.month;
              final oldYear = _selectedDate.year;
              setState(() {
                _selectedDate = day;
                if (day.month != oldMonth || day.year != oldYear) {
                  _calendarFuture = _fetchCalendar();
                }
              });
            },
            child: Container(
              width: 55,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : (isToday ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : Colors.transparent),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? Colors.transparent 
                      : (isToday ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : Colors.grey.shade200),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCityEventsTab(AppLocalizations l10n) {
    return Column(
      children: [
        _buildEventsFiltersPanel(l10n),
        Expanded(
          child: FutureBuilder<List<EventListItemModel>>(
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
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.eventsEmpty,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.eventsEmptyHint,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) => EventCard(event: events[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventsFiltersPanel(AppLocalizations l10n) {
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
              selected: _selectedClubId != null && _selectedClubId!.isNotEmpty,
              onSelected: (selected) async {
                if (!selected) {
                  setState(() {
                    _selectedClubId = null;
                    _eventsFuture = _fetchCityEvents();
                  });
                  return;
                }

                final clubId = await _resolveTrainingClubId();
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
