/// Auth endpoints: register, login, refresh, logout (+ Google, flag-gated).
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/token_storage.dart';
import '../../core/validators.dart';
import '../api_providers.dart';
import '../models/auth_tokens.dart';
import '../models/user_profile.dart';
import 'api_call.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;

  /// `POST /auth/register` → 201 [RegisterResponse]. Returns a profile, NOT
  /// tokens — call [login] next. 409 codes: `EMAIL_ALREADY_REGISTERED`,
  /// `PHONE_ALREADY_REGISTERED`.
  Future<RegisterResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) => apiCall(() async {
    final trimmedPhone = phone?.trim();
    final res = await _dio.post<Object?>(
      '/auth/register',
      data: {
        'name': name.trim(),
        'email': Validators.normaliseEmail(email),
        'password': password,
        if (trimmedPhone != null && trimmedPhone.isNotEmpty)
          'phone': trimmedPhone,
      },
    );
    return RegisterResponse.fromJson(asJsonObject(res.data));
  });

  /// `POST /auth/login` → [AuthResponse]; tokens are persisted before return.
  /// 401 = invalid email/password (deliberately indistinguishable);
  /// 429 = rate limited (5/min/IP, `retryAfterSeconds`).
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) => apiCall(() async {
    final res = await _dio.post<Object?>(
      '/auth/login',
      data: {'email': Validators.normaliseEmail(email), 'password': password},
    );
    final auth = AuthResponse.fromJson(asJsonObject(res.data));
    await _persist(auth.tokens);
    return auth;
  });

  /// `POST /auth/oauth/google`. NOT LIVE: backend task 1.4 is not built, and
  /// the UI entry point is behind `FeatureFlags.googleSignIn` (off).
  Future<AuthResponse> loginWithGoogle(String idToken) => apiCall(() async {
    final res = await _dio.post<Object?>(
      '/auth/oauth/google',
      data: {'id_token': idToken},
    );
    final auth = AuthResponse.fromJson(asJsonObject(res.data));
    await _persist(auth.tokens);
    return auth;
  });

  /// `POST /auth/refresh` — normally done automatically by `ApiClient` on a
  /// 401; exposed for explicit use. Persists the rotated pair.
  Future<AuthTokens> refresh() => apiCall(() async {
    final refreshToken = await _tokens.readRefreshToken();
    final res = await _dio.post<Object?>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final tokens = AuthTokens.fromJson(asJsonObject(res.data));
    await _persist(tokens);
    return tokens;
  });

  /// `POST /auth/logout` with `{refresh_token}` (D-3): revokes THIS device's
  /// session only; always 204. Local tokens are cleared even if the network
  /// call fails — a user who taps "Log out" must end up logged out.
  Future<void> logout() async {
    final refreshToken = await _tokens.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _dio.post<Object?>(
          '/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      }
    } on DioException {
      // Best effort: the token expires server-side within 30 days anyway.
    } finally {
      await _tokens.clear();
    }
  }

  /// Whether a session (refresh token) is stored on this device.
  Future<bool> hasStoredSession() async =>
      (await _tokens.readRefreshToken()) != null;

  Future<void> _persist(AuthTokens tokens) => _tokens.writeTokens(
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
  );
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);
