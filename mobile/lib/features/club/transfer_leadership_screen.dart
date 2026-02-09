import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_member_model.dart';

/// Screen for transferring club leadership to another member.
class TransferLeadershipScreen extends StatefulWidget {
  final String clubId;

  const TransferLeadershipScreen({super.key, required this.clubId});

  @override
  State<TransferLeadershipScreen> createState() => _TransferLeadershipScreenState();
}

class _TransferLeadershipScreenState extends State<TransferLeadershipScreen> {
  late Future<List<ClubMemberModel>> _membersFuture;
  bool _transferring = false;

  @override
  void initState() {
    super.initState();
    _membersFuture = ServiceLocator.clubsService.getClubMembers(widget.clubId);
  }

  Future<void> _transferTo(ClubMemberModel member) async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.transferLeadership),
        content: Text('${member.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.transferLeadership),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _transferring = true);
    try {
      await ServiceLocator.clubsService.updateMemberRole(
        widget.clubId,
        member.userId,
        'leader',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.transferSuccess)),
      );
      // Go back to club details
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectNewLeader),
      ),
      body: FutureBuilder<List<ClubMemberModel>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(snapshot.error.toString()),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _membersFuture = ServiceLocator.clubsService.getClubMembers(widget.clubId);
                        });
                      },
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final members = (snapshot.data ?? [])
              .where((m) => m.role != 'leader')
              .toList();

          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.clubMembersEmpty),
              ),
            );
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(member.displayName),
                subtitle: Text(member.role),
                trailing: _transferring
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward),
                onTap: _transferring ? null : () => _transferTo(member),
              );
            },
          );
        },
      ),
    );
  }
}
