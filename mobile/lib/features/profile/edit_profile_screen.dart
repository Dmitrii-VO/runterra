import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart';
import '../../shared/auth/auth_service.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/profile_model.dart';
import '../../shared/models/trainer_profile.dart';
import '../city/city_picker_dialog.dart';
import '../../app.dart';

/// Edit profile screen — form to change name, avatar URL, and settings.
/// Settings: geolocation, profile visibility, logout, delete account.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final ProfileModel profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _countryController;
  late final TextEditingController _avatarUrlController;
  String? _validationError;
  bool _saving = false;
  DateTime? _birthDate;
  String? _gender;
  String? _cityId;
  String? _cityName;
  bool _locationPermissionGranted = false;
  bool? _profileVisibleOverride;
  bool _savingProfileVisible = false;
  TrainerProfile? _trainerProfile;
  bool _trainerProfileLoaded = false;
  bool _savingAcceptsPrivateClients = false;

  ProfileUserData get _user => widget.profile.user;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: _user.firstName ?? _user.name);
    _lastNameController = TextEditingController(text: _user.lastName ?? '');
    _countryController = TextEditingController(text: _user.country ?? '');
    _avatarUrlController = TextEditingController(text: _user.avatarUrl ?? '');
    _birthDate = _user.birthDate;
    _gender = _user.gender;
    _cityId = _user.cityId;
    _cityName = _user.cityName;
    _checkLocationPermission();
    _loadTrainerProfile();
  }

  Future<void> _loadTrainerProfile() async {
    try {
      final profile = await ServiceLocator.trainerService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _trainerProfile = profile;
        _trainerProfileLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _trainerProfileLoaded = true);
    }
  }

  Future<void> _checkLocationPermission() async {
    final permission = await ServiceLocator.locationService.checkPermission();
    if (!mounted) return;
    setState(() {
      _locationPermissionGranted = permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) {
      setState(() {
        _validationError = AppLocalizations.of(context)!.editProfileNameRequired;
      });
      return;
    }
    setState(() {
      _validationError = null;
      _saving = true;
    });
    try {
      final lastName = _lastNameController.text.trim();
      final country = _countryController.text.trim();
      final avatarUrl = _avatarUrlController.text.trim();
      await ServiceLocator.usersService.updateProfile(
        firstName: firstName,
        lastName: lastName.isEmpty ? null : lastName,
        birthDate: _birthDate,
        country: country.isEmpty ? null : country,
        gender: _gender,
        currentCityId: _cityId,
        avatarUrl: avatarUrl.isEmpty ? '' : avatarUrl,
      );
      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final birthDateText = _birthDate != null
        ? '${_birthDate!.day.toString().padLeft(2, '0')}.'
            '${_birthDate!.month.toString().padLeft(2, '0')}.'
            '${_birthDate!.year}'
        : l10n.profileNotSpecified;
    final cityText = (_cityName != null && _cityName!.isNotEmpty)
        ? _cityName!
        : (_cityId != null && _cityId!.isNotEmpty ? _cityId! : l10n.profileNotSpecified);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      if (picked == null) return;
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
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _gender,
              decoration: InputDecoration(
                labelText: l10n.editProfileGender,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
                DropdownMenuItem(value: 'female', child: Text(l10n.genderFemale)),
              ],
              onChanged: _saving ? null : (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _saving
                  ? null
                  : () async {
                      final selected = await showCityPickerDialog(context);
                      if (selected == null) return;
                      try {
                        final city = await ServiceLocator.citiesService.getCityById(selected);
                        setState(() {
                          _cityId = selected;
                          _cityName = city.name;
                        });
                      } catch (_) {
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
            const SizedBox(height: 16),
            TextField(
              controller: _avatarUrlController,
              decoration: InputDecoration(
                labelText: l10n.editProfilePhotoUrl,
                hintText: 'https://…',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
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
                  : Text(l10n.editProfileSave),
            ),
            const SizedBox(height: 24),
            _buildTrainerSection(l10n),
            const SizedBox(height: 32),
            _buildSettingsSection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerSection(AppLocalizations l10n) {
    final profile = _trainerProfile;
    final acceptsClients = profile?.acceptsPrivateClients ?? false;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              l10n.trainerSection,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (_trainerProfileLoaded)
            SwitchListTile(
              title: Text(l10n.trainerAcceptsClients),
              subtitle: Text(l10n.trainerAcceptsClientsHint,
                  style: Theme.of(context).textTheme.bodySmall),
              value: acceptsClients,
              onChanged: _savingAcceptsPrivateClients || !_trainerProfileLoaded || profile == null
                  ? null
                  : (value) => _onAcceptsPrivateClientsChanged(value, l10n),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sports),
            title: Text(l10n.trainerSetupProfile),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await context.push<bool>(
                '/trainer/edit',
                extra: profile,
              );
              if (result == true && mounted) _loadTrainerProfile();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onAcceptsPrivateClientsChanged(bool value, AppLocalizations l10n) async {
    setState(() => _savingAcceptsPrivateClients = true);
    try {
      await ServiceLocator.trainerService.updateProfile({'acceptsPrivateClients': value});
      if (mounted) {
        setState(() {
          _trainerProfile = TrainerProfile(
            userId: _trainerProfile!.userId,
            bio: _trainerProfile!.bio,
            specialization: _trainerProfile!.specialization,
            experienceYears: _trainerProfile!.experienceYears,
            certificates: _trainerProfile!.certificates,
            acceptsPrivateClients: value,
            createdAt: _trainerProfile!.createdAt,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : l10n.errorGeneric(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _savingAcceptsPrivateClients = false);
    }
  }

  Widget _buildSettingsSection(AppLocalizations l10n) {
    final profileVisible = _profileVisibleOverride ?? _user.profileVisible;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(l10n.settingsLocation),
            subtitle: Text(
              _locationPermissionGranted
                  ? l10n.settingsLocationAllowed
                  : l10n.settingsLocationDenied,
            ),
            trailing: Icon(
              _locationPermissionGranted ? Icons.check_circle : Icons.cancel,
              color: _locationPermissionGranted ? Colors.green : Colors.red,
            ),
            onTap: () => Geolocator.openAppSettings(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: Text(l10n.settingsVisibility),
            subtitle: Text(
              profileVisible ? l10n.settingsVisible : l10n.settingsHidden,
            ),
            trailing: Switch(
              value: profileVisible,
              onChanged: _savingProfileVisible
                  ? null
                  : (value) => _onProfileVisibilityChanged(value, l10n),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              l10n.settingsLogout,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _onLogout(l10n),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              l10n.settingsDeleteAccount,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _onDeleteAccount(l10n),
          ),
        ],
      ),
    );
  }

  Future<void> _onProfileVisibilityChanged(bool value, AppLocalizations l10n) async {
    final prev = _profileVisibleOverride ?? _user.profileVisible;
    try {
      setState(() {
        _profileVisibleOverride = value;
        _savingProfileVisible = true;
      });
      await ServiceLocator.usersService.updateProfile(profileVisible: value);
      if (mounted) setState(() => _profileVisibleOverride = null);
    } catch (e) {
      if (mounted) {
        setState(() => _profileVisibleOverride = prev);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : l10n.errorGeneric(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProfileVisible = false);
    }
  }

  Future<void> _onLogout(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await AuthService.instance.signOut();
    ServiceLocator.updateAuthToken(null);
    authRefreshNotifier.refresh();
    if (mounted) context.go('/login');
  }

  Future<void> _onDeleteAccount(AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteAccountConfirmButton),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ServiceLocator.usersService.deleteAccount();
      if (!mounted) return;
      await AuthService.instance.signOut();
      ServiceLocator.updateAuthToken(null);
      authRefreshNotifier.refresh();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : l10n.errorGeneric(e.toString()),
            ),
          ),
        );
      }
    }
  }
}
