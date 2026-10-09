/// `/users/me` endpoints.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_language.dart';
import '../api_providers.dart';
import '../models/enums.dart';
import '../models/issue.dart';
import '../models/paginated_response.dart';
import '../models/user_profile.dart';
import 'api_call.dart';

class UserRepository {
  UserRepository(this._dio);

  final Dio _dio;

  /// `GET /users/me` (real endpoint). 401 if the token is invalid or the
  /// account was deactivated.
  Future<UserProfile> getMe() => apiCall(() async {
    final res = await _dio.get<Object?>('/users/me');
    return UserProfile.fromJson(asJsonObject(res.data));
  });

  /// `PATCH /users/me` — partial update; omitted fields are unchanged.
  ///
  // TODO(contract): confirm against B-NOTIF. Today this is a Phase 0 mock
  // returning a PARTIAL profile, so the response body is ignored and callers
  // should re-fetch with [getMe] (AuthController.refreshProfile does).
  // Field name for the push token is `fcm_token` per schemas/user.py
  // `UpdateProfileRequest` and openapi.yaml — NOT `device_token`. If B-NOTIF
  // returns a full UserProfile, change the return type to UserProfile.
  Future<void> updateMe({
    String? name,
    AppLanguage? preferredLang,
    String? fcmToken,
  }) => apiCall(() async {
    await _dio.patch<Object?>(
      '/users/me',
      data: {
        'name': ?name?.trim(),
        'preferred_lang': ?preferredLang?.code,
        'fcm_token': ?fcmToken,
      },
    );
  });

  /// `GET /users/me/reports` — the caller's own issues, paginated.
  ///
  // TODO(contract): confirm against B-NOTIF. Today a Phase 0 mock that always
  // returns an empty page and ignores query params. Assumed: same
  // `PaginatedResponse[IssueSummary]` shape as `GET /issues` (openapi.yaml
  // says PaginatedIssueResponse) and the same `page`/`page_size`/`status`
  // query params as `GET /issues`.
  Future<PaginatedResponse<IssueSummary>> getMyReports({
    int page = 1,
    int pageSize = 20,
    List<IssueStatus>? statuses,
  }) => apiCall(() async {
    final res = await _dio.get<Object?>(
      '/users/me/reports',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (statuses != null && statuses.isNotEmpty)
          'status': statuses.map((s) => s.wire).toList(),
      },
      options: Options(listFormat: ListFormat.multi),
    );
    return PaginatedResponse.fromJson(
      asJsonObject(res.data),
      IssueSummary.fromJson,
    );
  });
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(dioProvider)),
);
