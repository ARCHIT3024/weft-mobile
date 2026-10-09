import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:weft_mobile/app.dart';
import 'package:weft_mobile/core/storage/app_preferences.dart';
import 'package:weft_mobile/core/storage/token_storage.dart';
import 'package:weft_mobile/features/auth/state/auth_controller.dart';
import 'package:weft_mobile/routing/app_router.dart';
import 'package:weft_mobile/routing/routes.dart';

import '../helpers/fake_http.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';

/// End-to-end routing through the real WeftApp, router, redirect and
/// AuthController — only HTTP and storage are faked.
void main() {
  late FakeHttpAdapter adapter;

  setUp(() {
    adapter = FakeHttpAdapter((req) async {
      if (req.path == '/users/me') return jsonResponse(userProfileJson());
      return jsonResponse({});
    });
  });

  /// Location of the top-most route, including pushed (imperative) ones.
  String location(ProviderContainer container) {
    final config = container
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration;
    final last = config.last;
    return last is ImperativeRouteMatch
        ? last.matches.uri.toString()
        : config.uri.toString();
  }

  testWidgets('first launch: language → onboarding (skip) → login', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final container = await createTestContainer(
      adapter: adapter,
      languageChosen: false,
      onboardingSeen: false,
    );
    await tester.pumpWidget(wrapWithContainer(container, const WeftApp()));
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(container.read(appPreferencesProvider).language?.code, 'en');

    expect(find.text('Report in seconds'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(container.read(appPreferencesProvider).onboardingSeen, isTrue);

    expect(location(container), Routes.login);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('stored session → home shell; profile shows /users/me data', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final container = await createTestContainer(
      adapter: adapter,
      tokens: InMemoryTokenStorage(accessToken: 'a', refreshToken: 'r'),
    );
    await tester.pumpWidget(wrapWithContainer(container, const WeftApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(location(container), Routes.map);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('report_fab')), findsOneWidget);
    expect(container.read(authControllerProvider).user?.name, 'Test Citizen');

    await tester.tap(find.text('Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(location(container), Routes.profile);
    expect(find.text('Test Citizen'), findsOneWidget);
    expect(find.text('citizen@weft.local'), findsOneWidget);
    expect(find.text('Civic Contributor'), findsOneWidget);
    expect(find.text('75.5%'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
  });

  testWidgets('Report FAB opens the report flow over the shell', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final container = await createTestContainer(
      adapter: adapter,
      anonymous: true,
    );
    await tester.pumpWidget(wrapWithContainer(container, const WeftApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(location(container), Routes.map);

    await tester.tap(find.byKey(const Key('report_fab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(location(container), Routes.report);
    expect(find.text('Step 1 of 3 — Take a photo'), findsOneWidget);
  });

  testWidgets('anonymous profile offers sign-in; logout returns to login', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final container = await createTestContainer(
      adapter: adapter,
      anonymous: true,
    );
    await tester.pumpWidget(wrapWithContainer(container, const WeftApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    container.read(routerProvider).go(Routes.profile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text("You're browsing anonymously"), findsOneWidget);

    await container.read(authControllerProvider.notifier).logout();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(location(container), Routes.login);
    expect(container.read(appPreferencesProvider).anonymousMode, isFalse);
  });

  testWidgets('refresh token rejected → auto-logout to login with message', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final tokens = InMemoryTokenStorage(accessToken: 'a', refreshToken: 'r');
    adapter.handler = (req) async {
      // Access token expired AND refresh token revoked.
      return jsonResponse(errorEnvelope('UNAUTHORIZED', 'expired'), 401);
    };
    final container = await createTestContainer(
      adapter: adapter,
      tokens: tokens,
    );
    await tester.pumpWidget(wrapWithContainer(container, const WeftApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      adapter.requests.map((r) => r.path),
      containsAllInOrder(['/users/me', '/auth/refresh']),
    );
    final state = container.read(authControllerProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.sessionExpired, isTrue);
    expect(await tokens.readRefreshToken(), isNull);
    expect(location(container), Routes.login);
    expect(
      find.text('Your session has expired. Please sign in again.'),
      findsOneWidget,
    );
  });

  testWidgets('unknown route shows a not-found page', (tester) async {
    usePhoneSurface(tester);
    final container = await createTestContainer(
      adapter: adapter,
      anonymous: true,
    );
    await tester.pumpWidget(wrapWithContainer(container, const WeftApp()));
    await tester.pump();
    container.read(routerProvider).go('/does-not-exist');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Page not found'), findsOneWidget);
  });
}
