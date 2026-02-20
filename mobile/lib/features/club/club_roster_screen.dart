import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_member_model.dart';

class ClubRosterScreen extends StatefulWidget {
  final String clubId;

  const ClubRosterScreen({super.key, required this.clubId});

  @override
  State<ClubRosterScreen> createState() => _ClubRosterScreenState();
}

class _ClubRosterScreenState extends State<ClubRosterScreen> {
  List<ClubMemberModel>? _members;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _loading = true);
    try {
      final members = await ServiceLocator.clubsService.getClubMembers(widget.clubId);
      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rosterTitle),
        actions: [
          IconButton(
            onPressed: _loadMembers, 
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retry,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members == null || _members!.isEmpty
              ? Center(child: Text(l10n.noData))
              : RefreshIndicator(
                  onRefresh: _loadMembers,
                  child: ListView.builder(
                    itemCount: _members!.length,
                    itemBuilder: (context, index) {
                      final member = _members![index];
                      final isPersonal = member.planType == 'personal';

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(member.displayName.isNotEmpty
                              ? member.displayName[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(member.displayName),
                        subtitle: Text(_roleLabel(l10n, member.role)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPersonal ? Colors.purple.shade100 : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPersonal ? Colors.purple.shade400 : Colors.blue.shade400,
                            ),
                          ),
                          child: Text(
                            isPersonal ? l10n.planTypePersonal : l10n.planTypeClub,
                            style: TextStyle(
                              fontSize: 12,
                              color: isPersonal ? Colors.purple.shade900 : Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () async {
                          final changed = await context.push<bool>(
                            '/club/${widget.clubId}/members/${member.userId}/plan',
                            extra: member,
                          );
                          // If we return from personal plan screen, always reload to get updated planType
                          if (changed == true || mounted) {
                            _loadMembers();
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }

  String _roleLabel(AppLocalizations l10n, String role) {
    switch (role) {
      case 'leader':
        return l10n.roleLeader;
      case 'trainer':
        return l10n.roleTrainer;
      default:
        return l10n.roleMember;
    }
  }
}
