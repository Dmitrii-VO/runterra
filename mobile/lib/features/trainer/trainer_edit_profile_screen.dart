import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/trainer_profile.dart';
import '../../shared/api/users_service.dart' show ApiException;

/// Screen to create or edit trainer profile
class TrainerEditProfileScreen extends StatefulWidget {
  final TrainerProfile? existingProfile;

  const TrainerEditProfileScreen({super.key, this.existingProfile});

  @override
  State<TrainerEditProfileScreen> createState() =>
      _TrainerEditProfileScreenState();
}

class _TrainerEditProfileScreenState extends State<TrainerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  final List<String> _selectedSpecs = [];
  final List<_CertificateEntry> _certificates = [];
  bool _saving = false;
  bool _loading = false;
  bool _acceptsPrivateClients = false;
  TrainerProfile? _loadedProfile;

  static const _allSpecs = [
    'MARATHON',
    'SPRINT',
    'TRAIL',
    'RECOVERY',
    'GENERAL'
  ];

  @override
  void initState() {
    super.initState();
    _loadedProfile = widget.existingProfile;
    _bioController = TextEditingController();
    _experienceController = TextEditingController();
    
    if (_loadedProfile != null) {
      _initFromProfile(_loadedProfile!);
    } else {
      _loadInitialData();
    }
  }

  void _initFromProfile(TrainerProfile p) {
    _bioController.text = p.bio ?? '';
    _experienceController.text = p.experienceYears.toString();
    _selectedSpecs.clear();
    _selectedSpecs.addAll(p.specialization);
    _acceptsPrivateClients = p.acceptsPrivateClients;
    
    _certificates.clear();
    for (final c in p.certificates) {
      _certificates.add(_CertificateEntry(
        nameController: TextEditingController(text: c.name),
        dateController: TextEditingController(text: c.date ?? ''),
        orgController: TextEditingController(text: c.organization ?? ''),
      ));
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final p = await ServiceLocator.trainerService.getMyProfile();
      if (p != null && mounted) {
        setState(() {
          _loadedProfile = p;
          _initFromProfile(p);
        });
      } else if (mounted) {
        // Just set default values for creation
        _experienceController.text = '0';
      }
    } catch (_) {
      if (mounted) _experienceController.text = '0';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _experienceController.dispose();
    for (final c in _certificates) {
      c.nameController.dispose();
      c.dateController.dispose();
      c.orgController.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecs.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.trainerSpecializationRequired)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final certs = _certificates
          .where((c) => c.nameController.text.trim().isNotEmpty)
          .map((c) => <String, dynamic>{
                'name': c.nameController.text.trim(),
                if (c.dateController.text.trim().isNotEmpty)
                  'date': c.dateController.text.trim(),
                if (c.orgController.text.trim().isNotEmpty)
                  'organization': c.orgController.text.trim(),
              })
          .toList();

      final data = <String, dynamic>{
        'bio': _bioController.text.trim(),
        'specialization': _selectedSpecs,
        'experienceYears': int.tryParse(_experienceController.text) ?? 0,
        'certificates': certs,
        'acceptsPrivateClients': _acceptsPrivateClients,
      };

      if (_loadedProfile != null) {
        await ServiceLocator.trainerService.updateProfile(data);
      } else {
        await ServiceLocator.trainerService.createProfile(
          bio: data['bio'] as String?,
          specialization: List<String>.from(data['specialization'] as List),
          experienceYears: data['experienceYears'] as int,
          certificates:
              List<Map<String, dynamic>>.from(data['certificates'] as List),
          acceptsPrivateClients: _acceptsPrivateClients,
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.trainerProfileSaved)),
        );
        Navigator.of(context).pop(true);
      }
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
    final isEdit = (_loadedProfile ?? widget.existingProfile) != null;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? l10n.trainerEditProfile : l10n.trainerProfile),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.trainerEditProfile : l10n.trainerProfile),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bio
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(
                labelText: l10n.trainerBio,
                hintText: l10n.trainerBioHint,
              ),
              maxLines: 4,
              maxLength: 2000,
            ),
            const SizedBox(height: 8),

            // Accept private clients toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.trainerAcceptsClients),
              subtitle: Text(l10n.trainerAcceptsClientsHint,
                  style: Theme.of(context).textTheme.bodySmall),
              value: _acceptsPrivateClients,
              onChanged: (v) => setState(() => _acceptsPrivateClients = v),
            ),
            const SizedBox(height: 8),

            // Specialization chips
            Text(l10n.trainerSpecialization,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _allSpecs
                  .map((s) => FilterChip(
                        label: Text(_localizeSpec(l10n, s)),
                        selected: _selectedSpecs.contains(s),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSpecs.add(s);
                            } else {
                              _selectedSpecs.remove(s);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Experience years
            TextFormField(
              controller: _experienceController,
              decoration: InputDecoration(labelText: l10n.trainerExperience),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 0 || n > 50) {
                  return l10n.trainerExperienceRange;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Certificates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.trainerCertificates,
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: l10n.trainerAddCertificate,
                  onPressed: () {
                    setState(() {
                      _certificates.add(_CertificateEntry(
                        nameController: TextEditingController(),
                        dateController: TextEditingController(),
                        orgController: TextEditingController(),
                      ));
                    });
                  },
                ),
              ],
            ),
            ..._certificates.asMap().entries.map((entry) {
              final idx = entry.key;
              final cert = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cert.nameController,
                              decoration: InputDecoration(
                                  labelText: l10n.trainerCertificateName),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                _certificates.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cert.dateController,
                              decoration: InputDecoration(
                                  labelText: l10n.trainerCertificateDate),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: cert.orgController,
                              decoration: InputDecoration(
                                  labelText: l10n.trainerCertificateOrg),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.editProfileSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localizeSpec(AppLocalizations l10n, String spec) {
    switch (spec) {
      case 'MARATHON':
        return l10n.specMarathon;
      case 'SPRINT':
        return l10n.specSprint;
      case 'TRAIL':
        return l10n.specTrail;
      case 'RECOVERY':
        return l10n.specRecovery;
      case 'GENERAL':
        return l10n.specGeneral;
      default:
        return spec;
    }
  }
}

class _CertificateEntry {
  final TextEditingController nameController;
  final TextEditingController dateController;
  final TextEditingController orgController;

  _CertificateEntry({
    required this.nameController,
    required this.dateController,
    required this.orgController,
  });
}
