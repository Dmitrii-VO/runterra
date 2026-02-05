import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/profile_model.dart';
import '../city/city_picker_dialog.dart';

/// Edit profile screen — form to change name and avatar URL.
/// City is edited from the main profile screen.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final ProfileUserData user;

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

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName ?? widget.user.name);
    _lastNameController = TextEditingController(text: widget.user.lastName ?? '');
    _countryController = TextEditingController(text: widget.user.country ?? '');
    _avatarUrlController = TextEditingController(text: widget.user.avatarUrl ?? '');
    _birthDate = widget.user.birthDate;
    _gender = widget.user.gender;
    _cityId = widget.user.cityId;
    _cityName = widget.user.cityName;
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
              value: _gender,
              decoration: InputDecoration(
                labelText: l10n.editProfileGender,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'male', child: Text(l10n.genderMale)),
                DropdownMenuItem(value: 'female', child: Text(l10n.genderFemale)),
                DropdownMenuItem(value: 'other', child: Text(l10n.genderOther)),
                DropdownMenuItem(value: 'unknown', child: Text(l10n.genderUnknown)),
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
          ],
        ),
      ),
    );
  }
}
