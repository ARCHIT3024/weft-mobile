import 'package:flutter/material.dart';

import '../../core/widgets/feature_placeholder.dart';

/// Alerts tab — OWNER: notifications agent (tasks 2.29–2.31).
///
// TODO(task 2.30): notificationRepositoryProvider.list(), read/unread state,
//   markRead / markAllRead, tap → context.push(Routes.issueDetail(issueId)).
//   Anonymous users have no notifications — show a sign-in prompt.
// TODO(task 2.29/2.31): FCM via firebase_messaging, guarded by
//   FirebaseBootstrap.isAvailable; register the token with
//   userRepositoryProvider.updateMe(fcmToken: ...).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: const FeaturePlaceholder(
        title: 'Notifications',
        task: 'task 2.30',
        icon: Icons.notifications_outlined,
      ),
    );
  }
}
