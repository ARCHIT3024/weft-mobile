import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/issue_visuals.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/issue.dart';
import '../../../routing/routes.dart';

/// Marker-tap bottom sheet — OWNER: F-MAP.
///
// TODO(task 2.24): photo thumbnail (needs IssueDetail or a thumbnail field —
// IssueSummary has no images), category badge, upvote count, status badge,
// "View Details" button. Minimal version below.
Future<void> showIssuePreviewSheet(BuildContext context, IssueSummary issue) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => IssuePreviewSheet(issue: issue),
  );
}

class IssuePreviewSheet extends StatelessWidget {
  const IssuePreviewSheet({super.key, required this.issue});

  final IssueSummary issue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CategoryIcon(issue.category, excludeFromSemantics: true),
              title: Text(issue.category.label),
              subtitle: Text(issue.issueNumber),
              trailing: StatusBadge(issue.status, compact: true),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(Routes.issueDetail(issue.id));
              },
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }
}
