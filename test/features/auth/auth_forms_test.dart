import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:weft_mobile/core/storage/app_preferences.dart';
import 'package:weft_mobile/core/storage/token_storage.dart';
import 'package:weft_mobile/core/theme.dart';
import 'package:weft_mobile/features/auth/login_screen.dart';
import 'package:weft_mobile/features/auth/register_screen.dart';
import 'package:weft_mobile/features/auth/state/auth_controller.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/fixtures.dart';
import '../../helpers/test_app.dart';

/// Login/Register screens inside a minimal router (no redirects), so the
/// tests exercise the forms and the auth controller in isolation.
Future<ProviderContainer> pumpAuth(
  WidgetTester tester, {
  required FakeHttpAdapter adapter,
  InMemoryTokenStorage? tokens,
  String initial = '/login',
}) async {
  usePhoneSurface(tester);
  final container = await createTestContainer(adapter: adapter, tokens: tokens);
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/map',
        builder: (_, _) => const Scaffold(body: Text('MAP')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    wrapWithContainer(
      container,
      MaterialApp.router(theme: WeftTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late FakeHttpAdapter adapter;

  setUp(() {
    adapter = FakeHttpAdapter((req) async => jsonResponse({}));
  });

  group('LoginScreen', () {
    testWidgets('empty submit shows field errors and sends nothing', (
      tester,
    ) async {
      await pumpAuth(tester, adapter: adapter);
      await tapVisible(tester, find.byKey(const Key('login_submit')));

      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('malformed email is rejected client-side', (tester) async {
      await pumpAuth(tester, adapter: adapter);
      await tester.enterText(find.byKey(const Key('login_email')), 'a@b');
      await tester.enterText(find.byKey(const Key('login_password')), 'x');
      await tapVisible(tester, find.byKey(const Key('login_submit')));

      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('valid credentials log in and store tokens', (tester) async {
      adapter.handler = (req) async => jsonResponse(authResponseJson());
      final tokens = InMemoryTokenStorage();
      final container = await pumpAuth(
        tester,
        adapter: adapter,
        tokens: tokens,
      );

      await tester.enterText(
        find.byKey(const Key('login_email')),
        'Citizen@Weft.local',
      );
      await tester.enterText(
        find.byKey(const Key('login_password')),
        'DevPassword123!',
      );
      await tapVisible(tester, find.byKey(const Key('login_submit')));

      final login = adapter.requests.firstWhere((r) => r.path == '/auth/login');
      expect(jsonDecode(login.bodyText)['email'], 'citizen@weft.local');
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.name, 'Test Citizen');
      expect(await tokens.readRefreshToken(), 'refresh-456');
    });

    testWidgets('wrong password shows a non-revealing error', (tester) async {
      adapter.handler = (req) async => jsonResponse(
        errorEnvelope('UNAUTHORIZED', 'Invalid email or password'),
        401,
      );
      final container = await pumpAuth(tester, adapter: adapter);

      await tester.enterText(
        find.byKey(const Key('login_email')),
        'citizen@weft.local',
      );
      await tester.enterText(find.byKey(const Key('login_password')), 'nope');
      await tapVisible(tester, find.byKey(const Key('login_submit')));

      expect(find.text('Incorrect email or password.'), findsOneWidget);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.unauthenticated,
      );
    });

    testWidgets('rate limit shows the retry-after time', (tester) async {
      adapter.handler = (req) async => jsonResponse(
        errorEnvelope('RATE_LIMIT_EXCEEDED', 'Too many', {
          'retry_after_seconds': 37,
        }),
        429,
      );
      await pumpAuth(tester, adapter: adapter);
      await tester.enterText(
        find.byKey(const Key('login_email')),
        'citizen@weft.local',
      );
      await tester.enterText(find.byKey(const Key('login_password')), 'x');
      await tapVisible(tester, find.byKey(const Key('login_submit')));

      expect(find.textContaining('37 seconds'), findsOneWidget);
    });

    testWidgets('Continue anonymously persists the mode and opens the map', (
      tester,
    ) async {
      final container = await pumpAuth(tester, adapter: adapter);
      await tapVisible(tester, find.byKey(const Key('login_anonymous')));

      expect(find.text('MAP'), findsOneWidget);
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.anonymous,
      );
      expect(container.read(appPreferencesProvider).anonymousMode, isTrue);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('Google Sign-In is hidden by default (backend 1.4 missing)', (
      tester,
    ) async {
      await pumpAuth(tester, adapter: adapter);
      expect(find.text('Continue with Google'), findsNothing);
    });

    testWidgets('touch targets are at least 48dp', (tester) async {
      await pumpAuth(tester, adapter: adapter);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  group('RegisterScreen', () {
    Future<void> fill(
      WidgetTester tester, {
      String name = 'New Citizen',
      String email = 'new@weft.local',
      String password = 'password1',
      String confirm = 'password1',
    }) async {
      await tester.enterText(find.byKey(const Key('register_name')), name);
      await tester.enterText(find.byKey(const Key('register_email')), email);
      await tester.enterText(
        find.byKey(const Key('register_password')),
        password,
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm')),
        confirm,
      );
    }

    testWidgets('empty submit shows every required-field error', (
      tester,
    ) async {
      await pumpAuth(tester, adapter: adapter, initial: '/register');
      await tapVisible(tester, find.byKey(const Key('register_submit')));

      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Enter a password'), findsOneWidget);
      expect(find.text('Re-enter your password'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('password shorter than 8 and mismatched confirm are rejected', (
      tester,
    ) async {
      await pumpAuth(tester, adapter: adapter, initial: '/register');
      await fill(tester, password: 'short', confirm: 'shorter');
      await tapVisible(tester, find.byKey(const Key('register_submit')));

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(adapter.requests, isEmpty);
    });

    testWidgets('valid form registers, then logs in (register returns no '
        'tokens)', (tester) async {
      adapter.handler = (req) async => req.path == '/auth/register'
          ? jsonResponse(registerResponseJson(), 201)
          : jsonResponse(authResponseJson());
      final container = await pumpAuth(
        tester,
        adapter: adapter,
        initial: '/register',
      );
      await fill(tester);
      await tapVisible(tester, find.byKey(const Key('register_submit')));

      expect(adapter.requests.map((r) => r.path).take(2), [
        '/auth/register',
        '/auth/login',
      ]);
      expect(jsonDecode(adapter.requests.first.bodyText), {
        'name': 'New Citizen',
        'email': 'new@weft.local',
        'password': 'password1',
      });
      expect(
        container.read(authControllerProvider).status,
        AuthStatus.authenticated,
      );
    });

    testWidgets('duplicate email (409) shows a helpful message', (
      tester,
    ) async {
      adapter.handler = (req) async => jsonResponse(
        errorEnvelope('EMAIL_ALREADY_REGISTERED', 'Email already registered'),
        409,
      );
      await pumpAuth(tester, adapter: adapter, initial: '/register');
      await fill(tester);
      await tapVisible(tester, find.byKey(const Key('register_submit')));

      expect(find.textContaining('already exists'), findsOneWidget);
    });
  });
}
