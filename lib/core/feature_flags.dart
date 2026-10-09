/// Compile-time feature flags, set with `--dart-define`.
library;

class FeatureFlags {
  FeatureFlags._();

  /// Google Sign-In on the login screen (task 2.4).
  ///
  /// **Off by default, and must stay off until backend task 1.4
  /// (`POST /auth/oauth/google`) exists.** The client side is also not wired:
  /// obtaining a Google ID token needs the `google_sign_in` package plus
  /// per-platform OAuth client configuration, neither of which is in this repo.
  /// `AuthRepository.loginWithGoogle(idToken)` is ready for when it is.
  ///
  /// Enable with `--dart-define=WEFT_ENABLE_GOOGLE_SIGN_IN=true`.
  static const bool googleSignIn = bool.fromEnvironment(
    'WEFT_ENABLE_GOOGLE_SIGN_IN',
  );
}
