import 'package:flutter/material.dart';

import '../../core/widgets/feature_placeholder.dart';

/// "My Reports" tab — OWNER: F-MAP.
///
// TODO(task 2.28): userRepositoryProvider.getMyReports(...) list with status
//   badges, pull-to-refresh, filter chips (All / Reported / In Progress /
//   Resolved). Anonymous users (authControllerProvider.isAnonymous) cannot
//   call this endpoint — show a "Sign in to track your reports" prompt.
//   Phase 2 exit criterion: refreshes after a submission without manual
//   refresh (e.g. invalidate your provider from the report success path).
//   Add WeftSpacing.fabClearance bottom padding to the list.
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: const FeaturePlaceholder(
        title: 'My Reports',
        task: 'task 2.28',
        icon: Icons.list_alt,
      ),
    );
  }
}
