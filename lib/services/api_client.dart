/// Dio HTTP client configured for the Weft API.
///
/// Features:
/// - Base URL from AppConstants (switches per flavour)
/// - JWT Authorization header injection from secure storage
/// - 401 → automatic token refresh → retry original request
/// - Request/response logging in debug mode
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants.dart';
import '../core/env_config.dart';

class ApiClient {
  ApiClient._();

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: EnvConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  static const _storage = FlutterSecureStorage();
  static bool _isRefreshing = false;
  static final List<Function(String)> _retryQueue = [];

  /// Initialise interceptors. Call once in main().
  static void init() {
    // ── Request: attach JWT ─────────────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },

      // ── Response: pass through ────────────────────────────────
      onResponse: (response, handler) => handler.next(response),

      // ── Error: handle 401 with token refresh ──────────────────
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshToken = await _storage.read(
              key: AppConstants.refreshTokenKey,
            );
            if (refreshToken == null) {
              return handler.reject(error);
            }

            final response = await Dio().post(
              '${AppConstants.apiBaseUrl}/auth/refresh',
              data: {'refresh_token': refreshToken},
            );

            final newAccessToken = response.data['access_token'] as String;
            final newRefreshToken = response.data['refresh_token'] as String;

            await _storage.write(
              key: AppConstants.accessTokenKey,
              value: newAccessToken,
            );
            await _storage.write(
              key: AppConstants.refreshTokenKey,
              value: newRefreshToken,
            );

            // Retry queued requests
            for (final retry in _retryQueue) {
              retry(newAccessToken);
            }
            _retryQueue.clear();

            // Retry the original request
            error.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final retryResponse = await _dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          } catch (e) {
            // Refresh failed — clear tokens, user must re-login
            await _storage.delete(key: AppConstants.accessTokenKey);
            await _storage.delete(key: AppConstants.refreshTokenKey);
            return handler.reject(error);
          } finally {
            _isRefreshing = false;
          }
        }
        return handler.next(error);
      },
    ));

    // ── Logging (debug only) ────────────────────────────────────
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  /// Access the configured Dio instance.
  static Dio get dio => _dio;
}
