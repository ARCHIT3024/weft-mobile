import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import 'issue_visuals.dart';

/// Pill showing an issue status: icon (shape cue) + label, spec colours.
/// Announced to screen readers as "Status: In Progress".
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.compact = false});

  final IssueStatus status;

  /// Smaller variant for dense list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final v = status.visual;
    final fontSize = compact ? 11.0 : 12.0;
    return Semantics(
      label: 'Status: ${v.label}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: v.background,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(v.icon, size: fontSize + 2, color: v.foreground),
            const SizedBox(width: 4),
            Text(
              v.label,
              style: TextStyle(
                color: v.foreground,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
