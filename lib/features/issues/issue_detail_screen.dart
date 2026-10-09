import 'package:flutter/material.dart';

import '../../core/widgets/feature_placeholder.dart';

/// Issue detail (`/issues/:id`) — OWNER: F-MAP.
///
// TODO(task 2.25): load with issueRepositoryProvider.getIssue(issueId); show
//   photos (IssueImage.url), info, status timeline (statusHistory is
//   newest-first; `timelineOldestFirst` for top-down).
// TODO(task 2.26): upvote via upvoteRepositoryProvider; anonymous →
//   "Sign in to upvote" → context.push(Routes.loginFrom('/issues/$issueId')).
class IssueDetailScreen extends StatelessWidget {
  const IssueDetailScreen({super.key, required this.issueId});

  final String issueId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Issue')),
      body: const FeaturePlaceholder(
        title: 'Issue details',
        task: 'task 2.25',
        icon: Icons.article_outlined,
      ),
    );
  }
}
