/// Riverpod wiring for the HTTP layer.
///
///   tokenStorageProvider (core/storage) ─┐
///   sessionEventsProvider ───────────────┼─> apiClientProvider ─> dioProvider
///                                        │                         │
///                       repositories (data/repositories/*) <───────┘
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/token_storage.dart';
import '../services/api_client.dart';

/// Broadcasts "the server rejected our refresh token" so auth state can log
/// the user out without the data layer depending on the auth feature.
class SessionEvents {
  final StreamController<void> _expired = StreamController<void>.broadcast();

  Stream<void> get expired => _expired.stream;

  void notifyExpired() {
    if (!_expired.isClosed) _expired.add(null);
  }

  Future<void> dispose() => _expired.close();
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final events = ref.watch(sessionEventsProvider);
  return ApiClient(
    storage: ref.watch(tokenStorageProvider),
    onSessionExpired: events.notifyExpired,
  );
});

/// The authenticated Dio instance (JWT + refresh interceptors). Override with
/// a Dio using a fake `HttpClientAdapter` in tests.
final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);
