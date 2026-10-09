import 'package:flutter/material.dart';

/// Full-width primary action (filled, accessible teal, ≥ 52 dp tall).
/// While [isLoading] it shows a spinner, ignores taps, and tells screen
/// readers it is busy.
class WeftPrimaryButton extends StatelessWidget {
  const WeftPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : _ButtonContent(label: label, icon: icon);
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
    return Semantics(
      button: true,
      label: isLoading ? '$label, in progress' : null,
      excludeSemantics: isLoading,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}

/// Outlined secondary action.
class WeftSecondaryButton extends StatelessWidget {
  const WeftSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      child: _ButtonContent(label: label, icon: icon),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label, textAlign: TextAlign.center);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}
