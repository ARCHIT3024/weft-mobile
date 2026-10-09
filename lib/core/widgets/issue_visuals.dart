/// Presentation metadata for issue categories and statuses — the single place
/// that maps wire enums to labels, icons and colours.
///
/// Accessibility rules enforced here (same as weft-web/src/lib/issueMeta.ts):
/// * Status is never colour alone: every status has a distinct icon SHAPE and
///   a text label (WCAG 1.4.1).
/// * Badge text/background pairs are ≥ 5:1 contrast (spec colours from
///   03_weft_uiux.jsx `StatusBadge`).
/// Category colours match weft-web `--color-cat-*` so a pothole is the same
/// colour on the dashboard and the phone.
library;

import 'package:flutter/material.dart';

import '../../data/models/enums.dart';

@immutable
class CategoryVisual {
  const CategoryVisual({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
  });

  final String label;

  /// Compact label for the 4-column category grid.
  final String shortLabel;
  final IconData icon;

  /// Marker/icon colour (use white icons on it, with a white outline).
  final Color color;
}

extension IssueCategoryVisuals on IssueCategory {
  CategoryVisual get visual => switch (this) {
    IssueCategory.pothole => const CategoryVisual(
      label: 'Pothole',
      shortLabel: 'Pothole',
      icon: Icons.edit_road,
      color: Color(0xFFB45309),
    ),
    IssueCategory.garbageAccumulation => const CategoryVisual(
      label: 'Garbage Accumulation',
      shortLabel: 'Garbage',
      icon: Icons.delete_outline,
      color: Color(0xFF65A30D),
    ),
    IssueCategory.waterLogging => const CategoryVisual(
      label: 'Water Logging',
      shortLabel: 'Water',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF0284C7),
    ),
    IssueCategory.brokenStreetLight => const CategoryVisual(
      label: 'Broken Street Light',
      shortLabel: 'Street Light',
      icon: Icons.lightbulb_outline,
      color: Color(0xFFCA8A04),
    ),
    IssueCategory.damagedFootpath => const CategoryVisual(
      label: 'Damaged Footpath',
      shortLabel: 'Footpath',
      icon: Icons.directions_walk,
      color: Color(0xFF7C3AED),
    ),
    IssueCategory.sewageOverflow => const CategoryVisual(
      label: 'Sewage Overflow',
      shortLabel: 'Sewage',
      icon: Icons.plumbing,
      color: Color(0xFFBE123C),
    ),
    IssueCategory.other => const CategoryVisual(
      label: 'Other',
      shortLabel: 'Other',
      icon: Icons.place_outlined,
      color: Color(0xFF64748B),
    ),
  };

  String get label => visual.label;
}

@immutable
class StatusVisual {
  const StatusVisual({
    required this.label,
    required this.description,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color foreground;
  final Color background;
}

extension IssueStatusVisuals on IssueStatus {
  StatusVisual get visual => switch (this) {
    IssueStatus.reported => const StatusVisual(
      label: 'Reported',
      description: 'Submitted, awaiting review',
      icon: Icons.flag_outlined,
      foreground: Color(0xFF1D4ED8),
      background: Color(0xFFDBEAFE),
    ),
    IssueStatus.inProgress => const StatusVisual(
      label: 'In Progress',
      description: 'Accepted and being worked on',
      icon: Icons.autorenew,
      foreground: Color(0xFF92400E),
      background: Color(0xFFFEF3C7),
    ),
    IssueStatus.resolved => const StatusVisual(
      label: 'Resolved',
      description: 'Fixed and closed',
      icon: Icons.check_circle_outline,
      foreground: Color(0xFF065F46),
      background: Color(0xFFD1FAE5),
    ),
    IssueStatus.rejected => const StatusVisual(
      label: 'Rejected',
      description: 'Duplicate, out of scope, or unfounded',
      icon: Icons.cancel_outlined,
      foreground: Color(0xFF991B1B),
      background: Color(0xFFFEE2E2),
    ),
    IssueStatus.unknown => const StatusVisual(
      label: 'Unknown',
      description: 'Status not recognised by this app version',
      icon: Icons.help_outline,
      foreground: Color(0xFF475569),
      background: Color(0xFFF1F5F9),
    ),
  };

  String get label => visual.label;
}
