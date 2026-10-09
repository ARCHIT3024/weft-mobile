/// Weft environment / flavour configuration.
///
/// Usage:
///   flutter run --dart-define=WEFT_ENV=dev
///   flutter run --dart-define=WEFT_ENV=staging
///   flutter run --dart-define=WEFT_ENV=prod
///
/// Optional override (e.g. a physical phone talking to a laptop on the LAN):
///   flutter run --dart-define=WEFT_API_BASE_URL=http://192.168.1.20:8000/v1
///
/// Dev default (task 2.10 — there is no staging deployment yet):
///   * Android  → http://10.0.2.2:8000/v1 (the emulator's alias for the host)
///   * anything else (iOS simulator, desktop, web) → http://localhost:8000/v1
library;

import 'package:flutter/foundation.dart';

import 'constants.dart';

enum WeftEnvironment { dev, staging, prod }

class EnvConfig {
  EnvConfig._();

  static const String _envString = String.fromEnvironment(
    'WEFT_ENV',
    defaultValue: 'dev',
  );

  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'WEFT_API_BASE_URL',
  );

  static WeftEnvironment get current {
    switch (_envString) {
      case 'staging':
        return WeftEnvironment.staging;
      case 'prod':
        return WeftEnvironment.prod;
      default:
        return WeftEnvironment.dev;
    }
  }

  /// The API base URL **including** the `/v1` prefix. Single source of truth:
  /// both the main Dio instance and the token-refresh call use this.
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    switch (current) {
      case WeftEnvironment.dev:
        return devBaseUrlFor(defaultTargetPlatform, isWeb: kIsWeb);
      case WeftEnvironment.staging:
        return AppConstants.apiBaseUrlStaging;
      case WeftEnvironment.prod:
        return AppConstants.apiBaseUrlProd;
    }
  }

  /// Dev URL for a given platform. Exposed for tests.
  @visibleForTesting
  static String devBaseUrlFor(TargetPlatform platform, {bool isWeb = false}) {
    if (!isWeb && platform == TargetPlatform.android) {
      return AppConstants.apiBaseUrlDevAndroidEmulator;
    }
    return AppConstants.apiBaseUrlDevLocalhost;
  }

  /// Scheme + host + port of the API with the path stripped — the origin that
  /// root-relative media URLs (`/media/...`) resolve against.
  static String get apiOrigin => originOf(apiBaseUrl);

  static String originOf(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    return uri.hasAuthority ? uri.origin : baseUrl;
  }

  static String get envName => _envString;

  static bool get isDev => current == WeftEnvironment.dev;
  static bool get isStaging => current == WeftEnvironment.staging;
  static bool get isProd => current == WeftEnvironment.prod;
}
