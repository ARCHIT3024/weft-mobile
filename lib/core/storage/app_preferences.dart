/// Non-secret, device-local app state: onboarding seen, chosen language,
/// anonymous mode. Backed by SharedPreferences (never put tokens here — see
/// `token_storage.dart`).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../l10n/app_language.dart';

class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  bool get onboardingSeen =>
      _prefs.getBool(AppConstants.prefOnboardingSeen) ?? false;
  Future<void> setOnboardingSeen() =>
      _prefs.setBool(AppConstants.prefOnboardingSeen, true);

  /// `null` until the user has picked a language on first launch.
  AppLanguage? get language =>
      AppLanguage.tryParse(_prefs.getString(AppConstants.prefLanguageCode));
  Future<void> setLanguage(AppLanguage language) =>
      _prefs.setString(AppConstants.prefLanguageCode, language.code);

  bool get anonymousMode =>
      _prefs.getBool(AppConstants.prefAnonymousMode) ?? false;
  Future<void> setAnonymousMode(bool value) =>
      _prefs.setBool(AppConstants.prefAnonymousMode, value);
}

/// Must be overridden at startup with the instance loaded in `main()`
/// (tests: `SharedPreferences.setMockInitialValues` + `getInstance()`).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  ),
);

final appPreferencesProvider = Provider<AppPreferences>(
  (ref) => AppPreferences(ref.watch(sharedPreferencesProvider)),
);

/// Whether onboarding has been completed/skipped. Reactive so the router
/// re-evaluates its redirect when it changes.
class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(appPreferencesProvider).onboardingSeen;

  Future<void> markSeen() async {
    await ref.read(appPreferencesProvider).setOnboardingSeen();
    state = true;
  }
}

final onboardingSeenProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

/// The language the user picked; `null` = never chosen (first launch).
class LanguageController extends Notifier<AppLanguage?> {
  @override
  AppLanguage? build() => ref.watch(appPreferencesProvider).language;

  Future<void> select(AppLanguage language) async {
    await ref.read(appPreferencesProvider).setLanguage(language);
    state = language;
  }
}

final selectedLanguageProvider =
    NotifierProvider<LanguageController, AppLanguage?>(LanguageController.new);

/// The language to render in — the chosen one, or English.
final effectiveLanguageProvider = Provider<AppLanguage>(
  (ref) => ref.watch(selectedLanguageProvider) ?? AppLanguage.fallback,
);
