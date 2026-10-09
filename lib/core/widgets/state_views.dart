/// Loading / error / empty placeholders with consistent layout and a11y.
library;

import 'package:flutter/material.dart';

import '../../data/models/api_error.dart';
import '../theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message ?? 'Loading',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(WeftSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: WeftSpacing.lg),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: WeftColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.icon,
  });

  /// Builds the right copy/icon for an error thrown by a repository.
  factory ErrorView.fromError(Object error, {Key? key, VoidCallback? onRetry}) {
    if (error is ApiException) {
      return ErrorView(
        key: key,
        title: error.isNetwork ? "You're offline" : 'Something went wrong',
        message: error.message,
        icon: error.isNetwork ? Icons.wifi_off : Icons.error_outline,
        onRetry: onRetry,
      );
    }
    return ErrorView(key: key, message: 'Please try again.', onRetry: onRetry);
  }

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _MessageLayout(
      icon: icon ?? Icons.error_outline,
      iconColor: WeftColors.dangerText,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;

  /// Optional CTA, e.g. a button.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _MessageLayout(
      icon: icon,
      iconColor: WeftColors.textMuted,
      title: title,
      message: message,
      action: action,
    );
  }
}

class _MessageLayout extends StatelessWidget {
  const _MessageLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(WeftSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 56, color: iconColor)),
            const SizedBox(height: WeftSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: WeftColors.textPrimary,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: WeftSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: WeftColors.textSecondary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: WeftSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
