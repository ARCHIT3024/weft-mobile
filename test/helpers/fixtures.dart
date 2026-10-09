/// Backend-shaped JSON fixtures. Field names and value formats copied from
/// weft-backend/app/schemas/*.py (Pydantic v2 serialisation: UUIDs as
/// strings, datetimes ISO 8601 with offset, floats as numbers).
library;

const issueId = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
const userId = '550e8400-e29b-41d4-a716-446655440001';

Map<String, dynamic> userProfileJson({
  String? title = 'Civic Contributor',
  String lang = 'en',
}) => {
  'id': userId,
  'email': 'citizen@weft.local',
  'name': 'Test Citizen',
  'role': 'CITIZEN',
  'trust_score': 75.5,
  'total_points': 120,
  'title': title,
  'is_anonymous': false,
  'preferred_lang': lang,
  'created_at': '2026-09-08T10:15:30.123456Z',
};

Map<String, dynamic> authResponseJson() => {
  'access_token': 'access-123',
  'refresh_token': 'refresh-456',
  'token_type': 'bearer',
  'expires_in': 86400,
  'user': userProfileJson(),
};

Map<String, dynamic> registerResponseJson() => {
  'user_id': userId,
  'email': 'new@weft.local',
  'name': 'New Citizen',
  'role': 'CITIZEN',
  'created_at': '2026-09-08T10:15:30+00:00',
};

Map<String, dynamic> issueSummaryJson({
  String id = issueId,
  String status = 'REPORTED',
  String category = 'POTHOLE',
}) => {
  'id': id,
  'issue_number': 'ISS-2026-K7QD3M8XPZ',
  'category': category,
  'description': 'Large pothole near the signal',
  'status': status,
  'latitude': 13.0827,
  'longitude': 80.2707,
  'address_text': 'Anna Salai, Chennai',
  'upvote_count': 12,
  'zone_id': 'a1b2c3d4-0000-4000-8000-000000000001',
  'department_id': 'a1b2c3d4-0000-4000-8000-000000000002',
  'assigned_to_id': null,
  'resolved_at': null,
  'created_at': '2026-09-09T08:00:00Z',
  'updated_at': '2026-09-09T09:30:00Z',
};

Map<String, dynamic> issueDetailJson() => {
  ...issueSummaryJson(status: 'IN_PROGRESS'),
  'assigned_at': '2026-09-09T09:30:00Z',
  'images': [
    {
      'id': '11111111-1111-4111-8111-111111111111',
      'cdn_url': '/media/issues/$issueId/abc.jpg',
      'image_type': 'REPORT',
      'created_at': '2026-09-09T08:00:01Z',
    },
    {
      'id': '22222222-2222-4222-8222-222222222222',
      'cdn_url': 'https://cdn.weft.city/proof.jpg',
      'image_type': 'RESOLUTION_PROOF',
      'created_at': '2026-09-10T08:00:01Z',
    },
  ],
  // Newest first, as the API returns it.
  'status_history': [
    {
      'id': '33333333-3333-4333-8333-333333333333',
      'previous_status': 'REPORTED',
      'new_status': 'IN_PROGRESS',
      'changed_by_id': '44444444-4444-4444-8444-444444444444',
      'note': 'Crew dispatched',
      'created_at': '2026-09-09T09:30:00Z',
    },
    {
      'id': '55555555-5555-4555-8555-555555555555',
      'previous_status': null,
      'new_status': 'REPORTED',
      'changed_by_id': null,
      'note': null,
      'created_at': '2026-09-09T08:00:00Z',
    },
  ],
};

Map<String, dynamic> nearbyIssueJson() => {
  ...issueSummaryJson(),
  'distance_m': 142.37,
};

Map<String, dynamic> paginatedJson(List<Map<String, dynamic>> items) => {
  'items': items,
  'total': 41,
  'page': 2,
  'page_size': 20,
  'total_pages': 3,
};

Map<String, dynamic> createIssueResponseJson() => {
  'issue_id': issueId,
  'issue_number': 'ISS-2026-K7QD3M8XPZ',
  'status': 'REPORTED',
  'category': 'GARBAGE_ACCUMULATION',
  'latitude': 13.08,
  'longitude': 80.27,
  'address_text': null,
  'zone_id': null,
  'department_id': 'a1b2c3d4-0000-4000-8000-000000000002',
  'image_url': '/media/issues/$issueId/first.jpg',
  'images': [
    {
      'id': '11111111-1111-4111-8111-111111111111',
      'cdn_url': '/media/issues/$issueId/first.jpg',
      'image_type': 'REPORT',
      'created_at': '2026-09-09T08:00:01Z',
    },
  ],
  'created_at': '2026-09-09T08:00:00Z',
};

Map<String, dynamic> upvoteResponseJson() => {
  'issue_id': issueId,
  'user_id': userId,
  'upvote_count': 13,
  'created_at': '2026-09-09T10:00:00Z',
};

/// The Phase 0 mock in weft-backend/app/routers/notifications.py.
Map<String, dynamic> notificationsMockJson() => {
  'items': [
    {
      'id': 'notif-uuid-001',
      'type': 'STATUS_CHANGE',
      'channel': 'PUSH',
      'title': 'Issue Updated',
      'body': 'Your reported pothole on Anna Salai is now In Progress.',
      'issue_id': '550e8400-e29b-41d4-a716-446655440000',
      'is_read': false,
      'created_at': '2026-07-02T10:30:00Z',
    },
  ],
  'total': 1,
  'page': 1,
  'page_size': 20,
  'total_pages': 1,
};
