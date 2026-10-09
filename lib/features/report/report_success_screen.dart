import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/feature_placeholder.dart';
import '../../data/models/issue.dart';
import '../../routing/routes.dart';

/// Report submitted (`/report/success`, `extra: CreateIssueResponse`) —
/// OWNER: F-REPORT.
///
// TODO(task 2.18): issue number card, status badge, confetti, "Track This
//   Issue" → context.go(Routes.issueDetail(result.issueId)), "Back to Map".
class ReportSuccessScreen extends StatelessWidget {
  const ReportSuccessScreen({super.key, this.result});

  /// Null if the route was opened without `extra` (e.g. state restoration).
  final CreateIssueResponse? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FeaturePlaceholder(
          title: 'Report submitted',
          task: 'task 2.18',
          icon: Icons.check_circle_outline,
          action: FilledButton(
            onPressed: () => context.go(Routes.map),
            child: const Text('Back to Map'),
          ),
        ),
      ),
    );
  }
}
