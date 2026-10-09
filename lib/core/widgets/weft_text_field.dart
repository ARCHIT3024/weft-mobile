import 'package:flutter/material.dart';

/// Labelled form field. The label is always a real `labelText` (never a
/// placeholder-only hint), so it is announced by screen readers and stays
/// visible once the user has typed.
class WeftTextField extends StatelessWidget {
  const WeftTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.helperText,
    this.prefixIcon,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    this.onFieldSubmitted,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.fieldKey,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? helperText;
  final IconData? prefixIcon;
  final int? maxLength;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final TextCapitalization textCapitalization;

  /// Key for the inner TextFormField (handy in widget tests).
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      maxLength: maxLength,
      maxLines: maxLines,
      enabled: enabled,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 2,
        errorMaxLines: 3,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}

/// Password field with a show/hide toggle (48 dp, labelled for TalkBack /
/// VoiceOver).
class WeftPasswordField extends StatefulWidget {
  const WeftPasswordField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.helperText,
    this.onFieldSubmitted,
    this.fieldKey,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? helperText;
  final ValueChanged<String>? onFieldSubmitted;
  final Key? fieldKey;

  @override
  State<WeftPasswordField> createState() => _WeftPasswordFieldState();
}

class _WeftPasswordFieldState extends State<WeftPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscured,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onFieldSubmitted,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: 2,
        errorMaxLines: 3,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscured ? 'Show password' : 'Hide password',
          icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}
