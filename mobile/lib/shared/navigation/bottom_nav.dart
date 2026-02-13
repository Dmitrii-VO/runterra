import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

/// Bottom navigation widget for switching between main screens.
///
/// Uses StatefulShellRoute branches, so each tab preserves its own navigation
/// stack and widget state.
class BottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNav({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          // Preserve state per tab (each branch has its own Navigator).
          // If user taps the current tab again, return to the branch root.
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: AppLocalizations.of(context)!.navMap,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.directions_run),
            label: AppLocalizations.of(context)!.navRun,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.message),
            label: AppLocalizations.of(context)!.navMessages,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event),
            label: AppLocalizations.of(context)!.navEvents,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.navProfile,
          ),
        ],
      ),
    );
  }
}

