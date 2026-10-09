import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants.dart';

/// Map tab — OWNER: F-MAP.
///
// TODO(task 2.21): centre on GPS location on first load (geolocator).
// TODO(task 2.22): markers from issueRepositoryProvider.nearbyIssues(...)
//   (radius 2 km), coloured with `IssueCategory.visual.color`.
// TODO(task 2.23): marker clustering (flutter_map_marker_cluster).
// TODO(task 2.24): tap marker → showIssuePreviewSheet (widgets/issue_preview_sheet.dart).
// TODO(task 2.27): category filter bottom sheet.
//
// Currently the Phase 0 (task 0.17) OSM map, unchanged.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weft')),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(
            AppConstants.defaultLat,
            AppConstants.defaultLng,
          ),
          initialZoom: AppConstants.defaultZoom,
        ),
        children: [
          TileLayer(
            urlTemplate: AppConstants.osmTileUrl,
            userAgentPackageName: AppConstants.osmUserAgentPackageName,
            maxZoom: 19,
          ),
          const RichAttributionWidget(
            attributions: [TextSourceAttribution(AppConstants.osmAttribution)],
          ),
        ],
      ),
    );
  }
}
