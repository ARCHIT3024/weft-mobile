import 'package:flutter/material.dart';

import '../../core/widgets/feature_placeholder.dart';

/// Report flow step 3 of 3 — location & description (`/report/details`) —
/// OWNER: F-REPORT.
///
// TODO(task 2.15/2.16): map pin at GPS (geolocator), manual adjustment,
//   optional description (≤ AppConstants.maxDescriptionLength).
// TODO(task 2.17): captcha token for anonymous users
//   (authControllerProvider.isAnonymous).
// TODO(task 2.18): submit with
//   issueRepositoryProvider.createIssue(draft.toInput(captchaToken: ...)),
//   then context.go(Routes.reportSuccess, extra: response) and
//   reportDraftProvider.reset().
// TODO(task 2.19/2.20): error handling + offline draft.
class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Location')),
      body: const FeaturePlaceholder(
        title: 'Step 3 of 3 — Location & details',
        task: 'task 2.15',
        icon: Icons.place_outlined,
      ),
    );
  }
}
