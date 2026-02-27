import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_member_model.dart';

class CreateTrainerGroupScreen extends StatefulWidget {
  final String clubId;
  final String clubName;

  const CreateTrainerGroupScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<CreateTrainerGroupScreen> createState() => _CreateTrainerGroupScreenState();
}

class _CreateTrainerGroupScreenState extends State<CreateTrainerGroupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  List<ClubMemberModel>? _members;
  bool _isLoadingMembers = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _error = null;
    });

    try {
      final members = await ServiceLocator.clubsService.getClubMembers(widget.clubId);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingMembers = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_selectedMemberIds.isEmpty) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ServiceLocator.trainerService.createGroup(
        clubId: widget.clubId,
        name: name,
        memberIds: _selectedMemberIds.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.trainerGroupCreated)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainerCreateGroup),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: (_nameController.text.trim().isNotEmpty && _selectedMemberIds.isNotEmpty)
                  ? _save
                  : null,
              child: Text(l10n.editProfileSave),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.trainerGroupName,
                hintText: l10n.trainerGroupNameHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  l10n.trainerSelectMembers,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${_selectedMemberIds.length}',
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.primaryColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingMembers
                ? const Center(child: CircularProgressIndicator())
                : _members == null || _members!.isEmpty
                    ? Center(child: Text(l10n.noData))
                    : ListView.builder(
                        itemCount: _members!.length,
                        itemBuilder: (context, index) {
                          final member = _members![index];
                          final isSelected = _selectedMemberIds.contains(member.userId);
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(member.displayName.isNotEmpty ? member.displayName[0] : '?'),
                            ),
                            title: Text(member.displayName),
                            subtitle: Text(member.role),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : const Icon(Icons.add_circle_outline),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedMemberIds.remove(member.userId);
                                } else {
                                  _selectedMemberIds.add(member.userId);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
