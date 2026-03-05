import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_member_model.dart';
import '../../shared/models/trainer_group_model.dart';

class CreateTrainerGroupScreen extends StatefulWidget {
  final String clubId;
  final String clubName;
  final TrainerGroupModel? existingGroup;
  final String? forcedTrainerId;
  final String? forcedTrainerName;

  const CreateTrainerGroupScreen({
    super.key,
    required this.clubId,
    required this.clubName,
    this.existingGroup,
    this.forcedTrainerId,
    this.forcedTrainerName,
  });

  @override
  State<CreateTrainerGroupScreen> createState() => _CreateTrainerGroupScreenState();
}

class _CreateTrainerGroupScreenState extends State<CreateTrainerGroupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  List<ClubMemberModel>? _members;
  String? _currentUserId;
  bool _isLoadingMembers = true;
  bool _isSaving = false;
  String? _error;
  bool get _isCreateMode => widget.existingGroup == null;

  @override
  void initState() {
    super.initState();
    if (widget.existingGroup != null) {
      _nameController.text = widget.existingGroup!.name;
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_isCreateMode) {
      setState(() {
        _isLoadingMembers = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoadingMembers = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ServiceLocator.usersService.getProfile(),
        ServiceLocator.clubsService.getClubMembers(widget.clubId),
        if (widget.existingGroup != null)
          ServiceLocator.trainerService.getGroupMemberIds(widget.existingGroup!.id),
      ]);

      final profile = results[0] as dynamic; // ProfileModel
      final members = results[1] as List<ClubMemberModel>;
      
      if (mounted) {
        setState(() {
          _currentUserId = profile.user.id;
          _members = members;
          
          if (widget.existingGroup != null) {
            final existingMemberIds = results[2] as List<String>;
            _selectedMemberIds.addAll(existingMemberIds);
            if (_currentUserId != null) {
              _selectedMemberIds.remove(_currentUserId);
            }
          }
          
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

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      if (widget.existingGroup != null) {
        await ServiceLocator.trainerService.updateGroup(
          widget.existingGroup!.id,
          name: name,
          memberIds: _selectedMemberIds.toList(),
        );
      } else {
        await ServiceLocator.trainerService.createGroup(
          clubId: widget.clubId,
          name: name,
          trainerId: widget.forcedTrainerId,
        );
      }
      
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

    // Filter members to exclude the group's trainer
    final excludedTrainerId =
        widget.existingGroup?.trainerId ?? widget.forcedTrainerId ?? _currentUserId;
    final filteredMembers =
        _members?.where((m) => m.userId != excludedTrainerId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingGroup != null ? l10n.editProfileEditAction : l10n.trainerCreateGroup),
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
              onPressed: (_nameController.text.trim().isNotEmpty &&
                      (_isCreateMode || _selectedMemberIds.isNotEmpty))
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.existingGroup == null && widget.forcedTrainerName != null) ...[
                  Text(
                    '${l10n.roleTrainer}: ${widget.forcedTrainerName!}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.trainerGroupName,
                    hintText: l10n.trainerGroupNameHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          if (!_isCreateMode)
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
          if (!_isCreateMode)
            Expanded(
              child: _isLoadingMembers
                  ? const Center(child: CircularProgressIndicator())
                  : filteredMembers == null || filteredMembers.isEmpty
                      ? Center(child: Text(l10n.noData))
                      : ListView.builder(
                          itemCount: filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = filteredMembers[index];
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
