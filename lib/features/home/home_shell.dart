import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/routes.dart';

/// Home shell (task 2.1): bottom navigation with four tabs that keep their
/// state (StatefulShellRoute.indexedStack), plus the "Report Issue" FAB
/// (task 2.11) that opens the report flow owned by F-REPORT.
///
/// Each tab screen owns its own AppBar. Scrollable tab content should add
/// `WeftSpacing.fabClearance` bottom padding so the FAB never hides the last
/// item.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      // Re-tapping the active tab returns it to its root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('report_fab'),
        heroTag: 'report_fab',
        tooltip: 'Report a civic issue',
        onPressed: () => context.push(Routes.report),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Report Issue'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
            tooltip: 'Issues map',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'My Reports',
          ),
          // TODO(task 2.30): unread-count badge (Badge widget) on this icon.
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
            tooltip: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
