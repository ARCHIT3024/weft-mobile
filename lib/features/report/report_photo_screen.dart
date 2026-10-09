import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/feature_placeholder.dart';
import '../../routing/routes.dart';

/// Report flow step 1 of 3 — photo (`/report`) — OWNER: F-REPORT.
/// Opened by the Report FAB on the home shell.
///
// TODO(task 2.11/2.12): open the camera immediately (image_picker), preview
//   with retake; store paths via reportDraftProvider.setPhotos(...).
// TODO(task 2.13): compress (flutter_image_compress) before storing.
// Next step: context.push(Routes.reportCategory).
class ReportPhotoScreen extends StatelessWidget {
  const ReportPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report an Issue')),
      body: FeaturePlaceholder(
        title: 'Step 1 of 3 — Take a photo',
        task: 'task 2.12',
        icon: Icons.photo_camera_outlined,
        action: FilledButton(
          onPressed: () => context.push(Routes.reportCategory),
          child: const Text('Next'),
        ),
      ),
    );
  }
}
