import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/event_start_location.dart';
import '../../shared/models/city_model.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _organizerIdController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _participantLimitController = TextEditingController();

  String _eventType = 'training';
  String _organizerType = 'club';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _saving = false;
  String? _cityId;
  String? _cityName;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _organizerIdController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _participantLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final currentCityId = ServiceLocator.currentCityService.currentCityId;
    setState(() {
      _cityId = currentCityId;
    });

    final clubId = ServiceLocator.currentClubService.currentClubId;
    if (clubId != null && clubId.isNotEmpty) {
      _organizerIdController.text = clubId;
      _organizerType = 'club';
    }

    CityModel? city;
    try {
      city = await ServiceLocator.currentCityService.getCurrentCity();
    } catch (_) {
      city = null;
    }

    if (city != null) {
      setState(() {
        _cityName = city!.name;
      });
      _latitudeController.text = city.center.latitude.toStringAsFixed(6);
      _longitudeController.text = city.center.longitude.toStringAsFixed(6);
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

    setState(() => _saving = true);
    try {
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
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
          longitude: longitude,
          latitude: latitude,
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
        : (_cityId ?? l10n.profileNotSpecified);

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
                  DropdownMenuItem(value: 'group_run', child: Text(l10n.eventTypeGroupRun)),
                  DropdownMenuItem(value: 'club_event', child: Text(l10n.eventTypeClubEvent)),
                  DropdownMenuItem(value: 'open_event', child: Text(l10n.eventTypeOpenEvent)),
                ],
                onChanged: _saving ? null : (value) => setState(() => _eventType = value ?? _eventType),
              ),
              const SizedBox(height: 16),
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
              TextFormField(
                controller: _organizerIdController,
                decoration: InputDecoration(
                  labelText: l10n.eventCreateOrganizerId,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.eventCreateOrganizerRequired;
                  }
                  return null;
                },
                enabled: !_saving,
              ),
              const SizedBox(height: 16),
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
                onChanged: _saving ? null : (value) => setState(() => _organizerType = value ?? _organizerType),
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: InputDecoration(
                        labelText: l10n.eventCreateLatitude,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return l10n.eventCreateCoordinatesRequired;
                        return double.tryParse(value.trim()) == null
                            ? l10n.eventCreateCoordinatesInvalid
                            : null;
                      },
                      enabled: !_saving,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: InputDecoration(
                        labelText: l10n.eventCreateLongitude,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return l10n.eventCreateCoordinatesRequired;
                        return double.tryParse(value.trim()) == null
                            ? l10n.eventCreateCoordinatesInvalid
                            : null;
                      },
                      enabled: !_saving,
                    ),
                  ),
                ],
              ),
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
