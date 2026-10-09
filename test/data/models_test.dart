import 'package:flutter_test/flutter_test.dart';
import 'package:weft_mobile/core/l10n/app_language.dart';
import 'package:weft_mobile/data/models/models.dart';

import '../helpers/fixtures.dart';

void main() {
  group('UserProfile', () {
    test('parses the GET /users/me shape', () {
      final u = UserProfile.fromJson(userProfileJson());
      expect(u.id, userId);
      expect(u.email, 'citizen@weft.local');
      expect(u.name, 'Test Citizen');
      expect(u.role, UserRole.citizen);
      expect(u.trustScore, 75.5);
      expect(u.totalPoints, 120);
      expect(u.title, 'Civic Contributor');
      expect(u.isAnonymous, isFalse);
      expect(u.preferredLang, AppLanguage.en);
      expect(u.createdAt, DateTime.utc(2026, 9, 8, 10, 15, 30, 123, 456));
    });

    test('null title/name/email, integer trust score, other language', () {
      final json = userProfileJson(title: null, lang: 'ta')
        ..['trust_score'] = 0
        ..['name'] = null
        ..['email'] = null
        ..['total_points'] = -10;
      final u = UserProfile.fromJson(json);
      expect(u.title, isNull);
      expect(u.trustScore, 0.0);
      expect(u.totalPoints, -10);
      expect(u.preferredLang, AppLanguage.ta);
      expect(u.displayName, 'Citizen');
    });

    test('round-trips through toJson', () {
      final u = UserProfile.fromJson(userProfileJson());
      expect(UserProfile.fromJson(u.toJson()), u);
    });

    test('missing required field fails loudly', () {
      final json = userProfileJson()..remove('trust_score');
      expect(() => UserProfile.fromJson(json), throwsFormatException);
    });
  });

  group('auth', () {
    test('AuthResponse (login) parses tokens + user', () {
      final a = AuthResponse.fromJson(authResponseJson());
      expect(a.tokens.accessToken, 'access-123');
      expect(a.tokens.refreshToken, 'refresh-456');
      expect(a.tokens.tokenType, 'bearer');
      expect(a.tokens.expiresIn, 86400);
      expect(a.user.email, 'citizen@weft.local');
      expect(a.tokens.toString(), isNot(contains('access-123')));
    });

    test('TokenResponse (refresh) parses without user', () {
      final t = AuthTokens.fromJson({
        'access_token': 'a',
        'refresh_token': 'b',
        'token_type': 'bearer',
        'expires_in': 86400,
      });
      expect(t.refreshToken, 'b');
    });

    test('RegisterResponse is a profile, not tokens', () {
      final r = RegisterResponse.fromJson(registerResponseJson());
      expect(r.userId, userId);
      expect(r.email, 'new@weft.local');
      expect(r.role, UserRole.citizen);
    });
  });

  group('issues', () {
    test('IssueSummary parses every field', () {
      final i = IssueSummary.fromJson(issueSummaryJson());
      expect(i.id, issueId);
      expect(i.issueNumber, 'ISS-2026-K7QD3M8XPZ');
      expect(i.category, IssueCategory.pothole);
      expect(i.status, IssueStatus.reported);
      expect(i.latitude, 13.0827);
      expect(i.longitude, 80.2707);
      expect(i.addressText, 'Anna Salai, Chennai');
      expect(i.upvoteCount, 12);
      expect(i.assignedToId, isNull);
      expect(i.resolvedAt, isNull);
      expect(i.updatedAt, DateTime.utc(2026, 9, 9, 9, 30));
      expect(IssueSummary.fromJson(i.toJson()), i);
    });

    test('integer coordinates are accepted as doubles', () {
      final json = issueSummaryJson()
        ..['latitude'] = 13
        ..['longitude'] = 80;
      final i = IssueSummary.fromJson(json);
      expect(i.latitude, 13.0);
    });

    test('unknown enum values degrade instead of throwing', () {
      final i = IssueSummary.fromJson(
        issueSummaryJson(status: 'ESCALATED', category: 'TREE_FALL'),
      );
      expect(i.status, IssueStatus.unknown);
      expect(i.category, IssueCategory.other);
    });

    test('every backend category/status wire value maps', () {
      for (final wire in [
        'POTHOLE',
        'GARBAGE_ACCUMULATION',
        'WATER_LOGGING',
        'BROKEN_STREET_LIGHT',
        'DAMAGED_FOOTPATH',
        'SEWAGE_OVERFLOW',
        'OTHER',
      ]) {
        expect(IssueCategory.fromWire(wire).wire, wire);
      }
      for (final wire in ['REPORTED', 'IN_PROGRESS', 'RESOLVED', 'REJECTED']) {
        expect(IssueStatus.fromWire(wire).wire, wire);
      }
    });

    test('NearbyIssue carries distance_m', () {
      final n = NearbyIssue.fromJson(nearbyIssueJson());
      expect(n.distanceM, 142.37);
      expect(n.issueNumber, 'ISS-2026-K7QD3M8XPZ');
      expect(n.toJson()['distance_m'], 142.37);
    });

    test('IssueDetail parses images and status history', () {
      final d = IssueDetail.fromJson(issueDetailJson());
      expect(d.status, IssueStatus.inProgress);
      expect(d.assignedAt, DateTime.utc(2026, 9, 9, 9, 30));
      expect(d.images, hasLength(2));
      expect(d.reportImages.single.imageType, ImageType.report);
      expect(
        d.resolutionProofImages.single.cdnUrl,
        'https://cdn.weft.city/proof.jpg',
      );
      expect(d.statusHistory, hasLength(2));
      expect(d.statusHistory.first.newStatus, IssueStatus.inProgress);
      expect(d.statusHistory.first.previousStatus, IssueStatus.reported);
      expect(d.statusHistory.first.note, 'Crew dispatched');
      expect(d.statusHistory.last.previousStatus, isNull);
      expect(d.timelineOldestFirst.first.newStatus, IssueStatus.reported);
      expect(IssueDetail.fromJson(d.toJson()), d);
    });

    test('IssueImage.url resolves root-relative media and keeps absolute', () {
      final d = IssueDetail.fromJson(issueDetailJson());
      expect(d.images.first.url, startsWith('http'));
      expect(d.images.first.url, endsWith('/media/issues/$issueId/abc.jpg'));
      expect(d.images.first.url, isNot(contains('/v1/')));
      expect(d.images.last.url, 'https://cdn.weft.city/proof.jpg');
    });

    test('CreateIssueResponse', () {
      final c = CreateIssueResponse.fromJson(createIssueResponseJson());
      expect(c.issueId, issueId);
      expect(c.category, IssueCategory.garbageAccumulation);
      expect(c.status, IssueStatus.reported);
      expect(c.zoneId, isNull);
      expect(c.images, hasLength(1));
      expect(c.resolvedImageUrl, endsWith('/media/issues/$issueId/first.jpg'));
    });

    test('UpvoteResponse', () {
      final u = UpvoteResponse.fromJson(upvoteResponseJson());
      expect(u.upvoteCount, 13);
      expect(u.userId, userId);
    });
  });

  group('PaginatedResponse', () {
    test('parses wrapper and items', () {
      final p = PaginatedResponse.fromJson(
        paginatedJson([issueSummaryJson(), issueSummaryJson(id: 'x')]),
        IssueSummary.fromJson,
      );
      expect(p.items, hasLength(2));
      expect(p.total, 41);
      expect(p.page, 2);
      expect(p.pageSize, 20);
      expect(p.totalPages, 3);
      expect(p.hasNextPage, isTrue);
    });

    test('the /users/me/reports mock (empty page) parses', () {
      final p = PaginatedResponse.fromJson({
        'items': [],
        'total': 0,
        'page': 1,
        'page_size': 20,
        'total_pages': 1,
      }, IssueSummary.fromJson);
      expect(p.isEmpty, isTrue);
      expect(p.hasNextPage, isFalse);
    });
  });

  test('AppNotification parses the Phase 0 mock', () {
    final p = PaginatedResponse.fromJson(
      notificationsMockJson(),
      AppNotification.fromJson,
    );
    final n = p.items.single;
    expect(n.type, NotificationType.statusChange);
    expect(n.isRead, isFalse);
    expect(n.issueId, '550e8400-e29b-41d4-a716-446655440000');
    expect(n.copyWith(isRead: true).isRead, isTrue);
  });
}
