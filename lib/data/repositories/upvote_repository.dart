/// Upvotes — authenticated citizens only (anonymous users get 401; show
/// "Sign in to upvote" instead of calling these).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_providers.dart';
import '../models/issue.dart';
import 'api_call.dart';

class UpvoteRepository {
  UpvoteRepository(this._dio);

  final Dio _dio;

  /// `POST /issues/{id}/upvote` → 201 with the trigger-computed total.
  /// 409 `ALREADY_UPVOTED` if this account already voted — treat it as
  /// "already in the upvoted state", not as a failure.
  Future<UpvoteResponse> upvote(String issueId) => apiCall(() async {
    final res = await _dio.post<Object?>('/issues/$issueId/upvote');
    return UpvoteResponse.fromJson(asJsonObject(res.data));
  });

  /// `DELETE /issues/{id}/upvote` → 204, idempotent (withdrawing a vote never
  /// cast is also 204). No body: re-fetch the issue for the new count.
  Future<void> removeUpvote(String issueId) => apiCall(() async {
    await _dio.delete<Object?>('/issues/$issueId/upvote');
  });
}

final upvoteRepositoryProvider = Provider<UpvoteRepository>(
  (ref) => UpvoteRepository(ref.watch(dioProvider)),
);
