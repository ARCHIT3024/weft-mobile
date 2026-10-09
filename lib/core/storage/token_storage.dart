/// Persistence for the access + refresh token pair (task 2.7).
///
/// WHY SECURE STORAGE HERE BUT MEMORY-ONLY ON THE WEB DASHBOARD (D-9):
/// `weft-web` keeps tokens in memory because a browser page that renders
/// untrusted citizen text is an XSS surface, and anything in web storage is
/// readable by an injected script. A native app has no such shared script
/// context. `flutter_secure_storage` puts the tokens in the Android Keystore-
/// backed EncryptedSharedPreferences / the iOS Keychain, which other apps
/// cannot read, and lets a citizen stay signed in across launches (the refresh
/// token lives 30 days). Tokens must never go into SharedPreferences, Hive or
/// logs.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants.dart';

abstract interface class TokenStorage {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();

  /// Always writes BOTH tokens: the backend rotates the refresh token on every
  /// refresh, so keeping an old one would end the session at the next refresh.
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clear();
}

/// Production implementation over `flutter_secure_storage`, with an in-memory
/// cache so the per-request token read does not hit the Keystore/Keychain.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;
  bool _loaded = false;
  String? _access;
  String? _refresh;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _access = await _storage.read(key: AppConstants.accessTokenKey);
    _refresh = await _storage.read(key: AppConstants.refreshTokenKey);
    _loaded = true;
  }

  @override
  Future<String?> readAccessToken() async {
    await _ensureLoaded();
    return _access;
  }

  @override
  Future<String?> readRefreshToken() async {
    await _ensureLoaded();
    return _refresh;
  }

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
    _loaded = true;
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: refreshToken,
    );
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _loaded = true;
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }
}

/// Non-persistent implementation, for tests and widget previews.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage({String? accessToken, String? refreshToken})
    : _access = accessToken,
      _refresh = refreshToken;

  String? _access;
  String? _refresh;

  @override
  Future<String?> readAccessToken() async => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

/// Override with [InMemoryTokenStorage] in tests.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);
