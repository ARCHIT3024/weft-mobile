import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:weft_mobile/core/l10n/app_language.dart';
import 'package:weft_mobile/core/storage/token_storage.dart';
import 'package:weft_mobile/data/models/models.dart';
import 'package:weft_mobile/data/repositories/repositories.dart';

import '../helpers/fake_http.dart';
import '../helpers/fixtures.dart';

void main() {
  late FakeHttpAdapter adapter;
  late InMemoryTokenStorage tokens;

  setUp(() {
    tokens = InMemoryTokenStorage();
    adapter = FakeHttpAdapter((req) async => jsonResponse({}));
  });

  group('AuthRepository', () {
    test('login normalises email, persists both tokens', () async {
      adapter.handler = (req) async => jsonResponse(authResponseJson());
      final repo = AuthRepository(fakeDio(adapter), tokens);
      final auth = await repo.login(
        email: ' Citizen@WEFT.local ',
        password: 'pw',
      );

      final req = adapter.requests.single;
      expect(req.method, 'POST');
      expect(req.path, '/auth/login');
      expect(jsonDecode(req.bodyText), {
        'email': 'citizen@weft.local',
        'password': 'pw',
      });
      expect(auth.user.name, 'Test Citizen');
      expect(await tokens.readAccessToken(), 'access-123');
      expect(await tokens.readRefreshToken(), 'refresh-456');
    });

    test('login 401 → ApiException(401), nothing persisted', () async {
      adapter.handler = (req) async => jsonResponse(
        errorEnvelope('UNAUTHORIZED', 'Invalid email or password'),
        401,
      );
      final repo = AuthRepository(fakeDio(adapter), tokens);
      await expectLater(
        repo.login(email: 'a@b.co', password: 'x'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isUnauthorized,
            'isUnauthorized',
            isTrue,
          ),
        ),
      );
      expect(await tokens.readRefreshToken(), isNull);
    });

    test(
      'register sends RegisterRequest fields, returns profile not tokens',
      () async {
        adapter.handler = (req) async =>
            jsonResponse(registerResponseJson(), 201);
        final repo = AuthRepository(fakeDio(adapter), tokens);
        final r = await repo.register(
          name: '  New Citizen ',
          email: 'New@Weft.Local',
          password: 'password1',
        );
        expect(jsonDecode(adapter.requests.single.bodyText), {
          'name': 'New Citizen',
          'email': 'new@weft.local',
          'password': 'password1',
        });
        expect(r.userId, userId);
        expect(await tokens.readAccessToken(), isNull);
      },
    );

    test('register 409 surfaces the backend code', () async {
      adapter.handler = (req) async => jsonResponse(
        errorEnvelope('EMAIL_ALREADY_REGISTERED', 'Email already registered'),
        409,
      );
      final repo = AuthRepository(fakeDio(adapter), tokens);
      await expectLater(
        repo.register(name: 'n', email: 'a@b.co', password: 'password1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            ApiErrorCodes.emailAlreadyRegistered,
          ),
        ),
      );
    });

    test(
      'logout posts {refresh_token} (D-3) and clears local tokens',
      () async {
        await tokens.writeTokens(accessToken: 'a', refreshToken: 'r');
        adapter.handler = (req) async => emptyResponse(204);
        await AuthRepository(fakeDio(adapter), tokens).logout();
        final req = adapter.requests.single;
        expect(req.path, '/auth/logout');
        expect(jsonDecode(req.bodyText), {'refresh_token': 'r'});
        expect(await tokens.readRefreshToken(), isNull);
      },
    );

    test('logout clears tokens even when offline', () async {
      await tokens.writeTokens(accessToken: 'a', refreshToken: 'r');
      adapter.handler = (req) async => throw Exception('offline');
      await AuthRepository(fakeDio(adapter), tokens).logout();
      expect(await tokens.readAccessToken(), isNull);
    });
  });

  group('UserRepository', () {
    test('getMe', () async {
      adapter.handler = (req) async => jsonResponse(userProfileJson());
      final me = await UserRepository(fakeDio(adapter)).getMe();
      expect(adapter.requests.single.path, '/users/me');
      expect(me.totalPoints, 120);
    });

    test(
      'updateMe sends only provided fields; push token is fcm_token',
      () async {
        await UserRepository(
          fakeDio(adapter),
        ).updateMe(preferredLang: AppLanguage.hi, fcmToken: 'tok');
        final req = adapter.requests.single;
        expect(req.method, 'PATCH');
        expect(jsonDecode(req.bodyText), {
          'preferred_lang': 'hi',
          'fcm_token': 'tok',
        });
      },
    );

    test('getMyReports repeats status params', () async {
      adapter.handler = (req) async => jsonResponse(paginatedJson([]));
      await UserRepository(
        fakeDio(adapter),
      ).getMyReports(statuses: [IssueStatus.reported, IssueStatus.inProgress]);
      final q = adapter.requests.single.uri.queryParametersAll;
      expect(q['status'], ['REPORTED', 'IN_PROGRESS']);
      expect(q['page'], ['1']);
    });
  });

  group('IssueRepository', () {
    test(
      'createIssue: multipart, repeated images field, optional fields',
      () async {
        adapter.handler = (req) async =>
            jsonResponse(createIssueResponseJson(), 201);
        final res = await IssueRepository(fakeDio(adapter)).createIssue(
          CreateIssueInput(
            category: IssueCategory.garbageAccumulation,
            latitude: 13.08,
            longitude: 80.27,
            description: '  Overflowing bin  ',
            captchaToken: 'cap',
            images: [
              ImageUpload.fromBytes(
                Uint8List.fromList([1, 2, 3]),
                filename: 'a.jpg',
              ),
              ImageUpload.fromBytes(
                Uint8List.fromList([4, 5]),
                filename: 'b.jpg',
              ),
            ],
          ),
        );
        final req = adapter.requests.single;
        expect(req.method, 'POST');
        expect(req.path, '/issues');
        final body = req.bodyText;
        expect(body, contains('name="category"\r\n\r\nGARBAGE_ACCUMULATION'));
        expect(body, contains('name="latitude"\r\n\r\n13.08'));
        expect(body, contains('name="longitude"\r\n\r\n80.27'));
        expect(body, contains('name="description"\r\n\r\nOverflowing bin'));
        expect(body, contains('name="captcha_token"\r\n\r\ncap'));
        expect(body, isNot(contains('name="address_text"')));
        expect(
          'name="images"'.allMatches(body).length,
          2,
          reason: 'images must be a repeated field, not images[]',
        );
        expect(body, contains('filename="a.jpg"'));
        expect(res.issueNumber, 'ISS-2026-K7QD3M8XPZ');
      },
    );

    test('listIssues uses the running backend param names', () async {
      adapter.handler = (req) async =>
          jsonResponse(paginatedJson([issueSummaryJson()]));
      final page = await IssueRepository(fakeDio(adapter)).listIssues(
        const IssueQuery(
          categories: [IssueCategory.pothole, IssueCategory.waterLogging],
          statuses: [IssueStatus.reported],
          lat: 13.0,
          lng: 80.0,
          radius: 1500,
          page: 2,
          sort: IssueSort.upvoteCount,
          descending: false,
        ),
      );
      final q = adapter.requests.single.uri.queryParametersAll;
      expect(q['category'], ['POTHOLE', 'WATER_LOGGING']);
      expect(q['status'], ['REPORTED']);
      expect(q['radius'], ['1500']);
      expect(q['sort'], ['upvote_count']);
      expect(q['order'], ['asc']);
      expect(q['page'], ['2']);
      expect(page.items.single.category, IssueCategory.pothole);
    });

    test('nearbyIssues parses a plain JSON array', () async {
      adapter.handler = (req) async => jsonResponse([nearbyIssueJson()]);
      final list = await IssueRepository(
        fakeDio(adapter),
      ).nearbyIssues(lat: 13.08, lng: 80.27);
      final q = adapter.requests.single.uri.queryParameters;
      expect(adapter.requests.single.path, '/issues/nearby');
      expect(q['radius'], '2000');
      expect(q['limit'], '50');
      expect(list.single.distanceM, 142.37);
    });

    test('getIssue 404 → ApiException.isNotFound', () async {
      adapter.handler = (req) async =>
          jsonResponse(errorEnvelope('NOT_FOUND', 'Issue not found'), 404);
      await expectLater(
        IssueRepository(fakeDio(adapter)).getIssue(issueId),
        throwsA(isA<ApiException>().having((e) => e.isNotFound, '404', isTrue)),
      );
    });

    test('malformed 2xx body → INVALID_RESPONSE ApiException', () async {
      adapter.handler = (req) async => jsonResponse({'id': 1});
      await expectLater(
        IssueRepository(fakeDio(adapter)).getIssue(issueId),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'INVALID_RESPONSE'),
        ),
      );
    });
  });

  group('Upvote / Notification repositories', () {
    test('upvote and remove', () async {
      adapter.handler = (req) async => req.method == 'POST'
          ? jsonResponse(upvoteResponseJson(), 201)
          : emptyResponse(204);
      final repo = UpvoteRepository(fakeDio(adapter));
      expect((await repo.upvote(issueId)).upvoteCount, 13);
      await repo.removeUpvote(issueId);
      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'POST /issues/$issueId/upvote',
        'DELETE /issues/$issueId/upvote',
      ]);
    });

    test('notifications list / read / read-all', () async {
      adapter.handler = (req) async {
        if (req.path == '/notifications') {
          return jsonResponse(notificationsMockJson());
        }
        if (req.path.endsWith('read-all')) {
          return jsonResponse({'updated_count': 3});
        }
        return jsonResponse({'id': 'n1', 'is_read': true});
      };
      final repo = NotificationRepository(fakeDio(adapter));
      expect((await repo.list()).items, hasLength(1));
      await repo.markRead('n1');
      expect(await repo.markAllRead(), 3);
      expect(adapter.requests[1].path, '/notifications/n1/read');
      expect(adapter.requests[1].method, 'PATCH');
    });
  });
}
