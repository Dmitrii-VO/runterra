import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/profile_model.dart';
import '../../shared/models/trainer_profile.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../city/city_picker_dialog.dart';

/// Edit profile screen — photo upload, name, username, and other fields.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final ProfileUserData user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _countryController;

  // F1: local file pending upload; null means no new photo selected
  XFile? _pendingPhotoFile;
  String? _avatarUrl; // current persisted avatar URL

  String? _validationError;
  String? _usernameError;
  bool _saving = false;
  DateTime? _birthDate;
  String? _gender; // only 'male' | 'female' | null
  String? _cityId;
  String? _cityName;
  late bool _profileVisible;

  TrainerProfile? _trainerProfile;
  bool _loadingTrainer = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
        text: widget.user.firstName ?? widget.user.name);
    _lastNameController =
        TextEditingController(text: widget.user.lastName ?? '');
    _usernameController =
        TextEditingController(text: widget.user.username ?? '');
    _countryController =
        TextEditingController(text: widget.user.country ?? '');
    _avatarUrl = widget.user.avatarUrl;
    _birthDate = widget.user.birthDate;
    // F2: normalise gender — only accept backend-valid values
    const validGenders = {'male', 'female'};
    _gender = validGenders.contains(widget.user.gender)
        ? widget.user.gender
        : null;
    _cityId = widget.user.cityId;
    _cityName = widget.user.cityName;
    _profileVisible = widget.user.profileVisible;

    _loadTrainerProfile();
  }

  Future<void> _loadTrainerProfile() async {
    setState(() => _loadingTrainer = true);
    try {
      final p = await ServiceLocator.trainerService.getMyProfile();
      if (mounted) setState(() => _trainerProfile = p);
    } catch (_) {
      // No trainer profile — not an error
    } finally {
      if (mounted) setState(() => _loadingTrainer = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // F1: only pick the image locally; actual upload deferred to _save()
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (xfile == null || !mounted) return;
    setState(() => _pendingPhotoFile = xfile);
  }

  Future<void> _save() async {
    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) {
      setState(() {
        _validationError = AppLocalizations.of(context)!.editProfileNameRequired;
      });
      return;
    }

    final rawUsername = _usernameController.text.trim();
    if (rawUsername.isNotEmpty &&
        !RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(rawUsername)) {
      setState(() {
        _usernameError =
            AppLocalizations.of(context)!.editProfileUsernameHint;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _usernameError = null;
      _saving = true;
    });

    try {
      // F1: upload deferred — happens here, after user taps Save
      String? avatarUrlToSave = _avatarUrl;
      if (_pendingPhotoFile != null) {
        avatarUrlToSave = await ServiceLocator.usersService
            .uploadAvatar(_pendingPhotoFile!.path);
        if (!mounted) return;
      }

      // F4: always pass lastName and country so empty = clear on backend
      final lastName = _lastNameController.text.trim();
      final country = _countryController.text.trim();
      final originalUsername = widget.user.username ?? '';
      final usernameChanged = rawUsername != originalUsername;

      await ServiceLocator.usersService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        country: country,
        birthDate: _birthDate,
        gender: _gender,
        currentCityId: _cityId,
        avatarUrl: avatarUrlToSave ?? '',
        profileVisible: _profileVisible,
        username: usernameChanged && rawUsername.isNotEmpty ? rawUsername : null,
        clearUsername: usernameChanged && rawUsername.isEmpty,
      );

      FirebaseAnalytics.instance.logEvent(name: 'profile_edit');

      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'username_taken') {
        setState(() {
          _usernameError =
              AppLocalizations.of(context)!.editProfileUsernameConflict;
          _saving = false;
        });
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _toggleTrainer(bool value) async {
    if (_trainerProfile == null) {
      final result = await context.push<bool>('/trainer/edit');
      if (result == true) _loadTrainerProfile();
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await ServiceLocator.trainerService.updateProfile({
        'acceptsPrivateClients': value,
      });
      if (mounted) setState(() => _trainerProfile = updated);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final birthDateText = _birthDate != null
        ? '${_birthDate!.day.toString().padLeft(2, '0')}.'
            '${_birthDate!.month.toString().padLeft(2, '0')}.'
            '${_birthDate!.year}'
        : l10n.profileNotSpecified;
    final cityText = (_cityName != null && _cityName!.isNotEmpty)
        ? _cityName!
        : (_cityId != null && _cityId!.isNotEmpty
            ? _cityId!
            : l10n.profileNotSpecified);

    // F1: show local file preview if user picked a photo, else stored URL
    final ImageProvider? avatarImage = _pendingPhotoFile != null
        ? FileImage(File(_pendingPhotoFile!.path))
        : (_avatarUrl != null && _avatarUrl!.isNotEmpty
            ? NetworkImage(_avatarUrl!) as ImageProvider
            : null);
    final bool hasAvatar = avatarImage != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundImage: avatarImage,
                    onForegroundImageError: hasAvatar ? (_, __) {} : null,
                    child: !hasAvatar
                        ? Text(
                            _firstNameController.text.isNotEmpty
                                ? _firstNameController.text[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 36,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: colorScheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _saving ? null : _pickPhoto,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _pendingPhotoFile != null
                    ? l10n.editProfilePhotoSelected
                    : l10n.editProfilePhotoChange,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _pendingPhotoFile != null
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // First name
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: l10n.editProfileFirstName,
                errorText: _validationError,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !_saving,
            ),
            const SizedBox(height: 16),

            // Last name
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: l10n.editProfileLastName,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !_saving,
            ),
            const SizedBox(height: 16),

            // Username
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: l10n.editProfileUsername,
                hintText: l10n.editProfileUsernameHint,
                prefixText: '@',
                errorText: _usernameError,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.visiblePassword,
              autocorrect: false,
              enabled: !_saving,
              onChanged: (_) {
                if (_usernameError != null) {
                  setState(() => _usernameError = null);
                }
              },
            ),
            const SizedBox(height: 16),

            // Country
            TextField(
              controller: _countryController,
              decoration: InputDecoration(
                labelText: l10n.editProfileCountry,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !_saving,
            ),
            const SizedBox(height: 16),

            // Birth date picker
            InkWell(
              onTap: _saving
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _birthDate ?? DateTime(2000, 1, 1),
                        firstDate: DateTime(1900, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      // F3: guard against setState after dispose
                      if (picked == null || !mounted) return;
                      setState(() => _birthDate = picked);
                    },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.editProfileBirthDate,
                  border: const OutlineInputBorder(),
                ),
                child: Text(birthDateText),
              ),
            ),
            const SizedBox(height: 16),

            // Gender — F2: only male/female (matches backend Zod enum)
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: l10n.editProfileGender,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
                DropdownMenuItem(
                    value: 'female', child: Text(l10n.genderFemale)),
              ],
              onChanged:
                  _saving ? null : (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 16),

            // City picker
            InkWell(
              onTap: _saving
                  ? null
                  : () async {
                      final selected = await showCityPickerDialog(context);
                      // F3: guard against setState after dispose
                      if (selected == null || !mounted) return;
                      try {
                        final city = await ServiceLocator.citiesService
                            .getCityById(selected);
                        if (!mounted) return;
                        setState(() {
                          _cityId = selected;
                          _cityName = city.name;
                        });
                      } catch (_) {
                        if (!mounted) return;
                        setState(() {
                          _cityId = selected;
                          _cityName = selected;
                        });
                      }
                    },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.editProfileCity,
                  border: const OutlineInputBorder(),
                ),
                child: Text(cityText),
              ),
            ),
            const SizedBox(height: 24),

            // Trainer section
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.trainerSection,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_loadingTrainer)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.trainerAcceptsClients),
                subtitle: Text(
                  _trainerProfile == null
                      ? l10n.trainerSetupProfile
                      : l10n.trainerAcceptsClientsHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: _trainerProfile?.acceptsPrivateClients ?? false,
                onChanged: _saving ? null : _toggleTrainer,
              ),

            // Profile visibility
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.profileVisibilityToggle),
              subtitle: Text(
                l10n.profileVisibilityHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: _profileVisible,
              onChanged:
                  _saving ? null : (v) => setState(() => _profileVisible = v),
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
                  : Text(l10n.editProfileSave),
            ),
          ],
        ),
      ),
    );
  }
}
