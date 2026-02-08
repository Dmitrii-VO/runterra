import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_model.dart';

/// Edit club screen - form to change club name and description.
/// Only club leaders can access this screen.
class EditClubScreen extends StatefulWidget {
  const EditClubScreen({super.key, required this.club});

  final ClubModel club;

  @override
  State<EditClubScreen> createState() => _EditClubScreenState();
}

class _EditClubScreenState extends State<EditClubScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _validationError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.club.name);
    _descriptionController = TextEditingController(text: widget.club.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    // Validation: name must be 3-50 characters
    if (name.isEmpty || name.length < 3 || name.length > 50) {
      setState(() {
        _validationError = AppLocalizations.of(context)!.editClubNameError;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _saving = true;
    });

    try {
      final description = _descriptionController.text.trim();
      await ServiceLocator.clubsService.updateClub(
        widget.club.id,
        name: name,
        description: description.isEmpty ? '' : description,
      );

      if (!mounted) return;
      context.pop(true); // Return success
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.editClubError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editClubTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.editClubName,
                errorText: _validationError,
                border: const OutlineInputBorder(),
                helperText: '3-50 ${l10n.editClubNameHelperText}',
              ),
              enabled: !_saving,
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.editClubDescription,
                border: const OutlineInputBorder(),
                helperText: l10n.editClubDescriptionHelperText,
              ),
              maxLines: 5,
              maxLength: 500,
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
                  : Text(l10n.editClubSave),
            ),
          ],
        ),
      ),
    );
  }
}
