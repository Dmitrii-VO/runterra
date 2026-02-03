import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/profile_model.dart';

/// Edit profile screen — form to change name and avatar URL.
/// City is edited from the main profile screen.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final ProfileUserData user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _avatarUrlController;
  String? _validationError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _avatarUrlController = TextEditingController(text: widget.user.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
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
      final avatarUrl = _avatarUrlController.text.trim();
      await ServiceLocator.usersService.updateProfile(
        name: name,
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
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.editProfileName,
                errorText: _validationError,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !_saving,
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
