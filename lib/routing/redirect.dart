/// Pure redirect policy for GoRouter — no Flutter, no Riverpod, so it is
/// unit-tested exhaustively in test/routing/redirect_test.dart.
library;

import '../features/auth/state/auth_controller.dart';
import 'routes.dart';

/// Returns the location to redirect to, or `null` to stay.
///
/// [uri] is the requested location (path + query).
String? resolveRedirect({
  required Uri uri,
  required AuthStatus auth,
  required bool languageChosen,
  required bool onboardingSeen,
}) {
  final path = uri.path;

  // 1. Bootstrapping: hold everything on the splash screen.
  if (auth == AuthStatus.unknown) {
    return path == Routes.splash ? null : Routes.splash;
  }

  // 2. Signed in: skip every pre-auth screen; honour ?from= after login.
  if (auth == AuthStatus.authenticated) {
    if (!Routes.preAuth.contains(path)) return null;
    final from = uri.queryParameters[Routes.fromParam];
    if (_isSafeInAppTarget(from)) return from;
    return Routes.map;
  }

  // 3. First launch: language, then onboarding (each shown once).
  if (!languageChosen) {
    return path == Routes.language ? null : Routes.language;
  }
  if (!onboardingSeen) {
    return path == Routes.onboarding ? null : Routes.onboarding;
  }

  // 4. Signed out: only login/register.
  if (auth == AuthStatus.unauthenticated) {
    return path == Routes.login || path == Routes.register
        ? null
        : Routes.login;
  }

  // 5. Anonymous: the whole app, plus login/register (to upgrade); the
  //    first-launch screens bounce to the map.
  if (path == Routes.splash ||
      path == Routes.language ||
      path == Routes.onboarding) {
    return Routes.map;
  }
  return null;
}

/// Only relative in-app paths, never another pre-auth screen (no loops) and
/// never a scheme/host (no open redirect via a crafted deep link).
bool _isSafeInAppTarget(String? from) {
  if (from == null || from.isEmpty) return false;
  if (!from.startsWith('/') || from.startsWith('//')) return false;
  final target = Uri.tryParse(from);
  if (target == null || target.hasScheme || target.hasAuthority) return false;
  return !Routes.preAuth.contains(target.path);
}
