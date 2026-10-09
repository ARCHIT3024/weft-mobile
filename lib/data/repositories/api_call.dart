/// Shared error translation for repositories: every repository method throws
/// [ApiException] and nothing else, so UI code has exactly one error type.
library;

import 'package:dio/dio.dart';

import '../models/api_error.dart';

Future<T> apiCall<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw ApiException.fromDioException(e);
  } on FormatException catch (e) {
    // The server answered 2xx with a body we cannot parse: a contract drift.
    throw ApiException(
      kind: ApiErrorKind.unknown,
      code: 'INVALID_RESPONSE',
      message: 'Unexpected response from the server.',
      details: {'reason': e.message},
    );
  } on TypeError catch (e) {
    throw ApiException(
      kind: ApiErrorKind.unknown,
      code: 'INVALID_RESPONSE',
      message: 'Unexpected response from the server.',
      details: {'reason': e.toString()},
    );
  }
}

/// Casts a decoded JSON body to an object map, or throws [FormatException].
Map<String, dynamic> asJsonObject(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw const FormatException('Expected a JSON object');
}

List<Map<String, dynamic>> asJsonList(Object? data) {
  if (data is List) {
    return data.map(asJsonObject).toList(growable: false);
  }
  throw const FormatException('Expected a JSON array');
}
