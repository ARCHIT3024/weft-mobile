import 'package:flutter_test/flutter_test.dart';
import 'package:weft_mobile/features/auth/state/auth_controller.dart';
import 'package:weft_mobile/routing/redirect.dart';
import 'package:weft_mobile/routing/routes.dart';

String? go(
  String location, {
  required AuthStatus auth,
  bool language = true,
  bool onboarding = true,
}) => resolveRedirect(
  uri: Uri.parse(location),
  auth: auth,
  languageChosen: language,
  onboardingSeen: onboarding,
);

void main() {
  const appRoutes = [
    Routes.map,
    Routes.myReports,
    Routes.notifications,
    Routes.profile,
    Routes.report,
    Routes.reportCategory,
    Routes.reportDetails,
    Routes.reportSuccess,
    '/issues/abc',
  ];

  group('bootstrapping (unknown)', () {
    test('everything is held on splash', () {
      for (final r in [...appRoutes, Routes.login, Routes.onboarding]) {
        expect(go(r, auth: AuthStatus.unknown), Routes.splash, reason: r);
      }
      expect(go(Routes.splash, auth: AuthStatus.unknown), isNull);
    });
  });

  group('unauthenticated', () {
    const s = AuthStatus.unauthenticated;

    test('first launch: language first, then onboarding', () {
      expect(
        go(Routes.splash, auth: s, language: false, onboarding: false),
        Routes.language,
      );
      expect(go(Routes.map, auth: s, language: false), Routes.language);
      expect(go(Routes.language, auth: s, language: false), isNull);
      expect(
        go(Routes.language, auth: s, onboarding: false),
        Routes.onboarding,
      );
      expect(go(Routes.onboarding, auth: s, onboarding: false), isNull);
    });

    test('app routes redirect to login', () {
      for (final r in [...appRoutes, Routes.splash, Routes.onboarding]) {
        expect(go(r, auth: s), Routes.login, reason: r);
      }
    });

    test('login and register are reachable', () {
      expect(go(Routes.login, auth: s), isNull);
      expect(go(Routes.register, auth: s), isNull);
      expect(go(Routes.loginFrom('/issues/1'), auth: s), isNull);
    });
  });

  group('anonymous', () {
    const s = AuthStatus.anonymous;

    test('whole app is reachable (incl. report flow and issue detail)', () {
      for (final r in appRoutes) {
        expect(go(r, auth: s), isNull, reason: r);
      }
    });

    test('can still open login/register to upgrade', () {
      expect(go(Routes.login, auth: s), isNull);
      expect(go(Routes.register, auth: s), isNull);
    });

    test('first-launch screens bounce to the map', () {
      expect(go(Routes.splash, auth: s), Routes.map);
      expect(go(Routes.onboarding, auth: s), Routes.map);
      expect(go(Routes.language, auth: s), Routes.map);
    });
  });

  group('authenticated', () {
    const s = AuthStatus.authenticated;

    test('app routes are reachable', () {
      for (final r in appRoutes) {
        expect(go(r, auth: s), isNull, reason: r);
      }
    });

    test('pre-auth screens go to the map', () {
      for (final r in Routes.preAuth) {
        expect(go(r, auth: s), Routes.map, reason: r);
      }
    });

    test('pre-auth state is irrelevant once signed in', () {
      expect(
        go(Routes.map, auth: s, language: false, onboarding: false),
        isNull,
      );
    });

    test('login?from= returns to the requested in-app page', () {
      expect(go(Routes.loginFrom('/issues/abc'), auth: s), '/issues/abc');
    });

    test('from= cannot be an external URL or a pre-auth loop', () {
      for (final from in [
        'https://evil.example/x',
        '//evil.example/x',
        'issues/abc',
        Routes.login,
        Routes.register,
      ]) {
        expect(go(Routes.loginFrom(from), auth: s), Routes.map, reason: from);
      }
    });
  });
}
