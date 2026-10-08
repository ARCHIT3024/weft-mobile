/// Weft environment / flavour configuration.
///
/// Usage:
///   flutter run --dart-define=WEFT_ENV=dev
///   flutter run --dart-define=WEFT_ENV=staging
///   flutter run --dart-define=WEFT_ENV=prod
library;

import 'constants.dart';

enum WeftEnvironment { dev, staging, prod }

class EnvConfig {
  EnvConfig._();

  static const String _envString = String.fromEnvironment(
    'WEFT_ENV',
    defaultValue: 'dev',
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

  static String get apiBaseUrl {
    switch (current) {
      case WeftEnvironment.dev:
        return AppConstants.apiBaseUrlDev;
      case WeftEnvironment.staging:
        return AppConstants.apiBaseUrlStaging;
      case WeftEnvironment.prod:
        return AppConstants.apiBaseUrlProd;
    }
  }

  static String get envName => _envString;

  static bool get isDev => current == WeftEnvironment.dev;
  static bool get isStaging => current == WeftEnvironment.staging;
  static bool get isProd => current == WeftEnvironment.prod;
}
