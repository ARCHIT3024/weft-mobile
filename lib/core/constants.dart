/// Weft Mobile — Crowdsourced Civic Issue Reporting
///
/// App constants: API URLs, design tokens, thresholds.
library;

class AppConstants {
  AppConstants._();

  // ── API ──────────────────────────────────────────────────────────
  static const String appName = 'Weft';
  static const String apiBaseUrlDev = 'http://10.0.2.2:8000/v1'; // Android emulator → localhost
  static const String apiBaseUrlStaging = 'https://api-staging.weft.city/v1';
  static const String apiBaseUrlProd = 'https://api.weft.city/v1';

  /// Current environment API URL — use EnvConfig.apiBaseUrl instead.
  /// This getter is kept for backward compat but delegates to env_config.
  static String get apiBaseUrl => apiBaseUrlDev;

  // ── Map ──────────────────────────────────────────────────────────
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmAttribution = '© OpenStreetMap contributors';
  static const double defaultLat = 13.0827; // Chennai
  static const double defaultLng = 80.2707;
  static const double defaultZoom = 13.0;
  static const double defaultRadius = 2000; // metres

  // ── Auth ─────────────────────────────────────────────────────────
  static const String accessTokenKey = 'weft_access_token';
  static const String refreshTokenKey = 'weft_refresh_token';

  // ── Rate Limits ─────────────────────────────────────────────────
  static const int maxIssuesPerHour = 10;
  static const int maxAnonymousPerHour = 3;

  // ── Image ───────────────────────────────────────────────────────
  static const int maxImageWidth = 1200;
  static const int maxImageHeight = 1200;
  static const int maxImageSizeBytes = 1024 * 1024; // 1 MB
}
