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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.map), label: l10n.navMap),
          BottomNavigationBarItem(icon: const Icon(Icons.fitness_center), label: l10n.navRun),
          BottomNavigationBarItem(icon: const Icon(Icons.message), label: l10n.navMessages),
          BottomNavigationBarItem(icon: const Icon(Icons.event), label: l10n.navEvents),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: l10n.navProfile),
        ],
      ),
    );
  }
}
