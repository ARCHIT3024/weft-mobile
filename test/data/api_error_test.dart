import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weft_mobile/data/models/api_error.dart';

void main() {
  test('parses the Weft error envelope', () {
    final e = ApiException.fromResponse(409, {
      'error': {
        'code': 'EMAIL_ALREADY_REGISTERED',
        'message': 'Email already registered',
        'details': {},
      },
    });
    expect(e.kind, ApiErrorKind.client);
    expect(e.code, ApiErrorCodes.emailAlreadyRegistered);
    expect(e.message, 'Email already registered');
    expect(e.isConflict, isTrue);
  });

  test('429 exposes retry_after_seconds', () {
    final e = ApiException.fromResponse(429, {
      'error': {
        'code': 'RATE_LIMIT_EXCEEDED',
        'message': 'You have exceeded the maximum of 5 requests per minute.',
        'details': {'limit': 5, 'window': 'minute', 'retry_after_seconds': 42},
      },
    });
    expect(e.isRateLimited, isTrue);
    expect(e.retryAfterSeconds, 42);
  });

  test('parses FastAPI {"detail": "..."}', () {
    final e = ApiException.fromResponse(404, {'detail': 'Not Found'});
    expect(e.code, ApiErrorCodes.notFound);
    expect(e.message, 'Not Found');
  });

  test('parses FastAPI 422 validation list', () {
    final e = ApiException.fromResponse(422, {
      'detail': [
        {
          'type': 'string_too_short',
          'loc': ['body', 'password'],
          'msg': 'String should have at least 8 characters',
        },
      ],
    });
    expect(e.code, ApiErrorCodes.validationError);
    expect(e.message, 'String should have at least 8 characters');
    expect(e.details['field'], 'password');
  });

  test('non-JSON 5xx body falls back to a generic server error', () {
    final e = ApiException.fromResponse(502, '<html>Bad gateway</html>');
    expect(e.kind, ApiErrorKind.server);
    expect(e.code, 'SERVER_ERROR');
  });

  test('connection error maps to network kind', () {
    final e = ApiException.fromDioException(
      DioException.connectionError(
        requestOptions: RequestOptions(path: '/x'),
        reason: 'refused',
      ),
    );
    expect(e.kind, ApiErrorKind.network);
    expect(e.isNetwork, isTrue);
  });
}
