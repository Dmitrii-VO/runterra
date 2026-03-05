import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/trainer_assignment_model.dart';

class ClubRosterScreen extends StatefulWidget {
  final String clubId;

  const ClubRosterScreen({super.key, required this.clubId});

  @override
  State<ClubRosterScreen> createState() => _ClubRosterScreenState();
}

class _ClubRosterScreenState extends State<ClubRosterScreen> {
  TrainerAssignmentsModel? _data;
  bool _loading = true;

  int _compareNames(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  List<MemberRef> _sortedMembers(Iterable<MemberRef> members) {
    final list = members.toList();
    list.sort((a, b) => _compareNames(a.displayName, b.displayName));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ServiceLocator.clubsService
          .getTrainerAssignments(widget.clubId);
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  bool get _isLeader => _data?.currentUserRole == 'leader';

  Future<void> _showMemberActions(
      BuildContext context, MemberRef member) async {
    final l10n = AppLocalizations.of(context)!;
    final data = _data!;

    // Determine current state for this member
    String? currentTrainerId;
    String? currentTrainerName;
    final List<({String groupId, String groupName})> currentGroups = [];

    for (final trainer in data.trainers) {
      for (final client in trainer.personalClients) {
        if (client.userId == member.userId) {
          currentTrainerId = trainer.trainerId;
          currentTrainerName = trainer.trainerName;
        }
      }
      for (final group in trainer.groups) {
        for (final gm in group.members) {
          if (gm.userId == member.userId) {
            currentGroups.add((groupId: group.groupId, groupName: group.groupName));
          }
        }
      }
    }

    final actions = <Widget>[];

    // Assign / change personal trainer
    actions.add(ListTile(
      leading: const Icon(Icons.person_add_outlined),
      title: Text(l10n.rosterAssignTrainer),
      onTap: () async {
        Navigator.pop(context);
        await _pickAndAssignTrainer(member);
      },
    ));

    // Remove personal trainer (if assigned)
    if (currentTrainerId != null) {
      actions.add(ListTile(
        leading: const Icon(Icons.person_remove_outlined),
        title: Text(
            '${l10n.rosterRemoveTrainer}: $currentTrainerName'),
        onTap: () async {
          Navigator.pop(context);
          await _removeTrainer(member);
        },
      ));
    }

    // Add to group
    actions.add(ListTile(
      leading: const Icon(Icons.group_add_outlined),
      title: Text(l10n.rosterAddToGroup),
      onTap: () async {
        Navigator.pop(context);
        await _pickAndAssignGroup(member, currentGroups.map((g) => g.groupId).toSet());
      },
    ));

    // Remove from each current group
    for (final g in currentGroups) {
      actions.add(ListTile(
        leading: const Icon(Icons.group_remove_outlined),
        title: Text('${l10n.rosterRemoveFromGroup}: ${g.groupName}'),
        onTap: () async {
          Navigator.pop(context);
          await _removeFromGroup(member, g.groupId);
        },
      ));
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                member.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ...actions,
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndAssignTrainer(MemberRef member) async {
    final l10n = AppLocalizations.of(context)!;
    final trainers = _data!.trainers;
    if (trainers.isEmpty) return;

    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.rosterSelectTrainer),
        children: trainers
            .map((t) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, t.trainerId),
                  child: Text(t.trainerName),
                ))
            .toList(),
      ),
    );
    if (picked == null || !mounted) return;

    try {
      await ServiceLocator.clubsService
          .assignTrainer(widget.clubId, member.userId, picked);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.rosterAssignmentUpdated)));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _removeTrainer(MemberRef member) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ServiceLocator.clubsService
          .removeTrainer(widget.clubId, member.userId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.rosterAssignmentUpdated)));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _pickAndAssignGroup(
      MemberRef member, Set<String> alreadyInGroups) async {
    final l10n = AppLocalizations.of(context)!;

    // Collect all groups from all trainers
    final allGroups = <({String groupId, String groupName})>[];
    for (final trainer in _data!.trainers) {
      for (final group in trainer.groups) {
        if (!alreadyInGroups.contains(group.groupId)) {
          allGroups.add((groupId: group.groupId, groupName: group.groupName));
        }
      }
    }

    if (allGroups.isEmpty) return;

    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.rosterSelectGroup),
        children: allGroups
            .map((g) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, g.groupId),
                  child: Text(g.groupName),
                ))
            .toList(),
      ),
    );
    if (picked == null || !mounted) return;

    try {
      await ServiceLocator.clubsService
          .assignGroup(widget.clubId, member.userId, picked);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.rosterAssignmentUpdated)));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _removeFromGroup(MemberRef member, String groupId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ServiceLocator.clubsService
          .removeFromGroup(widget.clubId, member.userId, groupId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.rosterAssignmentUpdated)));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _createGroupFromRoster() async {
    final data = _data;
    if (data == null || data.trainers.isEmpty || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final trainers = [...data.trainers]
      ..sort((a, b) => _compareNames(a.trainerName, b.trainerName));

    final pickedTrainerId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.rosterSelectTrainer),
        children: trainers
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, t.trainerId),
                child: Text(t.trainerName),
              ),
            )
            .toList(),
      ),
    );
    if (pickedTrainerId == null || !mounted) return;

    final pickedTrainer = trainers.firstWhere((t) => t.trainerId == pickedTrainerId);
    final result = await context.push<bool>(
      '/trainer/groups/create?clubId=${Uri.encodeComponent(widget.clubId)}'
      '&clubName=${Uri.encodeComponent(l10n.rosterTitle)}'
      '&trainerId=${Uri.encodeComponent(pickedTrainerId)}'
      '&trainerName=${Uri.encodeComponent(pickedTrainer.trainerName)}',
    );
    if (result == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rosterTitle),
        actions: [
          if (_isLeader)
            IconButton(
              onPressed: _createGroupFromRoster,
              icon: const Icon(Icons.group_add),
              tooltip: l10n.trainerCreateGroup,
            ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retry,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(child: Text(l10n.noData))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _buildList(l10n),
                ),
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    final data = _data!;
    final items = <Widget>[];

    final unassignedMembers = _sortedMembers(data.unassigned);
    if (unassignedMembers.isNotEmpty) {
      items.add(
        _SectionHeader(
          title: '${l10n.rosterNoTrainer} (${unassignedMembers.length})',
        ),
      );
      for (final m in unassignedMembers) {
        items.add(_MemberTile(
          member: m,
          onTap: _isLeader
              ? () => _showMemberActions(context, m)
              : null,
        ));
      }
    }

    final trainers = [...data.trainers]
      ..sort((a, b) => _compareNames(a.trainerName, b.trainerName));

    // Trainer sections
    for (final trainer in trainers) {
      final personalClients = _sortedMembers(trainer.personalClients);
      final groups = [...trainer.groups]
        ..sort((a, b) => _compareNames(a.groupName, b.groupName));

      final uniqueAssignedIds = <String>{
        ...personalClients.map((m) => m.userId),
      };
      for (final group in groups) {
        uniqueAssignedIds.addAll(group.members.map((m) => m.userId));
      }

      items.add(
        _SectionHeader(
          title: '${trainer.trainerName} (${uniqueAssignedIds.length})',
        ),
      );

      if (personalClients.isEmpty && groups.isEmpty) {
        items.add(_InfoRow(text: l10n.noData));
        continue;
      }

      for (final client in personalClients) {
        items.add(_MemberTile(
          member: client,
          subtitle: l10n.rosterPersonalClient,
          subtitleColor: Colors.purple,
          onTap: _isLeader
              ? () => _showMemberActions(context, client)
              : null,
        ));
      }

      for (final group in groups) {
        final groupMembers = _sortedMembers(group.members);
        items.add(
          _GroupSubHeader(name: '${group.groupName} (${groupMembers.length})'),
        );
        for (final gm in groupMembers) {
          items.add(_MemberTile(
            member: gm,
            onTap: _isLeader
                ? () => _showMemberActions(context, gm)
                : null,
          ));
        }
      }
    }

    if (items.isEmpty) {
      return Center(child: Text(l10n.noData));
    }

    return ListView(children: items);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _GroupSubHeader extends StatelessWidget {
  final String name;
  const _GroupSubHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 8, bottom: 2),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String text;
  const _InfoRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 6, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final MemberRef member;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback? onTap;

  const _MemberTile({
    required this.member,
    this.subtitle,
    this.subtitleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          member.displayName.isNotEmpty
              ? member.displayName[0].toUpperCase()
              : '?',
        ),
      ),
      title: Text(member.displayName),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: subtitleColor ?? Theme.of(context).colorScheme.secondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: onTap != null
          ? const Icon(Icons.more_vert, size: 18)
          : null,
      onTap: onTap,
    );
  }
}
