/// Languages the app offers, mirroring the backend `PreferredLanguage` enum
/// (`weft-backend/app/schemas/user.py`): en, hi, ta, te, mr, bn.
///
/// Task 2.2 stores the choice; task 4.13 adds real translations. To add them:
/// create `lib/l10n/*.arb`, enable `generate: true` + `flutter_localizations`
/// gen in pubspec, and add `AppLocalizations.delegate` next to the Global*
/// delegates in `lib/app.dart`. `MaterialApp.locale` is already driven by the
/// stored choice, so framework widgets (date pickers, tooltips) localise today.
library;

import 'package:flutter/widgets.dart';

enum AppLanguage {
  en('en', 'English', 'English'),
  hi('hi', 'Hindi', 'हिन्दी'),
  ta('ta', 'Tamil', 'தமிழ்'),
  te('te', 'Telugu', 'తెలుగు'),
  mr('mr', 'Marathi', 'मराठी'),
  bn('bn', 'Bengali', 'বাংলা');

  const AppLanguage(this.code, this.englishName, this.nativeName);

  /// BCP 47 code — the wire value for `preferred_lang`.
  final String code;
  final String englishName;
  final String nativeName;

  Locale get locale => Locale(code);

  static const AppLanguage fallback = AppLanguage.en;

  /// Parses a wire/storage code; unknown or null → `null`.
  static AppLanguage? tryParse(String? code) {
    if (code == null) return null;
    for (final lang in values) {
      if (lang.code == code.toLowerCase()) return lang;
    }
    return null;
  }

  static List<Locale> get supportedLocales =>
      values.map((l) => l.locale).toList(growable: false);
}
