import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/workout_plan.dart';
import '../../l10n/app_localizations.dart';

/// Screen showing personal workouts with [Мои] and [Сохранённые] tabs.
class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<WorkoutPlan>> _myWorkoutsFuture;
  late Future<List<WorkoutPlan>> _templatesFuture;
  late Future<List<Map<String, dynamic>>> _sharesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  void _loadAll() {
    _myWorkoutsFuture = ServiceLocator.workoutPlanService.getMyWorkouts();
    _templatesFuture = ServiceLocator.workoutPlanService.getTemplates();
    _sharesFuture = ServiceLocator.workoutPlanService.getReceivedShares();
  }

  void _refresh() {
    setState(_loadAll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workouts),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.workoutTabMy),
            Tab(text: l10n.workoutTabSaved),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/workout/create');
              _refresh();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyTab(
            workoutsFuture: _myWorkoutsFuture,
            sharesFuture: _sharesFuture,
            onRefresh: _refresh,
          ),
          _SavedTab(
            templatesFuture: _templatesFuture,
            onRefresh: _refresh,
          ),
        ],
      ),
    );
  }
}

// ── My tab ────────────────────────────────────────────────────────────────────

class _MyTab extends StatelessWidget {
  final Future<List<WorkoutPlan>> workoutsFuture;
  final Future<List<Map<String, dynamic>>> sharesFuture;
  final VoidCallback onRefresh;

  const _MyTab({
    required this.workoutsFuture,
    required this.sharesFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: FutureBuilder<List<WorkoutPlan>>(
        future: workoutsFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final workouts = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // Incoming shares section
              _IncomingSharesSection(
                future: sharesFuture,
                onRefresh: onRefresh,
              ),
              // My workouts
              if (workouts.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(l10n.workoutEmpty)),
                )
              else
                ...workouts.map(
                  (w) => _WorkoutCard(
                    workout: w,
                    onRefresh: onRefresh,
                    showAddToPlan: false,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Incoming shares ───────────────────────────────────────────────────────────

class _IncomingSharesSection extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onRefresh;

  const _IncomingSharesSection({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snap) {
        final shares = snap.data ?? [];
        if (shares.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                l10n.workoutIncomingShares,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            ...shares.map((share) => _ShareCard(share: share, onRefresh: onRefresh)),
            const Divider(),
          ],
        );
      },
    );
  }
}

class _ShareCard extends StatefulWidget {
  final Map<String, dynamic> share;
  final VoidCallback onRefresh;

  const _ShareCard({required this.share, required this.onRefresh});

  @override
  State<_ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends State<_ShareCard> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await ServiceLocator.workoutPlanService.acceptShare(widget.share['id'] as String);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.workoutShareAccepted)));
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workout = widget.share['workout'] as Map<String, dynamic>?;
    final senderName = widget.share['senderName'] as String? ?? '?';
    final workoutName = workout?['name'] as String? ?? '—';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.share, color: Colors.blue),
        title: Text(workoutName),
        subtitle: Text(l10n.workoutShareFrom(senderName)),
        trailing: _loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(
                onPressed: _accept,
                child: Text(l10n.workoutShareAccept),
              ),
      ),
    );
  }
}

// ── Saved tab ─────────────────────────────────────────────────────────────────

class _SavedTab extends StatelessWidget {
  final Future<List<WorkoutPlan>> templatesFuture;
  final VoidCallback onRefresh;

  const _SavedTab({required this.templatesFuture, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: FutureBuilder<List<WorkoutPlan>>(
        future: templatesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final templates = snap.data ?? [];
          if (templates.isEmpty) {
            return Center(child: Text(l10n.workoutEmpty));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: templates.length,
            itemBuilder: (context, i) => _WorkoutCard(
              workout: templates[i],
              onRefresh: onRefresh,
              showAddToPlan: true,
            ),
          );
        },
      ),
    );
  }
}

// ── Workout card ──────────────────────────────────────────────────────────────

class _WorkoutCard extends StatefulWidget {
  final WorkoutPlan workout;
  final VoidCallback onRefresh;
  final bool showAddToPlan;

  const _WorkoutCard({
    required this.workout,
    required this.onRefresh,
    required this.showAddToPlan,
  });

  @override
  State<_WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<_WorkoutCard> {
  bool _favLoading = false;

  Future<void> _toggleFav() async {
    if (widget.workout.id == null) return;
    setState(() => _favLoading = true);
    try {
      await ServiceLocator.workoutPlanService.toggleFavorite(widget.workout.id!);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  Future<void> _addToPlan() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !mounted) return;

    final scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    try {
      // Create a copy with scheduled_at
      await ServiceLocator.workoutPlanService.createWorkout(
        widget.workout.copyWith(scheduledAt: scheduledAt, id: null, isTemplate: false),
      );
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.workoutAddToPlan)));
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _shareWorkout() {
    if (widget.workout.id == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ShareBottomSheet(
        workout: widget.workout,
        onDone: () {
          Navigator.of(ctx).pop();
          widget.onRefresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final w = widget.workout;
    final typeName = _typeName(w.type, l10n);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(typeName,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                // Heart/favorite icon
                _favLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: Icon(
                          w.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: w.isFavorite ? Colors.red : null,
                        ),
                        onPressed: _toggleFav,
                        tooltip: w.isFavorite
                            ? l10n.workoutFavoriteRemoved
                            : l10n.workoutFavoriteAdded,
                      ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Start button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/workout/active', extra: w),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(l10n.workoutSavedStart),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Share button
                OutlinedButton(
                  onPressed: _shareWorkout,
                  child: const Icon(Icons.share, size: 18),
                ),
                if (widget.showAddToPlan) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _addToPlan,
                    child: const Icon(Icons.calendar_today, size: 18),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _typeName(WorkoutPlanType type, AppLocalizations l10n) {
    switch (type) {
      case WorkoutPlanType.easyRun:
        return l10n.workoutTypeEasyRun;
      case WorkoutPlanType.longRun:
        return l10n.workoutTypeLongRun;
      case WorkoutPlanType.intervals:
        return l10n.workoutTypeIntervals;
      case WorkoutPlanType.progression:
        return l10n.workoutTypeProgression;
      case WorkoutPlanType.recovery:
        return l10n.workoutTypeRecovery;
      case WorkoutPlanType.hillRun:
        return l10n.workoutTypeHillRun;
    }
  }
}

// ── Share bottom sheet ─────────────────────────────────────────────────────────

class _ShareBottomSheet extends StatefulWidget {
  final WorkoutPlan workout;
  final VoidCallback onDone;

  const _ShareBottomSheet({required this.workout, required this.onDone});

  @override
  State<_ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<_ShareBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  // Friend search
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  final Set<String> _selectedFriends = {};
  bool _searching = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ServiceLocator.usersService.searchUsers(query);
      setState(() => _searchResults = results
          .map((u) => {'id': u.id, 'name': u.name})
          .toList());
    } catch (_) {
      setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendToFriends() async {
    if (_selectedFriends.isEmpty || widget.workout.id == null) return;
    setState(() => _sending = true);
    try {
      await ServiceLocator.workoutPlanService.shareWorkout(
        widget.workout.id!,
        _selectedFriends.toList(),
      );
      widget.onDone();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            tabs: [
              Tab(text: l10n.workoutShareAsTrainer),
              Tab(text: l10n.workoutShareWithFriends),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _TrainerShareTab(workout: widget.workout, onDone: widget.onDone),
                _FriendsShareTab(
                  searchCtrl: _searchCtrl,
                  results: _searchResults,
                  selected: _selectedFriends,
                  searching: _searching,
                  sending: _sending,
                  onSearch: _search,
                  onToggle: (id) => setState(() {
                    if (_selectedFriends.contains(id)) {
                      _selectedFriends.remove(id);
                    } else {
                      _selectedFriends.add(id);
                    }
                  }),
                  onSend: _sendToFriends,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerShareTab extends StatefulWidget {
  final WorkoutPlan workout;
  final VoidCallback onDone;

  const _TrainerShareTab({required this.workout, required this.onDone});

  @override
  State<_TrainerShareTab> createState() => _TrainerShareTabState();
}

class _TrainerShareTabState extends State<_TrainerShareTab> {
  List<Map<String, dynamic>> _clients = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await ServiceLocator.trainerService.getTrainerClients();
      setState(() {
        _clients = clients.map((c) => {'id': c.clientId, 'name': c.clientName}).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_selected.isEmpty || widget.workout.id == null) return;
    setState(() => _sending = true);
    try {
      await ServiceLocator.workoutPlanService.shareWorkout(
        widget.workout.id!,
        _selected.toList(),
      );
      widget.onDone();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_clients.isEmpty) {
      return Center(child: Text(l10n.workoutAssignedEmpty));
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _clients.length,
            itemBuilder: (context, i) {
              final c = _clients[i];
              final id = c['id'] as String;
              return CheckboxListTile(
                value: _selected.contains(id),
                onChanged: (v) => setState(() {
                  if (v == true) { _selected.add(id); } else { _selected.remove(id); }
                }),
                title: Text(c['name'] as String),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected.isEmpty || _sending ? null : _send,
              child: _sending
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.workoutShareSend),
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendsShareTab extends StatelessWidget {
  final TextEditingController searchCtrl;
  final List<Map<String, dynamic>> results;
  final Set<String> selected;
  final bool searching;
  final bool sending;
  final void Function(String) onSearch;
  final void Function(String) onToggle;
  final VoidCallback onSend;

  const _FriendsShareTab({
    required this.searchCtrl,
    required this.results,
    required this.selected,
    required this.searching,
    required this.sending,
    required this.onSearch,
    required this.onToggle,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: l10n.peopleSearchHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        if (searching)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, i) {
                final u = results[i];
                final id = u['id'] as String;
                return CheckboxListTile(
                  value: selected.contains(id),
                  onChanged: (_) => onToggle(id),
                  title: Text(u['name'] as String),
                );
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected.isEmpty || sending ? null : onSend,
              child: sending
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.workoutShareSend),
            ),
          ),
        ),
      ],
    );
  }
}
