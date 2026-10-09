import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/api_error.dart';

/// Maps auth API errors to citizen-friendly copy.
String authErrorMessage(Object error) {
  if (error is! ApiException) return 'Something went wrong. Please try again.';
  if (error.isNetwork) return error.message;
  if (error.isRateLimited) {
    final wait = error.retryAfterSeconds;
    return wait == null
        ? 'Too many attempts. Please wait a minute and try again.'
        : 'Too many attempts. Please try again in $wait seconds.';
  }
  switch (error.code) {
    case ApiErrorCodes.emailAlreadyRegistered:
      return 'An account with this email already exists. Sign in instead.';
    case ApiErrorCodes.phoneAlreadyRegistered:
      return 'An account with this phone number already exists.';
  }
  if (error.isUnauthorized) return 'Incorrect email or password.';
  return error.message;
}

/// Inline error/info banner, announced to screen readers when it appears.
class FormBanner extends StatelessWidget {
  const FormBanner.error(this.message, {super.key}) : isError = true;
  const FormBanner.info(this.message, {super.key}) : isError = false;

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final fg = isError ? const Color(0xFF991B1B) : WeftColors.navy;
    final bg = isError ? const Color(0xFFFEE2E2) : WeftColors.tealBackground;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(WeftSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(WeftSpacing.radius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: fg,
              size: 20,
            ),
            const SizedBox(width: WeftSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen heading used by login/register.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: WeftColors.navy,
            ),
          ),
        ),
        const SizedBox(height: WeftSpacing.xs),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 15, color: WeftColors.textSecondary),
        ),
      ],
    );
  }
}
