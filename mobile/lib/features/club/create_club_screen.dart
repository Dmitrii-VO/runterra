import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/api/users_service.dart' show ApiException;

/// Screen for creating a new club.
/// City is taken from CurrentCityService; user must have a city set.
class CreateClubScreen extends StatefulWidget {
  const CreateClubScreen({super.key});

  @override
  State<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _validationError;
  bool _saving = false;
  bool _cityChecked = false;

  @override
  void initState() {
    super.initState();
    _ensureCity();
  }

  Future<void> _ensureCity() async {
    final svc = ServiceLocator.currentCityService;
    if (!svc.isInitialized) await svc.init();
    if (mounted) setState(() => _cityChecked = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _validationError = AppLocalizations.of(context)!.createClubNameRequired;
      });
      return;
    }
    final cityId = ServiceLocator.currentCityService.currentCityId;
    if (cityId == null || cityId.isEmpty) {
      setState(() {
        _validationError = AppLocalizations.of(context)!.createClubCityRequired;
      });
      return;
    }
    setState(() {
      _validationError = null;
      _saving = true;
    });
    try {
      final description = _descriptionController.text.trim();
      final club = await ServiceLocator.clubsService.createClub(
        name: name,
        description: description.isEmpty ? null : description,
        cityId: cityId,
      );
      if (!mounted) return;
      context.go('/club/${club.id}');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.createClubError(e.message),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.createClubError(e.toString()),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_cityChecked) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.createClubTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final cityId = ServiceLocator.currentCityService.currentCityId;
    final hasCity = cityId != null && cityId.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createClubTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!hasCity)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.createClubCityRequired,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            if (!hasCity) const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.createClubNameHint,
                errorText: _validationError,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              enabled: hasCity && !_saving,
              onChanged: (_) => setState(() => _validationError = null),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.createClubDescriptionHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              enabled: hasCity && !_saving,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (hasCity && !_saving) ? _create : null,
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.createClubSave),
            ),
          ],
        ),
      ),
    );
  }
}
