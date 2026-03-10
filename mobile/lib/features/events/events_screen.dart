import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  // Calendar
  final _calendarScrollController = ScrollController();
  DateTime? _selectedDate;
  late final List<DateTime> _calendarDays;

  // F3: club filter from GoRouter query params
  String? _clubId;
  bool _initialized = false;

  // Category chips (multi-select, all enabled by default)
  final Set<String> _selectedTypes = {'group_run', 'open_event', 'training', 'club_event'};

  // Sort
  String _sortBy = 'relevance';

  // Infinite scroll
  final _scrollController = ScrollController();
  final List<EventListItemModel> _events = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  bool _paginationError = false; // F6: pagination error for retry button
  int _offset = 0;
  int _generation = 0; // F1: generation counter to discard stale fetches
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _calendarDays = _buildCalendarDays();
    _scrollController.addListener(_onScroll);
    // Initial load happens in didChangeDependencies (F3: reads clubId from router)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // F3: read clubId from GoRouter query params
    final newClubId = GoRouterState.of(context).uri.queryParameters['clubId'];
    if (!_initialized) {
      _initialized = true;
      _clubId = newClubId;
      _loadEvents(refresh: true);
    } else if (newClubId != _clubId) {
      _clubId = newClubId;
      _loadEvents(refresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  List<DateTime> _buildCalendarDays() {
    final today = DateTime.now();
    return List.generate(
      61,
      (i) => DateTime(today.year, today.month, today.day + i),
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && !_paginationError) _loadEvents();
    }
  }

  Future<void> _loadEvents({bool refresh = false}) async {
    // F1: refresh always proceeds; pagination skips if already loading
    if (_isLoading && !refresh) return;

    final cityId = ServiceLocator.currentCityService.currentCityId;
    // F5: no city → stop spinner, show message
    if (cityId == null || cityId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    // F1: increment generation on refresh so in-flight old requests are discarded
    if (refresh) _generation++;
    final myGen = _generation;

    setState(() {
      _isLoading = true;
      _paginationError = false;
      if (refresh) {
        _offset = 0;
        _hasMore = true;
        _error = null;
        _events.clear(); // F4: clear before await — error won't show stale data
      }
    });

    try {
      final page = await ServiceLocator.eventsService.getEvents(
        cityId: cityId,
        sortBy: _sortBy,
        eventTypes: _selectedTypes.toList(),
        date: _selectedDate,
        clubId: _clubId,
        limit: _pageSize,
        offset: refresh ? 0 : _offset,
      );

      // F1: discard results from a superseded generation
      if (!mounted || myGen != _generation) return;

      setState(() {
        _isLoading = false;
        if (refresh) {
          _events
            ..clear()
            ..addAll(page);
        } else {
          _events.addAll(page);
        }
        _offset = (refresh ? 0 : _offset) + page.length;
        _hasMore = page.length == _pageSize;
      });
    } catch (e) {
      if (!mounted || myGen != _generation) return;
      setState(() {
        _isLoading = false;
        if (refresh) {
          _error = e.toString();
        } else {
          // F6: pagination error → stop spinner, show retry button
          _hasMore = false;
          _paginationError = true;
        }
      });
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadEvents(refresh: true);
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
    _loadEvents(refresh: true);
  }

  void _toggleType(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        if (_selectedTypes.length > 1) _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
    _loadEvents(refresh: true);
  }

  void _onSortChanged(String? value) {
    if (value == null || value == _sortBy) return;
    setState(() => _sortBy = value);
    _loadEvents(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventsTitle),
        actions: [
          _buildSortDropdown(l10n),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/event/create?type=open_event'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildCalendarStrip(l10n),
          if (_selectedDate != null) _buildShowAllButton(l10n),
          _buildCategoryChips(l10n),
          Expanded(child: _buildEventsList(l10n)),
        ],
      ),
    );
  }

  Widget _buildSortDropdown(AppLocalizations l10n) {
    final sortOptions = {
      'relevance': l10n.eventsSortRelevance,
      'date_asc': l10n.eventsSortDateAsc,
      'date_desc': l10n.eventsSortDateDesc,
      'price_asc': l10n.eventsSortPriceAsc,
      'price_desc': l10n.eventsSortPriceDesc,
    };

    return DropdownButton<String>(
      value: _sortBy,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.sort),
      items: sortOptions.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: _onSortChanged,
    );
  }

  Widget _buildCalendarStrip(AppLocalizations l10n) {
    final today = DateTime.now();

    return SizedBox(
      height: 72,
      child: ListView.builder(
        controller: _calendarScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _calendarDays.length,
        itemBuilder: (context, i) {
          final day = _calendarDays[i];
          final isToday = day.year == today.year &&
              day.month == today.month &&
              day.day == today.day;
          final isSelected = _selectedDate != null &&
              day.year == _selectedDate!.year &&
              day.month == _selectedDate!.month &&
              day.day == _selectedDate!.day;
          // F8: localized weekday abbreviation via intl
          final weekday = DateFormat('EEE', l10n.localeName).format(day);

          return GestureDetector(
            onTap: () => _selectDate(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 46,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : isToday
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : isToday
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
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

  Widget _buildShowAllButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _clearDateFilter,
          icon: const Icon(Icons.close, size: 16),
          label: Text(l10n.eventsShowAll),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(AppLocalizations l10n) {
    final categories = [
      ('group_run', l10n.eventCategoryRaces),
      ('open_event', l10n.eventCategoryCompetitions),
      ('training', l10n.eventCategoryTrainingOpen),
      ('club_event', l10n.eventCategoryClub),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: categories.map((cat) {
          final type = cat.$1;
          final label = cat.$2;
          final isSelected = _selectedTypes.contains(type);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => _toggleType(type),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventsList(AppLocalizations l10n) {
    // F5: no city selected
    final cityId = ServiceLocator.currentCityService.currentCityId;
    if (!_isLoading && _events.isEmpty && (cityId == null || cityId.isEmpty)) {
      return Center(child: Text(l10n.eventsNoCitySelected));
    }

    if (_error != null && _events.isEmpty) {
      return Center(child: Text(_error!));
    }

    if (!_isLoading && _events.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadEvents(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 300,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      _selectedDate != null
                          ? l10n.eventsEmptyFiltered
                          : l10n.eventsEmpty,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadEvents(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _events.length + (_hasMore || _isLoading || _paginationError ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _events.length) {
            // F6: pagination error → retry button instead of infinite spinner
            if (_paginationError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _paginationError = false);
                      _loadEvents();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.eventsRetry),
                  ),
                ),
              );
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return EventCard(event: _events[index]);
        },
      ),
    );
  }
}
