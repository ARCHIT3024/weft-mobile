import 'package:flutter/material.dart';

import 'state_views.dart';

/// Body for a route whose screen has not been built yet. Remove once the real
/// screen lands.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.task,
    this.icon = Icons.construction_outlined,
    this.action,
  });

  final String title;

  /// e.g. 'task 2.28'.
  final String task;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      icon: icon,
      title: title,
      message: 'Coming soon ($task).',
      action: action,
    );
  }
}
