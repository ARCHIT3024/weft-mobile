import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A recorded request, with its body bytes (for multipart assertions).
class RecordedRequest {
  RecordedRequest(this.options, this.body)
    // Snapshot: Dio replays reuse (and mutate) the same RequestOptions.
    : authorization = options.headers['Authorization'] as String?,
      uri = options.uri,
      method = options.method,
      path = options.path;

  final RequestOptions options;
  final List<int> body;
  final String? authorization;
  final Uri uri;
  final String method;
  final String path;

  String get bodyText => utf8.decode(body, allowMalformed: true);
}

typedef FakeHandler = Future<ResponseBody> Function(RecordedRequest request);

/// Scriptable Dio adapter: every request is recorded and answered by
/// [handler]. No sockets are opened.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  FakeHandler handler;
  final List<RecordedRequest> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        body.addAll(chunk);
      }
    }
    final recorded = RecordedRequest(options, body);
    requests.add(recorded);
    return handler(recorded);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object? data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody emptyResponse([int status = 204]) =>
    ResponseBody.fromString('', status);

Map<String, dynamic> errorEnvelope(
  String code,
  String message, [
  Map<String, dynamic> details = const {},
]) => {
  'error': {'code': code, 'message': message, 'details': details},
};

/// Dio pointed at a fake host with [adapter].
Dio fakeDio(FakeHttpAdapter adapter, {String baseUrl = 'http://api.test/v1'}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {'Content-Type': 'application/json'},
    ),
  )..httpClientAdapter = adapter;
}

/// Lets queued microtasks/timers-at-zero run.
Future<void> flushAsync([int times = 20]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
