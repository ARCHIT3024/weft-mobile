/// Dio HTTP client configured for the Weft API.
///
/// Features:
/// - Base URL from `EnvConfig.apiBaseUrl` (switches per flavour)
/// - JWT Authorization header injection from secure storage
/// - 401 → automatic token refresh → retry original request
/// - Concurrent 401s during an in-flight refresh are QUEUED and replayed once
///   the single refresh completes (task 2.6 fix (a))
/// - Request/response logging in debug mode
///
/// Changes from the Phase 0 version (task 2.6) — the interceptor design is
/// unchanged; these are the fixes:
/// (a) `_retryQueue` was declared and cleared but never appended to, so a 401
///     arriving while a refresh was in flight fell straight through to the
///     caller as a failure. It is now appended to, and every queued request is
///     replayed with the new token (or failed) when the one refresh settles.
/// (b) The refresh call used `AppConstants.apiBaseUrl` (hard-coded dev URL)
///     while Dio used `EnvConfig.apiBaseUrl`, so on staging/prod the refresh
///     would hit the wrong host. Both now use one base URL.
/// Also: the client is an injectable instance rather than a static singleton
/// (so it can be provided by Riverpod and tested with fake adapters), token
/// I/O goes through [TokenStorage], and a refresh failure notifies
/// [onSessionExpired] so auth state can log the user out (task 2.8).
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/env_config.dart';
import '../core/storage/token_storage.dart';

class ApiClient {
  ApiClient({
    required this._storage,
    String? baseUrl,
    Dio? dio,
    Dio? refreshDio,
    this.onSessionExpired,
    bool enableLogging = kDebugMode,
  }) : _dio = dio ?? Dio(_baseOptions(baseUrl ?? EnvConfig.apiBaseUrl)),
       // A separate, interceptor-free Dio for /auth/refresh: going through
       // `_dio` would re-enter the 401 handler and deadlock on the queue.
       _refreshDio =
           refreshDio ?? Dio(_baseOptions(baseUrl ?? EnvConfig.apiBaseUrl)) {
    _init(enableLogging: enableLogging);
  }

  static BaseOptions _baseOptions(String baseUrl) => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  );

  /// Marks a request that has already been replayed after a refresh, so a
  /// second 401 on it is returned to the caller instead of looping.
  static const String retriedExtraKey = 'weft_retried_after_refresh';

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStorage _storage;

  /// Called once when the refresh token is rejected by the server (expired,
  /// revoked, rotated elsewhere). Tokens have already been cleared.
  final void Function()? onSessionExpired;

  bool _isRefreshing = false;
  final List<_PendingRequest> _retryQueue = [];

  /// Access the configured Dio instance.
  Dio get dio => _dio;

  @visibleForTesting
  Dio get refreshDio => _refreshDio;

  @visibleForTesting
  int get queuedRequestCount => _retryQueue.length;

  /// Initialise interceptors. Called once from the constructor.
  void _init({required bool enableLogging}) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        // ── Request: attach JWT ─────────────────────────────────────
        onRequest: (options, handler) async {
          final token = await _storage.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },

        // ── Response: pass through ────────────────────────────────
        onResponse: (response, handler) => handler.next(response),

        // ── Error: handle 401 with token refresh ──────────────────
        onError: _onError,
      ),
    );

    // ── Logging (debug only) ────────────────────────────────────
    // Bodies are not logged: login/refresh bodies carry passwords and tokens.
    if (enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }
  }

  bool _isRefreshable(DioException error) {
    final options = error.requestOptions;
    if (error.response?.statusCode != 401) return false;
    if (options.extra[retriedExtraKey] == true) return false;
    // A 401 from an auth endpoint means bad credentials / bad refresh token,
    // never "access token expired" — refreshing would be wrong (and for
    // /auth/refresh itself, recursive).
    final path = options.path;
    if (path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/logout') ||
        path.contains('/auth/oauth/')) {
      return false;
    }
    return true;
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isRefreshable(error)) return handler.next(error);

    // Fix (a): a refresh is already in flight — queue this request; it is
    // replayed (or failed) when that refresh settles. This check and the flag
    // set below are synchronous (no await before them), so two 401s arriving
    // together can never both start a refresh.
    if (_isRefreshing) {
      _retryQueue.add(_PendingRequest(error, handler));
      return;
    }
    _isRefreshing = true;

    final String? newAccessToken;
    try {
      newAccessToken = await _obtainFreshAccessToken(error.requestOptions);
    } on DioException catch (refreshError) {
      await _settleQueue(null);
      final rejected =
          refreshError.response != null &&
          const {400, 401, 403}.contains(refreshError.response!.statusCode);
      if (rejected) {
        // The server refused the refresh token: the session is over. Clear
        // tokens and let auth state route to login. A network failure is NOT
        // a logout — the tokens may still be good when connectivity returns.
        await _storage.clear();
        onSessionExpired?.call();
      }
      return handler.next(error);
    } catch (_) {
      await _settleQueue(null);
      return handler.next(error);
    }

    if (newAccessToken == null) {
      // No refresh token at all (anonymous / signed out): nothing to refresh.
      await _settleQueue(null);
      return handler.next(error);
    }

    await _settleQueue(newAccessToken);
    await _replay(_PendingRequest(error, handler), newAccessToken);
  }

  /// Returns a usable access token, refreshing at most once. `null` when there
  /// is no refresh token. Throws [DioException] if the refresh call fails.
  Future<String?> _obtainFreshAccessToken(RequestOptions failed) async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return null;

    // Stale-token case: this request went out with an access token that has
    // since been replaced (a refresh finished between send and 401). Reuse
    // the current token instead of rotating again.
    final current = await _storage.readAccessToken();
    final sent = _bearerOf(failed);
    if (current != null && sent != null && sent != current) return current;

    // Fix (b): same base URL as `_dio` — `_refreshDio` is built from it.
    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final data = response.data ?? const <String, dynamic>{};
    final newAccessToken = data['access_token'] as String;
    final newRefreshToken = data['refresh_token'] as String;
    await _storage.writeTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );
    return newAccessToken;
  }

  /// Ends the refresh window and replays (token != null) or fails every
  /// request that queued during it.
  Future<void> _settleQueue(String? token) async {
    final queued = List<_PendingRequest>.of(_retryQueue);
    _retryQueue.clear();
    _isRefreshing = false;
    for (final pending in queued) {
      if (token == null) {
        pending.handler.next(pending.error);
      } else {
        unawaited(_replay(pending, token));
      }
    }
  }

  Future<void> _replay(_PendingRequest pending, String token) async {
    final options = pending.error.requestOptions;
    options.headers['Authorization'] = 'Bearer $token';
    options.extra[retriedExtraKey] = true;
    // A multipart body is a one-shot stream; replaying the finalised instance
    // throws. `POST /issues` from a signed-in user is exactly this case.
    final body = options.data;
    if (body is FormData) options.data = body.clone();
    try {
      final response = await _dio.fetch<dynamic>(options);
      pending.handler.resolve(response);
    } on DioException catch (e) {
      pending.handler.next(e);
    } catch (e) {
      pending.handler.next(DioException(requestOptions: options, error: e));
    }
  }

  static String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is String && header.startsWith('Bearer ')) {
      return header.substring('Bearer '.length);
    }
    return null;
  }
}

class _PendingRequest {
  _PendingRequest(this.error, this.handler);

  final DioException error;
  final ErrorInterceptorHandler handler;
}
