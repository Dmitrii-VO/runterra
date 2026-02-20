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

    return ServiceLocator.eventsService.getEvents(
      cityId: cityId,
      dateFilter: _selectedDateFilter,
      clubId: _selectedClubId,
      onlyOpen: _onlyOpen,
    );
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noClubChats, // "Вы пока не состоите в клубе"
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
                    return Center(child: Text(l10n.noData));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: dayItems.length,
                    itemBuilder: (context, index) {
                      final item = dayItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Icon(
                            item.type == CalendarItemType.event ? Icons.event : Icons.note_alt,
                            color: item.isPersonal ? Colors.purple : Colors.blue,
                          ),
                          title: Text(item.name),
                          subtitle: Text("${item.startTime ?? ''} ${item.description ?? ''}"),
                          trailing: item.isPersonal 
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4)),
                                child: Text(l10n.planTypePersonal, style: const TextStyle(fontSize: 10, color: Colors.purple)),
                              )
                            : null,
                          onTap: item.type == CalendarItemType.event 
                            ? () => context.push('/event/${item.id}') 
                            : null,
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
        itemCount: 31, // Show a month
        itemBuilder: (context, index) {
          final day = DateTime.now().add(Duration(days: index - 3)); // Start from 3 days ago
          final isSelected = day.year == _selectedDate.year && 
                             day.month == _selectedDate.month && 
                             day.day == _selectedDate.day;
          
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDate = day;
              // If month changed, reload calendar
              _calendarFuture = _fetchCalendar();
            }),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
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
        if (events.isEmpty) return Center(child: Text(l10n.eventsEmpty));

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) => EventCard(event: events[index]),
        );
      },
    );
  }
}
