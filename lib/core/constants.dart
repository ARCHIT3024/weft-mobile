/// Weft Mobile — Crowdsourced Civic Issue Reporting
///
/// App constants: API URLs, map defaults, storage keys, thresholds.
library;

class AppConstants {
  AppConstants._();

  // ── API ──────────────────────────────────────────────────────────
  // The per-flavour base URL is chosen in `EnvConfig.apiBaseUrl` — always read
  // it from there. (A former `AppConstants.apiBaseUrl` getter that hard-coded
  // the dev URL was removed: the token-refresh call used it while Dio used
  // EnvConfig, so refresh could hit a different host per flavour — task 2.6.)
  static const String appName = 'Weft';

  /// Android emulator → host machine's localhost.
  static const String apiBaseUrlDevAndroidEmulator = 'http://10.0.2.2:8000/v1';

  /// iOS simulator / desktop / web → the machine's own localhost.
  static const String apiBaseUrlDevLocalhost = 'http://localhost:8000/v1';
  static const String apiBaseUrlStaging = 'https://api-staging.weft.city/v1';
  static const String apiBaseUrlProd = 'https://api.weft.city/v1';

  // ── Map ──────────────────────────────────────────────────────────
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttribution = '© OpenStreetMap contributors';
  static const String osmUserAgentPackageName = 'city.weft.weft_mobile';
  static const double defaultLat = 13.0827; // Chennai
  static const double defaultLng = 80.2707;
  static const double defaultZoom = 13.0;

  /// Default radius for `GET /issues/nearby`, metres (backend default 2000,
  /// backend maximum 10000).
  static const int defaultRadius = 2000;
  static const int maxRadius = 10000;

  // ── Secure storage keys (tokens) ─────────────────────────────────
  static const String accessTokenKey = 'weft_access_token';
  static const String refreshTokenKey = 'weft_refresh_token';

  // ── Shared-preferences keys (non-secret app state) ───────────────
  static const String prefOnboardingSeen = 'weft_onboarding_seen';
  static const String prefLanguageCode = 'weft_language_code';
  static const String prefAnonymousMode = 'weft_anonymous_mode';

  // ── Rate Limits (documented server-side limits, for UI copy) ─────
  static const int maxIssuesPerHour = 10;
  static const int maxAnonymousPerHour = 3;

  // ── Issue submission (mirrors weft-backend) ──────────────────────
  /// `settings.MAX_IMAGES_PER_ISSUE` in weft-backend/app/config.py.
  static const int maxImagesPerIssue = 5;

  /// `DESCRIPTION_MAX_LENGTH` in weft-backend/app/schemas/issue.py.
  static const int maxDescriptionLength = 500;

  /// `ADDRESS_MAX_LENGTH` in weft-backend/app/schemas/issue.py.
  static const int maxAddressLength = 500;

  // ── Image ───────────────────────────────────────────────────────
  static const int maxImageWidth = 1200;
  static const int maxImageHeight = 1200;
  static const int maxImageSizeBytes = 1024 * 1024; // 1 MB
}
