import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../core/theme.dart';

/// Home screen with bottom navigation tabs.
///
/// Tabs:
///   0 — Map (flutter_map with OSM tiles)
///   1 — My Reports (Phase 2)
///   2 — Notifications (Phase 2)
///   3 — Profile (Phase 2)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weft'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              // Phase 2: open filter sheet
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Phase 2: navigate to /report
        },
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Report Issue'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() => _currentTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'My Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
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

  Widget _buildBody() {
    switch (_currentTab) {
      case 0:
        return _MapTab();
      case 1:
        return const _PlaceholderTab(
          icon: Icons.list_alt,
          label: 'My Reports',
          subtitle: 'Your submitted issues — Phase 2 (task 2.28)',
        );
      case 2:
        return const _PlaceholderTab(
          icon: Icons.notifications,
          label: 'Notifications',
          subtitle: 'Status updates — Phase 2 (task 2.30)',
        );
      case 3:
        return const _PlaceholderTab(
          icon: Icons.person,
          label: 'Profile',
          subtitle: 'Trust score & gamification — Phase 2 (task 2.9)',
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Map tab — flutter_map with OSM tiles (task 0.17)
class _MapTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          AppConstants.defaultLat,
          AppConstants.defaultLng,
        ),
        initialZoom: AppConstants.defaultZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: AppConstants.osmTileUrl,
          userAgentPackageName: 'city.weft.weft_mobile',
          maxZoom: 19,
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution(AppConstants.osmAttribution),
          ],
        ),
      ],
    );
  }
}

/// Placeholder tab for Phase 2 features.
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: WeftColors.textMuted),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: WeftColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: WeftColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
