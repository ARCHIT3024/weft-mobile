/// Resolve a media URL returned by the API into one the app can fetch.
///
/// The API returns image paths root-relative — `/media/issues/<id>/<uuid>.jpg`
/// (local-disk storage, D-11). Those bytes are served by the API host, so the
/// path must be joined to the API **origin** (scheme + host + port, with the
/// `/v1` prefix stripped). In production the API is expected to return an
/// absolute CDN URL, which passes through untouched.
///
/// Mirrors `weft-web/src/lib/media.ts::mediaUrl`.
library;

import 'env_config.dart';

/// Returns `null` for a null/empty input. [apiBaseUrl] defaults to
/// [EnvConfig.apiBaseUrl]; pass it explicitly in tests.
String? resolveMediaUrl(String? url, {String? apiBaseUrl}) {
  if (url == null) return null;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('data:')) {
    return trimmed;
  }
  final origin = EnvConfig.originOf(apiBaseUrl ?? EnvConfig.apiBaseUrl);
  // Protocol-relative (`//cdn.example.com/x.jpg`) → borrow the API's scheme.
  if (trimmed.startsWith('//')) {
    final scheme = Uri.parse(origin).scheme;
    return '${scheme.isEmpty ? 'https' : scheme}:$trimmed';
  }
  return trimmed.startsWith('/') ? '$origin$trimmed' : '$origin/$trimmed';
}
