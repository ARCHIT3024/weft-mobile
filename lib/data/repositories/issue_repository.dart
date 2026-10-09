/// `/issues` endpoints: submit (multipart), list, nearby, detail.
///
/// Query parameter names follow the RUNNING backend (`app/routers/issues.py`),
/// which differs from openapi.yaml in three places: `radius` (not
/// `radius_m`), `sort`/`order` (not `sort_by`/`sort_dir`), and
/// `GET /issues/nearby` returns a plain JSON array (not a paginated object).
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../api_providers.dart';
import '../models/enums.dart';
import '../models/issue.dart';
import '../models/paginated_response.dart';
import 'api_call.dart';

/// One photo to upload. The backend validates by decoded content, not by
/// filename/MIME, and re-encodes to JPEG — so no content type is sent.
class ImageUpload {
  const ImageUpload.fromPath(String this.path, {this.filename}) : bytes = null;

  const ImageUpload.fromBytes(
    Uint8List this.bytes, {
    required String this.filename,
  }) : path = null;

  final String? path;
  final Uint8List? bytes;
  final String? filename;

  Future<MultipartFile> toMultipartFile() async {
    if (bytes != null) {
      return MultipartFile.fromBytes(bytes!, filename: filename ?? 'photo.jpg');
    }
    return MultipartFile.fromFile(
      path!,
      filename: filename ?? path!.split(RegExp(r'[\\/]')).last,
    );
  }
}

/// Fields of `POST /issues` (`CreateIssueRequest`, multipart/form-data).
class CreateIssueInput {
  const CreateIssueInput({
    required this.category,
    required this.latitude,
    required this.longitude,
    this.description,
    this.addressText,
    this.images = const [],
    this.captchaToken,
  });

  final IssueCategory category;
  final double latitude;
  final double longitude;

  /// ≤ 500 chars (server rule).
  final String? description;

  /// ≤ 500 chars (server rule).
  final String? addressText;

  /// ≤ 5 files (server rule; more → 400 `TOO_MANY_IMAGES`).
  final List<ImageUpload> images;

  /// reCAPTCHA token — required for ANONYMOUS submissions only when the
  /// server has `RECAPTCHA_SECRET_KEY` set (400 `CAPTCHA_REQUIRED` /
  /// `CAPTCHA_FAILED`). Unset in dev.
  final String? captchaToken;
}

/// Sort field for `GET /issues` (`IssueSortField`).
enum IssueSort {
  createdAt('created_at'),
  upvoteCount('upvote_count');

  const IssueSort(this.wire);
  final String wire;
}

/// Filters for `GET /issues`. All optional.
class IssueQuery {
  const IssueQuery({
    this.categories,
    this.statuses,
    this.zoneId,
    this.minUpvotes,
    this.fromDate,
    this.toDate,
    this.lat,
    this.lng,
    this.radius,
    this.page = 1,
    this.pageSize = 20,
    this.sort = IssueSort.createdAt,
    this.descending = true,
  });

  final List<IssueCategory>? categories;
  final List<IssueStatus>? statuses;
  final String? zoneId;
  final int? minUpvotes;
  final DateTime? fromDate;
  final DateTime? toDate;
  final double? lat;
  final double? lng;

  /// Metres, 1–10000. Only applied with [lat] + [lng].
  final int? radius;
  final int page;

  /// 1–100.
  final int pageSize;
  final IssueSort sort;
  final bool descending;

  Map<String, dynamic> toQueryParameters() => {
    if (categories != null && categories!.isNotEmpty)
      'category': categories!.map((c) => c.wire).toList(),
    if (statuses != null && statuses!.isNotEmpty)
      'status': statuses!
          .where((s) => s != IssueStatus.unknown)
          .map((s) => s.wire)
          .toList(),
    'zone_id': ?zoneId,
    'min_upvotes': ?minUpvotes,
    'from_date': ?fromDate?.toUtc().toIso8601String(),
    'to_date': ?toDate?.toUtc().toIso8601String(),
    'lat': ?lat,
    'lng': ?lng,
    'radius': ?radius,
    'page': page,
    'page_size': pageSize,
    'sort': sort.wire,
    'order': descending ? 'desc' : 'asc',
  };
}

class IssueRepository {
  IssueRepository(this._dio);

  final Dio _dio;

  /// `POST /issues` — multipart; auth OPTIONAL (anonymous → no reporter).
  /// Images go in a REPEATED `images` field. Rejected images do not fail the
  /// report; they are just absent from the response.
  Future<CreateIssueResponse> createIssue(
    CreateIssueInput input, {
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) => apiCall(() async {
    final form = FormData();
    form.fields
      ..add(MapEntry('category', input.category.wire))
      ..add(MapEntry('latitude', input.latitude.toString()))
      ..add(MapEntry('longitude', input.longitude.toString()));
    final description = input.description?.trim();
    if (description != null && description.isNotEmpty) {
      form.fields.add(MapEntry('description', description));
    }
    final address = input.addressText?.trim();
    if (address != null && address.isNotEmpty) {
      form.fields.add(MapEntry('address_text', address));
    }
    if (input.captchaToken != null) {
      form.fields.add(MapEntry('captcha_token', input.captchaToken!));
    }
    for (final image in input.images.take(AppConstants.maxImagesPerIssue)) {
      form.files.add(MapEntry('images', await image.toMultipartFile()));
    }
    final res = await _dio.post<Object?>(
      '/issues',
      data: form,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
    return CreateIssueResponse.fromJson(asJsonObject(res.data));
  });

  /// `GET /issues` — paginated, filterable.
  Future<PaginatedResponse<IssueSummary>> listIssues([
    IssueQuery query = const IssueQuery(),
  ]) => apiCall(() async {
    final res = await _dio.get<Object?>(
      '/issues',
      queryParameters: query.toQueryParameters(),
      options: Options(listFormat: ListFormat.multi),
    );
    return PaginatedResponse.fromJson(
      asJsonObject(res.data),
      IssueSummary.fromJson,
    );
  });

  /// `GET /issues/nearby` — nearest first, with server-computed distance.
  /// [radius] metres (1–10000, default 2000); [limit] 1–200 (default 50).
  Future<List<NearbyIssue>> nearbyIssues({
    required double lat,
    required double lng,
    int radius = AppConstants.defaultRadius,
    int limit = 50,
  }) => apiCall(() async {
    final res = await _dio.get<Object?>(
      '/issues/nearby',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'radius': radius,
        'limit': limit,
      },
    );
    return asJsonList(
      res.data,
    ).map(NearbyIssue.fromJson).toList(growable: false);
  });

  /// `GET /issues/{id}` — images + status history. 404 if unknown.
  Future<IssueDetail> getIssue(String id) => apiCall(() async {
    final res = await _dio.get<Object?>('/issues/$id');
    return IssueDetail.fromJson(asJsonObject(res.data));
  });
}

final issueRepositoryProvider = Provider<IssueRepository>(
  (ref) => IssueRepository(ref.watch(dioProvider)),
);
