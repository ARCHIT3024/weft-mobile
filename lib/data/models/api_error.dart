/// The API error envelope and the single exception type repositories throw.
///
/// The backend emits two shapes (see weft-backend/app/core/exceptions.py and
/// FastAPI defaults):
///   * Weft errors:     `{"error": {"code", "message", "details": {}}}`
///   * FastAPI default: `{"detail": "..."}` or, for 422 validation errors,
///                      `{"detail": [{"loc": [...], "msg": "...", ...}]}`
/// [ApiException.fromDioException] normalises both, plus transport failures,
/// so UI code only ever handles [ApiException].
library;

import 'package:dio/dio.dart';

enum ApiErrorKind {
  /// No connection / DNS / socket failure. Safe to offer "retry".
  network,

  /// Connect/send/receive timeout.
  timeout,

  /// The request was cancelled by the app.
  cancelled,

  /// 4xx from the server.
  client,

  /// 5xx from the server.
  server,

  /// Response could not be understood (e.g. a contract drift).
  unknown,
}

/// Well-known `error.code` values emitted by weft-backend.
abstract final class ApiErrorCodes {
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';
  static const rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
  static const emailAlreadyRegistered = 'EMAIL_ALREADY_REGISTERED';
  static const phoneAlreadyRegistered = 'PHONE_ALREADY_REGISTERED';
  static const missingRefreshToken = 'MISSING_REFRESH_TOKEN';
  static const alreadyUpvoted = 'ALREADY_UPVOTED';
  static const captchaRequired = 'CAPTCHA_REQUIRED';
  static const captchaFailed = 'CAPTCHA_FAILED';
  static const tooManyImages = 'TOO_MANY_IMAGES';
  static const validationError = 'VALIDATION_ERROR';
}

class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.code,
    required this.message,
    this.statusCode,
    this.details = const {},
  });

  /// Parses an error response body (either envelope). Exposed for tests.
  factory ApiException.fromResponse(int? statusCode, Object? body) {
    final kind = statusCode != null && statusCode >= 500
        ? ApiErrorKind.server
        : statusCode != null && statusCode >= 400
        ? ApiErrorKind.client
        : ApiErrorKind.unknown;

    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        final details = error['details'];
        return ApiException(
          kind: kind,
          statusCode: statusCode,
          code: (error['code'] as String?) ?? _codeForStatus(statusCode),
          message:
              (error['message'] as String?) ?? _messageForStatus(statusCode),
          details: details is Map
              ? Map<String, dynamic>.from(details)
              : const {},
        );
      }
      final detail = body['detail'];
      if (detail is String) {
        return ApiException(
          kind: kind,
          statusCode: statusCode,
          code: _codeForStatus(statusCode),
          message: detail,
        );
      }
      if (detail is List) {
        // FastAPI 422: surface the first field message.
        final first = detail.isNotEmpty && detail.first is Map
            ? detail.first as Map
            : null;
        final loc = first?['loc'];
        final field = loc is List && loc.isNotEmpty
            ? loc.last.toString()
            : null;
        return ApiException(
          kind: kind,
          statusCode: statusCode,
          code: ApiErrorCodes.validationError,
          message: (first?['msg'] as String?) ?? 'The request was invalid.',
          details: {'errors': detail, 'field': ?field},
        );
      }
    }
    return ApiException(
      kind: kind,
      statusCode: statusCode,
      code: _codeForStatus(statusCode),
      message: _messageForStatus(statusCode),
    );
  }

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          kind: ApiErrorKind.timeout,
          code: 'TIMEOUT',
          message: 'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          kind: ApiErrorKind.network,
          code: 'NETWORK_ERROR',
          message: "Can't reach Weft. Check your connection and try again.",
        );
      case DioExceptionType.cancel:
        return const ApiException(
          kind: ApiErrorKind.cancelled,
          code: 'CANCELLED',
          message: 'The request was cancelled.',
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final response = e.response;
        if (response == null) {
          return const ApiException(
            kind: ApiErrorKind.network,
            code: 'NETWORK_ERROR',
            message: "Can't reach Weft. Check your connection and try again.",
          );
        }
        return ApiException.fromResponse(response.statusCode, response.data);
    }
  }

  final ApiErrorKind kind;

  /// HTTP status, when the server answered.
  final int? statusCode;

  /// Machine-readable code (`error.code`), e.g. `EMAIL_ALREADY_REGISTERED`.
  final String code;

  /// Human-readable message, safe to show.
  final String message;
  final Map<String, dynamic> details;

  bool get isNetwork =>
      kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isRateLimited => statusCode == 429;

  /// From `details.retry_after_seconds` on a 429.
  int? get retryAfterSeconds {
    final v = details['retry_after_seconds'];
    return v is num ? v.toInt() : null;
  }

  static String _codeForStatus(int? status) => switch (status) {
    400 => 'BAD_REQUEST',
    401 => ApiErrorCodes.unauthorized,
    403 => ApiErrorCodes.forbidden,
    404 => ApiErrorCodes.notFound,
    409 => 'CONFLICT',
    422 => ApiErrorCodes.validationError,
    429 => ApiErrorCodes.rateLimitExceeded,
    final int s when s >= 500 => 'SERVER_ERROR',
    _ => 'UNKNOWN_ERROR',
  };

  static String _messageForStatus(int? status) => switch (status) {
    401 => 'Please sign in again.',
    403 => "You don't have permission to do that.",
    404 => "We couldn't find that.",
    429 => 'Too many requests. Please wait a moment and try again.',
    final int s when s >= 500 =>
      'Something went wrong on our side. Please try again.',
    _ => 'Something went wrong. Please try again.',
  };

  @override
  String toString() => 'ApiException($statusCode $code: $message)';
}
