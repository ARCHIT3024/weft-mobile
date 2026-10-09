import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/feature_placeholder.dart';
import '../../routing/routes.dart';

/// Report flow step 2 of 3 — category (`/report/category`) — OWNER: F-REPORT.
///
// TODO(task 2.14): grid of the 7 categories (IssueCategory.values with
//   `.visual` for label/icon/colour) → reportDraftProvider.setCategory(...).
//   AI suggestion card: backend AI is cut (D-2), so no suggestion today.
// Next step: context.push(Routes.reportDetails).
class ReportCategoryScreen extends StatelessWidget {
  const ReportCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Category')),
      body: FeaturePlaceholder(
        title: 'Step 2 of 3 — Choose a category',
        task: 'task 2.14',
        icon: Icons.category_outlined,
        action: FilledButton(
          onPressed: () => context.push(Routes.reportDetails),
          child: const Text('Next'),
        ),
      ),
    );
  }
}
