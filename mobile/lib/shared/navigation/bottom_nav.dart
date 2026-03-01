import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import 'nav_status_provider.dart';

/// Bottom navigation widget for switching between main screens.
///
/// Uses StatefulShellRoute branches, so each tab preserves its own navigation
/// stack and widget state.
class BottomNav extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNav({
    super.key,
    required this.navigationShell,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  final UserNavStatusNotifier _navStatus = UserNavStatusNotifier();

  @override
  void initState() {
    super.initState();
    // Initial fetch when app starts (if auth'd)
    _navStatus.refresh();
  }

  /// Map each branch index to its corresponding NavType for filtering.
  _NavType _getNavTypeForIndex(int branchIndex) {
    switch (branchIndex) {
      case 0: return _NavType.map;
      case 1: return _NavType.run;
      case 2: return _NavType.messages;
      case 3: return _NavType.events;
      case 4: return _NavType.profile;
      default: return _NavType.map;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _navStatus,
      builder: (context, status, _) {
        final List<_NavItem> allItems = [
          _NavItem(
            type: _NavType.map,
            index: 0,
            icon: const Icon(Icons.map),
            label: AppLocalizations.of(context)!.navMap,
          ),
          _NavItem(
            type: _NavType.run,
            index: 1,
            icon: const Icon(Icons.directions_run),
            label: AppLocalizations.of(context)!.navRun,
          ),
          _NavItem(
            type: _NavType.messages,
            index: 2,
            icon: const Icon(Icons.message),
            label: AppLocalizations.of(context)!.navMessages,
            // Hidden if no clubs AND no trainers
            visible: status.hasClubs || status.hasTrainers,
          ),
          _NavItem(
            type: _NavType.events,
            index: 3,
            icon: const Icon(Icons.event),
            label: AppLocalizations.of(context)!.navEvents,
            // Hidden if no clubs
            visible: status.hasClubs,
          ),
          _NavItem(
            type: _NavType.profile,
            index: 4,
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.navProfile,
          ),
        ];

        // Filter based on visibility
        final visibleItems = allItems.where((i) => i.visible).toList();

        // Find current selected index among visible items
        final currentType = _getNavTypeForIndex(widget.navigationShell.currentIndex);
        int displayIndex = visibleItems.indexWhere((i) => i.type == currentType);
        
        // If current screen is hidden (e.g. after logout or leaving club), 
        // fallback to index 0.
        if (displayIndex == -1) displayIndex = 0;

        return Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: displayIndex,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            onTap: (newDisplayIndex) {
              final targetItem = visibleItems[newDisplayIndex];
              // Map back to branch index for GoRouter
              widget.navigationShell.goBranch(
                targetItem.index,
                initialLocation: targetItem.index == widget.navigationShell.currentIndex,
              );
            },
            items: visibleItems.map((i) => BottomNavigationBarItem(
              icon: i.icon,
              label: i.label,
            )).toList(),
          ),
        );
      },
    );
  }
}

enum _NavType { map, run, messages, events, profile }

class _NavItem {
  final _NavType type;
  final int index; // Real branch index in GoRouter
  final Widget icon;
  final String label;
  final bool visible;

  _NavItem({
    required this.type,
    required this.index,
    required this.icon,
    required this.label,
    this.visible = true,
  });
}

