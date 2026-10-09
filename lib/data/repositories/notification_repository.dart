/// `/notifications` endpoints (authenticated).
///
// TODO(contract): confirm against B-NOTIF — all three endpoints are Phase 0
// mocks today (weft-backend/app/routers/notifications.py) and openapi.yaml
// declares no response schemas. Shapes below follow the mocks:
//   GET   /notifications            → PaginatedResponse[AppNotification]
//   PATCH /notifications/{id}/read  → {"id", "is_read": true}  (ignored)
//   PATCH /notifications/read-all   → {"updated_count": int}
// Assumed query params: page, page_size (same as GET /issues).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_providers.dart';
import '../models/app_notification.dart';
import '../models/paginated_response.dart';
import 'api_call.dart';

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<AppNotification>> list({
    int page = 1,
    int pageSize = 20,
  }) => apiCall(() async {
    final res = await _dio.get<Object?>(
      '/notifications',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return PaginatedResponse.fromJson(
      asJsonObject(res.data),
      AppNotification.fromJson,
    );
  });

  Future<void> markRead(String notificationId) => apiCall(() async {
    await _dio.patch<Object?>('/notifications/$notificationId/read');
  });

  /// Returns how many were updated (0 if the server omits the count).
  Future<int> markAllRead() => apiCall(() async {
    final res = await _dio.patch<Object?>('/notifications/read-all');
    final data = res.data;
    if (data is Map && data['updated_count'] is num) {
      return (data['updated_count'] as num).toInt();
    }
    return 0;
  });
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(dioProvider)),
);
