import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weft_mobile/core/env_config.dart';
import 'package:weft_mobile/core/storage/token_storage.dart';
import 'package:weft_mobile/services/api_client.dart';

import '../helpers/fake_http.dart';

/// Task 2.6 fixes: (a) concurrent 401s queue behind ONE refresh and are each
/// replayed once; (b) refresh uses the same base URL as the main client.
void main() {
  const baseUrl = 'http://api.test/v1';

  late InMemoryTokenStorage storage;
  late FakeHttpAdapter api;
  late FakeHttpAdapter refresh;
  late Completer<void> releaseRefresh;
  late int sessionExpiredCalls;

  ApiClient buildClient() => ApiClient(
    storage: storage,
    baseUrl: baseUrl,
    dio: fakeDio(api, baseUrl: baseUrl),
    refreshDio: fakeDio(refresh, baseUrl: baseUrl),
    onSessionExpired: () => sessionExpiredCalls++,
    enableLogging: false,
  );

  setUp(() {
    storage = InMemoryTokenStorage(accessToken: 'old', refreshToken: 'r1');
    sessionExpiredCalls = 0;
    releaseRefresh = Completer<void>();
    // Main API: the stale token is rejected, the fresh one accepted.
    api = FakeHttpAdapter((req) async {
      if (req.authorization == 'Bearer new') {
        return jsonResponse({'path': req.path});
      }
      return jsonResponse(
        errorEnvelope('UNAUTHORIZED', 'Authentication required'),
        401,
      );
    });
    // Refresh endpoint: held open until the test releases it.
    refresh = FakeHttpAdapter((req) async {
      await releaseRefresh.future;
      return jsonResponse({
        'access_token': 'new',
        'refresh_token': 'r2',
        'token_type': 'bearer',
        'expires_in': 86400,
      });
    });
  });

  group('concurrent 401s (fix a)', () {
    test('three concurrent 401s trigger ONE refresh and each request is '
        'replayed exactly once with the new token', () async {
      final client = buildClient();

      final futures = [
        client.dio.get<Map<String, dynamic>>('/a'),
        client.dio.get<Map<String, dynamic>>('/b'),
        client.dio.get<Map<String, dynamic>>('/c'),
      ];
      await flushAsync();

      // All three have failed once and are waiting on the single refresh.
      expect(refresh.requests, hasLength(1));
      expect(
        client.queuedRequestCount,
        2,
        reason: 'the 2nd and 3rd 401 must be queued, not failed',
      );

      releaseRefresh.complete();
      final responses = await Future.wait(futures);

      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(responses.map((r) => r.data!['path']), ['/a', '/b', '/c']);
      expect(refresh.requests, hasLength(1), reason: 'one refresh only');
      expect(
        refresh.requests.single.bodyText,
        contains('"refresh_token":"r1"'),
      );

      // Each path: exactly one stale attempt + exactly one replay.
      for (final path in ['/a', '/b', '/c']) {
        final attempts = api.requests.where((r) => r.path == path).toList();
        expect(
          attempts.map((r) => r.authorization),
          ['Bearer old', 'Bearer new'],
          reason: '$path must be replayed once',
        );
      }
      expect(await storage.readAccessToken(), 'new');
      expect(
        await storage.readRefreshToken(),
        'r2',
        reason: 'rotated refresh token must be stored',
      );
      expect(client.queuedRequestCount, 0);
      expect(sessionExpiredCalls, 0);
    });

    test(
      'a 401 that arrives AFTER the refresh finished (request sent with '
      'the old token) reuses the new token instead of rotating again',
      () async {
        final releaseSlow = Completer<void>();
        api.handler = (req) async {
          if (req.authorization == 'Bearer new') {
            return jsonResponse({'path': req.path});
          }
          if (req.path == '/slow') await releaseSlow.future;
          return jsonResponse(errorEnvelope('UNAUTHORIZED', 'expired'), 401);
        };
        releaseRefresh.complete();
        final client = buildClient();

        final slow = client.dio.get<Map<String, dynamic>>('/slow');
        await flushAsync();
        final fast = await client.dio.get<Map<String, dynamic>>('/fast');
        expect(fast.statusCode, 200);
        expect(refresh.requests, hasLength(1));

        releaseSlow.complete();
        final slowResponse = await slow;
        expect(slowResponse.statusCode, 200);
        expect(refresh.requests, hasLength(1), reason: 'no second rotation');
        expect(await storage.readRefreshToken(), 'r2');
      },
    );
  });

  group('refresh failure', () {
    test('server rejects the refresh token: every queued request fails, '
        'tokens are cleared, session-expired fires once', () async {
      refresh.handler = (req) async {
        await releaseRefresh.future;
        return jsonResponse(
          errorEnvelope('UNAUTHORIZED', 'Invalid or expired refresh token'),
          401,
        );
      };
      final client = buildClient();
      final futures = [
        for (final p in ['/a', '/b', '/c'])
          client.dio
              .get<Object?>(p)
              .then<int?>(
                (r) => r.statusCode,
                onError: (Object e) => (e as DioException).response?.statusCode,
              ),
      ];
      await flushAsync();
      releaseRefresh.complete();
      final statuses = await Future.wait(futures);

      expect(statuses, [401, 401, 401]);
      expect(refresh.requests, hasLength(1));
      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
      expect(sessionExpiredCalls, 1);
      expect(client.queuedRequestCount, 0);
      // Nothing was replayed.
      expect(api.requests, hasLength(3));
    });

    test('network failure during refresh does NOT log the user out', () async {
      refresh.handler = (req) async => throw DioException.connectionError(
        requestOptions: req.options,
        reason: 'offline',
      );
      final client = buildClient();
      await expectLater(
        client.dio.get<Object?>('/a'),
        throwsA(isA<DioException>()),
      );
      expect(await storage.readRefreshToken(), 'r1');
      expect(sessionExpiredCalls, 0);
    });
  });

  group('no refresh attempted', () {
    test(
      'without a refresh token (anonymous) the 401 passes through',
      () async {
        storage = InMemoryTokenStorage();
        final client = buildClient();
        await expectLater(
          client.dio.get<Object?>('/users/me'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              401,
            ),
          ),
        );
        expect(refresh.requests, isEmpty);
        expect(api.requests.single.authorization, isNull);
      },
    );

    test(
      'a 401 from /auth/login (bad credentials) is not a refresh trigger',
      () async {
        final client = buildClient();
        await expectLater(
          client.dio.post<Object?>('/auth/login', data: {'email': 'x'}),
          throwsA(isA<DioException>()),
        );
        expect(refresh.requests, isEmpty);
        expect(sessionExpiredCalls, 0);
      },
    );

    test(
      'a replayed request that 401s again is returned, not looped',
      () async {
        releaseRefresh.complete();
        api.handler = (req) async =>
            jsonResponse(errorEnvelope('UNAUTHORIZED', 'nope'), 401);
        final client = buildClient();
        await expectLater(
          client.dio.get<Object?>('/a'),
          throwsA(isA<DioException>()),
        );
        expect(refresh.requests, hasLength(1));
        expect(api.requests, hasLength(2), reason: 'original + one replay');
      },
    );
  });

  group('base URL (fix b)', () {
    test('refresh client uses the same base URL as the main client', () {
      final client = ApiClient(
        storage: InMemoryTokenStorage(),
        baseUrl: 'https://api-staging.weft.city/v1',
        enableLogging: false,
      );
      expect(client.dio.options.baseUrl, 'https://api-staging.weft.city/v1');
      expect(client.refreshDio.options.baseUrl, client.dio.options.baseUrl);
    });

    test('both default to EnvConfig.apiBaseUrl', () {
      final client = ApiClient(
        storage: InMemoryTokenStorage(),
        enableLogging: false,
      );
      expect(client.dio.options.baseUrl, EnvConfig.apiBaseUrl);
      expect(client.refreshDio.options.baseUrl, EnvConfig.apiBaseUrl);
    });

    test('refresh POSTs to <base>/auth/refresh', () async {
      releaseRefresh.complete();
      final client = buildClient();
      await client.dio.get<Object?>('/a');
      expect(
        refresh.requests.single.uri.toString(),
        'http://api.test/v1/auth/refresh',
      );
      expect(refresh.requests.single.method, 'POST');
    });
  });
}
