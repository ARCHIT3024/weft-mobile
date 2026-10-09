import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weft_mobile/core/env_config.dart';
import 'package:weft_mobile/core/media_url.dart';

void main() {
  group('resolveMediaUrl (mirrors weft-web/src/lib/media.ts)', () {
    const base = 'http://10.0.2.2:8000/v1';

    test('root-relative path joins the API origin, dropping /v1', () {
      expect(
        resolveMediaUrl('/media/issues/abc/1.jpg', apiBaseUrl: base),
        'http://10.0.2.2:8000/media/issues/abc/1.jpg',
      );
    });

    test('relative path without leading slash gets one', () {
      expect(
        resolveMediaUrl('media/x.jpg', apiBaseUrl: base),
        'http://10.0.2.2:8000/media/x.jpg',
      );
    });

    test('absolute http(s) and data: URLs pass through untouched', () {
      for (final url in [
        'https://cdn.weft.city/issues/1.jpg',
        'http://example.com/a.png',
        'HTTPS://CDN.WEFT.CITY/X.JPG',
        'data:image/png;base64,AAAA',
      ]) {
        expect(resolveMediaUrl(url, apiBaseUrl: base), url);
      }
    });

    test('protocol-relative URL borrows the API scheme', () {
      expect(
        resolveMediaUrl(
          '//cdn.weft.city/a.jpg',
          apiBaseUrl: 'https://api.weft.city/v1',
        ),
        'https://cdn.weft.city/a.jpg',
      );
    });

    test('null / empty → null', () {
      expect(resolveMediaUrl(null, apiBaseUrl: base), isNull);
      expect(resolveMediaUrl('', apiBaseUrl: base), isNull);
      expect(resolveMediaUrl('   ', apiBaseUrl: base), isNull);
    });

    test('https production origin', () {
      expect(
        resolveMediaUrl('/media/a.jpg', apiBaseUrl: 'https://api.weft.city/v1'),
        'https://api.weft.city/media/a.jpg',
      );
    });
  });

  group('EnvConfig', () {
    test('dev base URL: Android emulator alias vs localhost', () {
      expect(
        EnvConfig.devBaseUrlFor(TargetPlatform.android),
        'http://10.0.2.2:8000/v1',
      );
      expect(
        EnvConfig.devBaseUrlFor(TargetPlatform.iOS),
        'http://localhost:8000/v1',
      );
      expect(
        EnvConfig.devBaseUrlFor(TargetPlatform.android, isWeb: true),
        'http://localhost:8000/v1',
      );
    });

    test('originOf strips the path', () {
      expect(
        EnvConfig.originOf('http://10.0.2.2:8000/v1'),
        'http://10.0.2.2:8000',
      );
      expect(
        EnvConfig.originOf('https://api-staging.weft.city/v1'),
        'https://api-staging.weft.city',
      );
    });

    test('default flavour is dev', () {
      expect(EnvConfig.current, WeftEnvironment.dev);
      expect(EnvConfig.apiBaseUrl, endsWith(':8000/v1'));
    });
  });
}
