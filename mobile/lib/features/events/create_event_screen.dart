import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/event_start_location.dart';
import '../../shared/models/city_model.dart';
import '../../shared/models/workout.dart';

class CreateEventScreen extends StatefulWidget {
  final String? initialType;

  const CreateEventScreen({super.key, this.initialType});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _organizerIdController = TextEditingController();
  final _participantLimitController = TextEditingController();

  late String _eventType;
  String _organizerType = 'club';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _saving = false;
  String? _cityId;
  String? _cityName;
  bool _hasClub = false;
  String? _selectedWorkoutId;
  List<Workout> _workouts = [];

  // Location picker state (replaces lat/lon controllers)
  double? _selectedLat;
  double? _selectedLon;

  @override
  void initState() {
    super.initState();
    _eventType = widget.initialType ?? 'training';
    _loadDefaults();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _organizerIdController.dispose();
    _participantLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final currentCityId = ServiceLocator.currentCityService.currentCityId;
    setState(() {
      _cityId = currentCityId;
    });

    // Auto-fill organizer
    final clubId = ServiceLocator.currentClubService.currentClubId;
    if (clubId != null && clubId.isNotEmpty) {
      _organizerIdController.text = clubId;
      _organizerType = 'club';
      setState(() => _hasClub = true);
      _loadWorkouts(clubId);
    } else {
      // No club — use user profile as trainer
      _organizerType = 'trainer';
      try {
        final profile = await ServiceLocator.usersService.getProfile();
        _organizerIdController.text = profile.user.id;
        _loadWorkouts();
      } catch (e) {
        debugPrint('Error loading profile for organizer: $e');
      }
    }

    CityModel? city;
    try {
      city = await ServiceLocator.currentCityService.getCurrentCity();
    } catch (e) {
      debugPrint('Error loading city defaults: $e');
      city = null;
    }

    if (city != null) {
      setState(() {
        _cityName = city!.name;
        _selectedLat = city.center.latitude;
        _selectedLon = city.center.longitude;
      });
    }
  }

  Future<void> _loadWorkouts([String? clubId]) async {
    try {
      final personal = await ServiceLocator.workoutsService.getWorkouts();
      final club = clubId != null
          ? await ServiceLocator.workoutsService.getWorkouts(clubId: clubId)
          : <Workout>[];
      final seen = <String>{};
      final merged = [...personal, ...club].where((w) => seen.add(w.id)).toList();
      if (mounted) setState(() => _workouts = merged);
    } catch (e) {
      debugPrint('Error loading workouts: $e');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null) return;
    setState(() => _selectedTime = picked);
  }

  DateTime _composeDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickLocation() async {
    final result = await context.push<Map<String, double>>(
      '/map/pick?lat=${_selectedLat ?? 59.93}&lon=${_selectedLon ?? 30.33}',
    );
    if (result != null && mounted) {
      setState(() {
        _selectedLat = result['lat'];
        _selectedLon = result['lon'];
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_cityId == null || _cityId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventCreateCityRequired)),
      );
      return;
    }
    if (_selectedLat == null || _selectedLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventCreateLocationRequired)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final participantLimitText = _participantLimitController.text.trim();
      final participantLimit = participantLimitText.isEmpty
          ? null
          : int.tryParse(participantLimitText);
      if (participantLimitText.isNotEmpty && participantLimit == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.eventCreateLimitInvalid)),
          );
        }
        setState(() => _saving = false);
        return;
      }

      final event = await ServiceLocator.eventsService.createEvent(
        name: _nameController.text.trim(),
        type: _eventType,
        startDateTime: _composeDateTime(),
        startLocation: EventStartLocation(
          longitude: _selectedLon!,
          latitude: _selectedLat!,
        ),
        locationName: _locationNameController.text.trim().isEmpty
            ? null
            : _locationNameController.text.trim(),
        organizerId: _organizerIdController.text.trim(),
        organizerType: _organizerType,
        cityId: _cityId!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        participantLimit: participantLimit,
        workoutId: _selectedWorkoutId,
      );

      // Логируем создание мероприятия
      FirebaseAnalytics.instance.logEvent(
        name: 'event_create',
        parameters: {
          'event_id': event.id,
          'type': _eventType,
          'organizer_type': _organizerType,
          'city_id': _cityId!,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventCreateSuccess)),
      );
      context.go('/event/${event.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventCreateError(e.toString()))),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateText =
        '${_selectedDate.day.toString().padLeft(2, '0')}.'
        '${_selectedDate.month.toString().padLeft(2, '0')}.'
        '${_selectedDate.year}';
    final timeText =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:'
        '${_selectedTime.minute.toString().padLeft(2, '0')}';
    final cityDisplay = (_cityName != null && _cityName!.isNotEmpty)
        ? _cityName!
        : l10n.eventCreateSelectCity;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventCreateTitle),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.eventCreateName,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.eventCreateNameRequired;
                  }
                  return null;
                },
                enabled: !_saving,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _eventType,
                decoration: InputDecoration(
                  labelText: l10n.eventCreateType,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'training', child: Text(l10n.eventTypeTraining)),
                  DropdownMenuItem(value: 'open_event', child: Text(l10n.eventTypeOpenEvent)),
                ],
                onChanged: _saving ? null : (value) => setState(() => _eventType = value ?? _eventType),
              ),
              const SizedBox(height: 16),
              if (_eventType == 'training') ...[
                DropdownButtonFormField<String?>(
                  value: _selectedWorkoutId,
                  decoration: InputDecoration(
                    labelText: l10n.eventWorkout,
                    border: const OutlineInputBorder(),
                    hintText: l10n.eventSelectWorkout,
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.eventNoWorkout)),
                    ..._workouts.map((w) => DropdownMenuItem(
                          value: w.id,
                          child: Text(w.name),
                        )),
                  ],
                  onChanged: _saving ? null : (value) => setState(() => _selectedWorkoutId = value),
                ),
                const SizedBox(height: 16),
              ],
              InkWell(
                onTap: _saving ? null : _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.eventCreateDate,
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(dateText),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _saving ? null : _pickTime,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.eventCreateTime,
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(timeText),
                ),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.eventCreateCity,
                  border: const OutlineInputBorder(),
                ),
                child: Text(cityDisplay),
              ),
              const SizedBox(height: 16),
              // Organizer type: only show if user has a club (to choose between club/personal event)
              if (_hasClub) ...[
                DropdownButtonFormField<String>(
                  value: _organizerType,
                  decoration: InputDecoration(
                    labelText: l10n.eventCreateOrganizerType,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'club', child: Text(l10n.eventCreateOrganizerClub)),
                    DropdownMenuItem(value: 'trainer', child: Text(l10n.eventCreateOrganizerTrainer)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) async {
                          setState(() => _organizerType = value ?? _organizerType);
                          // Update organizerId and reload workouts based on selection
                          if (value == 'club') {
                            final clubId = ServiceLocator.currentClubService.currentClubId;
                            if (clubId != null && clubId.isNotEmpty) {
                              _organizerIdController.text = clubId;
                              _loadWorkouts(clubId);
                            }
                          } else {
                            try {
                              final profile = await ServiceLocator.usersService.getProfile();
                              _organizerIdController.text = profile.user.id;
                            } catch (_) {}
                            _loadWorkouts();
                          }
                        },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _locationNameController,
                decoration: InputDecoration(
                  labelText: l10n.eventCreateLocationName,
                  border: const OutlineInputBorder(),
                ),
                enabled: !_saving,
              ),
              const SizedBox(height: 16),
              // Location picker button (replaces lat/lon text fields)
              OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: Text(
                  _selectedLat != null
                      ? l10n.eventCreateLocationSelected
                      : l10n.eventCreatePickLocation,
                ),
                onPressed: _saving ? null : _pickLocation,
              ),
              if (_selectedLat != null && _selectedLon != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${_selectedLat!.toStringAsFixed(5)}, ${_selectedLon!.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _participantLimitController,
                decoration: InputDecoration(
                  labelText: l10n.eventCreateParticipantLimit,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                enabled: !_saving,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.eventCreateDescription,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                enabled: !_saving,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.eventCreateSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
