/// App-wide authentication state (task 2.8).
///
/// States:
///   unknown         — bootstrapping (reading secure storage); router holds
///                     the user on the splash screen.
///   unauthenticated — no session; router sends the user to login.
///   anonymous       — "Continue anonymously": can browse and report, cannot
///                     upvote or see My Reports / notifications. Persisted.
///   authenticated   — tokens stored; [AuthState.user] holds the profile once
///                     fetched (may be null briefly, or while offline).
///
/// Auto-logout: when `ApiClient` sees the server reject the refresh token it
/// clears the tokens and fires `SessionEvents.expired`; this controller then
/// moves to `unauthenticated(sessionExpired: true)` and the router redirects to
/// login.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_language.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/api_providers.dart';
import '../../../data/models/api_error.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';

enum AuthStatus { unknown, unauthenticated, anonymous, authenticated }

@immutable
class AuthState {
  const AuthState._(this.status, {this.user, this.sessionExpired = false});

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.unauthenticated({bool sessionExpired = false})
    : this._(AuthStatus.unauthenticated, sessionExpired: sessionExpired);
  const AuthState.anonymous() : this._(AuthStatus.anonymous);
  const AuthState.authenticated([UserProfile? user])
    : this._(AuthStatus.authenticated, user: user);

  final AuthStatus status;

  /// Profile of the signed-in user (authenticated only; may lag the status).
  final UserProfile? user;

  /// True when we got here because the session expired (show a message).
  final bool sessionExpired;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAnonymous => status == AuthStatus.anonymous;

  /// Signed in OR browsing anonymously — i.e. allowed into the home shell.
  bool get canUseApp => isAuthenticated || isAnonymous;

  @override
  bool operator ==(Object other) =>
      other is AuthState &&
      other.status == status &&
      other.user == user &&
      other.sessionExpired == sessionExpired;

  @override
  int get hashCode => Object.hash(status, user, sessionExpired);

  @override
  String toString() => 'AuthState($status, user: ${user?.id})';
}

class AuthController extends Notifier<AuthState> {
  StreamSubscription<void>? _expirySub;

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  UserRepository get _users => ref.read(userRepositoryProvider);
  AppPreferences get _prefs => ref.read(appPreferencesProvider);

  @override
  AuthState build() {
    _expirySub = ref
        .read(sessionEventsProvider)
        .expired
        .listen((_) => _onSessionExpired());
    ref.onDispose(() => _expirySub?.cancel());
    // Bootstrap after build returns (state cannot be set during build).
    Future.microtask(bootstrap);
    return const AuthState.unknown();
  }

  /// Restores the persisted session. Safe to call more than once.
  Future<void> bootstrap() async {
    final hasSession =
        (await ref.read(tokenStorageProvider).readRefreshToken()) != null;
    if (hasSession) {
      state = const AuthState.authenticated();
      // Fire-and-forget: the app is usable offline without the profile.
      unawaited(refreshProfile());
      return;
    }
    state = _prefs.anonymousMode
        ? const AuthState.anonymous()
        : const AuthState.unauthenticated();
  }

  /// Email + password login. Throws [ApiException] on failure (401 invalid
  /// credentials, 429 rate limited, network...).
  Future<void> login({required String email, required String password}) async {
    final auth = await _auth.login(email: email, password: password);
    await _prefs.setAnonymousMode(false);
    state = AuthState.authenticated(auth.user);
    unawaited(_syncLanguageToServer());
  }

  /// Register, then log straight in (register returns a profile, not tokens).
  /// If registration succeeds but the follow-up login fails, throws
  /// [AccountCreatedButLoginFailed] so the UI can send the user to login.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    await _auth.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
    try {
      await login(email: email, password: password);
    } on ApiException catch (e) {
      throw AccountCreatedButLoginFailed(e);
    }
  }

  /// "Continue anonymously" — persisted so the next launch skips login.
  Future<void> continueAnonymously() async {
    await _prefs.setAnonymousMode(true);
    state = const AuthState.anonymous();
  }

  /// Logs out (revokes this device's refresh token, D-3) or leaves anonymous
  /// mode. Always ends unauthenticated, even offline.
  Future<void> logout() async {
    if (state.isAuthenticated) await _auth.logout();
    await _prefs.setAnonymousMode(false);
    state = const AuthState.unauthenticated();
  }

  /// Re-fetches `GET /users/me`. Errors are swallowed except that they leave
  /// the cached profile in place; a rejected session is handled by
  /// [_onSessionExpired] via the API client. Returns the fresh profile.
  Future<UserProfile?> refreshProfile() async {
    if (!state.isAuthenticated) return null;
    try {
      final me = await _users.getMe();
      if (state.isAuthenticated) state = AuthState.authenticated(me);
      return me;
    } on ApiException {
      return state.user;
    }
  }

  /// Best-effort: push the device's chosen language to the profile.
  Future<void> _syncLanguageToServer() async {
    final lang = ref.read(selectedLanguageProvider);
    final user = state.user;
    if (lang == null || user == null || user.preferredLang == lang) return;
    await updatePreferredLanguage(lang);
  }

  /// Saves [language] on the server for signed-in users (best effort).
  Future<void> updatePreferredLanguage(AppLanguage language) async {
    if (!state.isAuthenticated) return;
    try {
      await _users.updateMe(preferredLang: language);
    } on ApiException {
      // Local choice already saved; the server copy can catch up later.
    }
  }

  void _onSessionExpired() {
    if (state.status == AuthStatus.unauthenticated) return;
    state = const AuthState.unauthenticated(sessionExpired: true);
  }
}

class AccountCreatedButLoginFailed implements Exception {
  AccountCreatedButLoginFailed(this.cause);

  final ApiException cause;

  @override
  String toString() => 'AccountCreatedButLoginFailed($cause)';
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Convenience: the signed-in profile, or null.
final currentUserProvider = Provider<UserProfile?>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.user)),
);
