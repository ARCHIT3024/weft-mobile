import 'package:flutter/material.dart';

import '../../../core/l10n/app_language.dart';
import '../../../core/theme.dart';

/// Radio list of the six supported languages, native name first.
/// Used on first launch (`/language`) and from the profile screen.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AppLanguage selected;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<AppLanguage>(
      groupValue: selected,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final lang in AppLanguage.values)
            RadioListTile<AppLanguage>(
              value: lang,
              title: Text(
                lang.nativeName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: WeftColors.textPrimary,
                ),
              ),
              subtitle: lang == AppLanguage.en ? null : Text(lang.englishName),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet wrapper; resolves to the chosen language (or null).
Future<AppLanguage?> showLanguagePickerSheet(
  BuildContext context, {
  required AppLanguage current,
}) {
  return showModalBottomSheet<AppLanguage>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Semantics(
                  header: true,
                  child: const Text(
                    'Language',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              LanguagePicker(
                selected: current,
                onChanged: (lang) => Navigator.of(context).pop(lang),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
