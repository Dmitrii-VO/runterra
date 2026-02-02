import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

/// Bottom navigation widget for switching between main screens
/// Integrated with GoRouter for navigation
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Widget child;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          // Навигация через GoRouter
          if (index == 0) {
            context.go('/map');
          } else if (index == 1) {
            context.go('/run');
          } else if (index == 2) {
            context.go('/messages');
          } else if (index == 3) {
            context.go('/events');
          } else if (index == 4) {
            context.go('/');
          }
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
