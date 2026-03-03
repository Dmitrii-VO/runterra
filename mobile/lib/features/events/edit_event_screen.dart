import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../shared/models/event_details_model.dart';
import '../../shared/models/event_start_location.dart';
import '../../shared/ui/error_display.dart';
import '../../shared/models/workout.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;

  const EditEventScreen({super.key, required this.eventId});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _participantLimitController = TextEditingController();

  late Future<EventDetailsModel> _loadFuture;
  EventDetailsModel? _event;
  String _eventType = 'training';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  double? _selectedLat;
  double? _selectedLon;
  String? _selectedWorkoutId;
  List<Workout> _workouts = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadEvent();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _participantLimitController.dispose();
    super.dispose();
  }

  Future<EventDetailsModel> _loadEvent() async {
    final event =
        await ServiceLocator.eventsService.getEventById(widget.eventId);
    _populateForm(event);
    _loadWorkouts(event.organizerType == 'club' ? event.organizerId : null);
    return event;
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

  void _populateForm(EventDetailsModel event) {
    _event = event;
    _nameController.text = event.name;
    _descriptionController.text = event.description ?? '';
    _locationNameController.text = event.locationName ?? '';
    _participantLimitController.text =
        event.participantLimit != null ? event.participantLimit.toString() : '';
    _eventType = event.type;
    _selectedDate = event.startDateTime;
    _selectedTime = TimeOfDay.fromDateTime(event.startDateTime);
    _selectedLat = event.startLocation?.latitude;
    _selectedLon = event.startLocation?.longitude;
    _selectedWorkoutId = event.workoutId;
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
    final result = await context.push<Map<String, dynamic>>(
      '/map/pick?lat=${_selectedLat ?? 59.93}&lon=${_selectedLon ?? 30.33}',
    );
    if (result != null && mounted) {
      setState(() {
        _selectedLat = (result['lat'] as num?)?.toDouble();
        _selectedLon = (result['lon'] as num?)?.toDouble();
      });
      // Always update location name when picker returns an address
      final address = result['address'] as String?;
      if (address != null) {
        _locationNameController.text = address;
      }
    }
  }

  Future<void> _save() async {
    if (_saving || _event == null) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final participantLimitText = _participantLimitController.text.trim();
      int? participantLimit;
      bool clearParticipantLimit = false;
      if (participantLimitText.isEmpty) {
        if (_event!.participantLimit != null) clearParticipantLimit = true;
      } else {
        participantLimit = int.tryParse(participantLimitText);
        if (participantLimit == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.eventCreateLimitInvalid)),
            );
          }
          setState(() => _saving = false);
          return;
        }
      }

      await ServiceLocator.eventsService.updateEvent(
        widget.eventId,
        name: _nameController.text.trim(),
        type: _eventType,
        startDateTime: _composeDateTime(),
        startLocation: (_selectedLat != null && _selectedLon != null)
            ? EventStartLocation(
                longitude: _selectedLon!, latitude: _selectedLat!)
            : null,
        locationName: _locationNameController.text.trim().isEmpty
            ? null
            : _locationNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        participantLimit: participantLimit,
        clearParticipantLimit: clearParticipantLimit,
      );

      if (_selectedWorkoutId != _event?.workoutId) {
        await ServiceLocator.eventsService.updateEventTrainerFields(
          widget.eventId,
          workoutId: _selectedWorkoutId,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventEditSuccess)),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventEditError(e.message))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventEditError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.eventEditTitle)),
      body: FutureBuilder<EventDetailsModel>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorDisplay(
              errorMessage: snapshot.error.toString(),
              onRetry: () {
                setState(() {
                  _loadFuture = _loadEvent();
                });
              },
            );
          }
          if (!snapshot.hasData) {
            return Center(child: Text(l10n.noData));
          }

          final dateText = '${_selectedDate.day.toString().padLeft(2, '0')}.'
              '${_selectedDate.month.toString().padLeft(2, '0')}.'
              '${_selectedDate.year}';
          final timeText = '${_selectedTime.hour.toString().padLeft(2, '0')}:'
              '${_selectedTime.minute.toString().padLeft(2, '0')}';

          return Form(
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
                                ),                    items: [
                      DropdownMenuItem(
                          value: 'training',
                          child: Text(l10n.eventTypeTraining)),
                      DropdownMenuItem(
                          value: 'group_run',
                          child: Text(l10n.eventTypeGroupRun)),
                      DropdownMenuItem(
                          value: 'club_event',
                          child: Text(l10n.eventTypeClubEvent)),
                      DropdownMenuItem(
                          value: 'open_event',
                          child: Text(l10n.eventTypeOpenEvent)),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) =>
                            setState(() => _eventType = value ?? _eventType),
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
                  TextFormField(
                    controller: _locationNameController,
                    decoration: InputDecoration(
                      labelText: l10n.eventCreateLocationName,
                      border: const OutlineInputBorder(),
                    ),
                    enabled: !_saving,
                  ),
                  const SizedBox(height: 16),
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
                        : Text(l10n.eventEditSave),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
