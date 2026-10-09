/// Issue models — weft-backend/app/schemas/issue.py (the source of truth; it
/// also matches `weft-web/src/types/issue.ts`).
///
/// * [IssueSummary]   — list item (`GET /issues`, `GET /users/me/reports`)
/// * [NearbyIssue]    — `GET /issues/nearby` item: summary + `distance_m`
/// * [IssueDetail]    — `GET /issues/{id}`: summary + images + status history
/// * [CreateIssueResponse] — `POST /issues` 201
/// * [UpvoteResponse] — `POST /issues/{id}/upvote` 201
///
/// Not present on purpose (backend decisions): `reporter_id` (anonymity is a
/// product promise), `ai_suggested_category` / `ai_confidence` (AI cut, D-2),
/// and — NOTE for F-MAP — there is no "has the current user upvoted" flag on
/// any issue response yet.
library;

import 'package:equatable/equatable.dart';

import '../../core/media_url.dart';
import 'enums.dart';
import 'json_utils.dart';

/// `IssueImageOut`. [cdnUrl] is what the API sent (root-relative `/media/...`
/// in dev); use [url] to display it.
class IssueImage extends Equatable {
  const IssueImage({
    required this.id,
    required this.cdnUrl,
    required this.imageType,
    required this.createdAt,
  });

  factory IssueImage.fromJson(Json json) => IssueImage(
    id: requireString(json, 'id'),
    cdnUrl: requireString(json, 'cdn_url'),
    imageType: ImageType.fromWire(optString(json, 'image_type')),
    createdAt: requireDate(json, 'created_at'),
  );

  final String id;
  final String cdnUrl;
  final ImageType imageType;
  final DateTime createdAt;

  /// Fetchable URL: root-relative paths resolved against the API origin.
  String get url => resolveMediaUrl(cdnUrl) ?? cdnUrl;

  Json toJson() => {
    'id': id,
    'cdn_url': cdnUrl,
    'image_type': imageType.wire,
    'created_at': dateToJson(createdAt),
  };

  @override
  List<Object?> get props => [id, cdnUrl, imageType, createdAt];
}

/// `IssueStatusHistoryEntry`. `previousStatus` is null only on the initial
/// REPORTED row. The API returns history **newest first**.
class StatusHistoryEntry extends Equatable {
  const StatusHistoryEntry({
    required this.id,
    required this.newStatus,
    required this.createdAt,
    this.previousStatus,
    this.changedById,
    this.note,
  });

  factory StatusHistoryEntry.fromJson(Json json) => StatusHistoryEntry(
    id: requireString(json, 'id'),
    previousStatus: IssueStatus.fromWireOrNull(
      optString(json, 'previous_status'),
    ),
    newStatus: IssueStatus.fromWire(optString(json, 'new_status')),
    changedById: optString(json, 'changed_by_id'),
    note: optString(json, 'note'),
    createdAt: requireDate(json, 'created_at'),
  );

  final String id;
  final IssueStatus? previousStatus;
  final IssueStatus newStatus;
  final String? changedById;
  final String? note;
  final DateTime createdAt;

  Json toJson() => {
    'id': id,
    'previous_status': previousStatus?.wire,
    'new_status': newStatus.wire,
    'changed_by_id': changedById,
    'note': note,
    'created_at': dateToJson(createdAt),
  };

  @override
  List<Object?> get props => [
    id,
    previousStatus,
    newStatus,
    changedById,
    note,
    createdAt,
  ];
}

/// `IssueSummary` — no photos, no history.
class IssueSummary extends Equatable {
  const IssueSummary({
    required this.id,
    required this.issueNumber,
    required this.category,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.upvoteCount,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.addressText,
    this.zoneId,
    this.departmentId,
    this.assignedToId,
    this.resolvedAt,
  });

  factory IssueSummary.fromJson(Json json) => IssueSummary(
    id: requireString(json, 'id'),
    issueNumber: requireString(json, 'issue_number'),
    category: IssueCategory.fromWire(optString(json, 'category')),
    description: optString(json, 'description'),
    status: IssueStatus.fromWire(optString(json, 'status')),
    latitude: requireDouble(json, 'latitude'),
    longitude: requireDouble(json, 'longitude'),
    addressText: optString(json, 'address_text'),
    upvoteCount: requireInt(json, 'upvote_count'),
    zoneId: optString(json, 'zone_id'),
    departmentId: optString(json, 'department_id'),
    assignedToId: optString(json, 'assigned_to_id'),
    resolvedAt: optDate(json, 'resolved_at'),
    createdAt: requireDate(json, 'created_at'),
    updatedAt: requireDate(json, 'updated_at'),
  );

  final String id;

  /// Human reference, e.g. `ISS-2026-K7QD3M8XPZ`.
  final String issueNumber;
  final IssueCategory category;
  final String? description;
  final IssueStatus status;
  final double latitude;
  final double longitude;
  final String? addressText;

  /// Maintained by a DB trigger — never computed client-side.
  final int upvoteCount;
  final String? zoneId;
  final String? departmentId;
  final String? assignedToId;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Json toJson() => {
    'id': id,
    'issue_number': issueNumber,
    'category': category.wire,
    'description': description,
    'status': status.wire,
    'latitude': latitude,
    'longitude': longitude,
    'address_text': addressText,
    'upvote_count': upvoteCount,
    'zone_id': zoneId,
    'department_id': departmentId,
    'assigned_to_id': assignedToId,
    'resolved_at': dateToJson(resolvedAt),
    'created_at': dateToJson(createdAt),
    'updated_at': dateToJson(updatedAt),
  };

  @override
  List<Object?> get props => [
    id,
    issueNumber,
    category,
    description,
    status,
    latitude,
    longitude,
    addressText,
    upvoteCount,
    zoneId,
    departmentId,
    assignedToId,
    resolvedAt,
    createdAt,
    updatedAt,
  ];
}

/// `NearbyIssue` — a summary plus the server-computed great-circle distance.
class NearbyIssue extends IssueSummary {
  const NearbyIssue({
    required super.id,
    required super.issueNumber,
    required super.category,
    required super.status,
    required super.latitude,
    required super.longitude,
    required super.upvoteCount,
    required super.createdAt,
    required super.updatedAt,
    required this.distanceM,
    super.description,
    super.addressText,
    super.zoneId,
    super.departmentId,
    super.assignedToId,
    super.resolvedAt,
  });

  factory NearbyIssue.fromJson(Json json) {
    final s = IssueSummary.fromJson(json);
    return NearbyIssue(
      id: s.id,
      issueNumber: s.issueNumber,
      category: s.category,
      description: s.description,
      status: s.status,
      latitude: s.latitude,
      longitude: s.longitude,
      addressText: s.addressText,
      upvoteCount: s.upvoteCount,
      zoneId: s.zoneId,
      departmentId: s.departmentId,
      assignedToId: s.assignedToId,
      resolvedAt: s.resolvedAt,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      distanceM: requireDouble(json, 'distance_m'),
    );
  }

  /// Metres from the query point (computed by PostGIS on the spheroid).
  final double distanceM;

  @override
  Json toJson() => {...super.toJson(), 'distance_m': distanceM};

  @override
  List<Object?> get props => [...super.props, distanceM];
}

/// `IssueDetail` — a summary plus photos and the full audit trail.
class IssueDetail extends IssueSummary {
  const IssueDetail({
    required super.id,
    required super.issueNumber,
    required super.category,
    required super.status,
    required super.latitude,
    required super.longitude,
    required super.upvoteCount,
    required super.createdAt,
    required super.updatedAt,
    required this.images,
    required this.statusHistory,
    super.description,
    super.addressText,
    super.zoneId,
    super.departmentId,
    super.assignedToId,
    super.resolvedAt,
    this.assignedAt,
  });

  factory IssueDetail.fromJson(Json json) {
    final s = IssueSummary.fromJson(json);
    return IssueDetail(
      id: s.id,
      issueNumber: s.issueNumber,
      category: s.category,
      description: s.description,
      status: s.status,
      latitude: s.latitude,
      longitude: s.longitude,
      addressText: s.addressText,
      upvoteCount: s.upvoteCount,
      zoneId: s.zoneId,
      departmentId: s.departmentId,
      assignedToId: s.assignedToId,
      resolvedAt: s.resolvedAt,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      assignedAt: optDate(json, 'assigned_at'),
      images: requireList(json, 'images', IssueImage.fromJson),
      statusHistory: requireList(
        json,
        'status_history',
        StatusHistoryEntry.fromJson,
      ),
    );
  }

  final DateTime? assignedAt;

  /// Report photos and resolution proofs, oldest first.
  final List<IssueImage> images;

  /// Every transition, NEWEST first (as the API returns it).
  final List<StatusHistoryEntry> statusHistory;

  List<IssueImage> get reportImages =>
      images.where((i) => i.imageType == ImageType.report).toList();

  List<IssueImage> get resolutionProofImages =>
      images.where((i) => i.imageType == ImageType.resolutionProof).toList();

  /// Oldest-first copy, convenient for a top-to-bottom timeline.
  List<StatusHistoryEntry> get timelineOldestFirst =>
      statusHistory.reversed.toList(growable: false);

  @override
  Json toJson() => {
    ...super.toJson(),
    'assigned_at': dateToJson(assignedAt),
    'images': images.map((i) => i.toJson()).toList(),
    'status_history': statusHistory.map((h) => h.toJson()).toList(),
  };

  @override
  List<Object?> get props => [
    ...super.props,
    assignedAt,
    images,
    statusHistory,
  ];
}

/// `CreateIssueResponse` (`POST /issues` 201). Not an IssueDetail: identity +
/// routing decisions. Images the server rejected are simply absent.
class CreateIssueResponse extends Equatable {
  const CreateIssueResponse({
    required this.issueId,
    required this.issueNumber,
    required this.status,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.createdAt,
    this.addressText,
    this.zoneId,
    this.departmentId,
    this.imageUrl,
  });

  factory CreateIssueResponse.fromJson(Json json) => CreateIssueResponse(
    issueId: requireString(json, 'issue_id'),
    issueNumber: requireString(json, 'issue_number'),
    status: IssueStatus.fromWire(optString(json, 'status')),
    category: IssueCategory.fromWire(optString(json, 'category')),
    latitude: requireDouble(json, 'latitude'),
    longitude: requireDouble(json, 'longitude'),
    addressText: optString(json, 'address_text'),
    zoneId: optString(json, 'zone_id'),
    departmentId: optString(json, 'department_id'),
    imageUrl: optString(json, 'image_url'),
    images: requireList(json, 'images', IssueImage.fromJson),
    createdAt: requireDate(json, 'created_at'),
  );

  final String issueId;
  final String issueNumber;
  final IssueStatus status;
  final IssueCategory category;
  final double latitude;
  final double longitude;
  final String? addressText;
  final String? zoneId;
  final String? departmentId;

  /// First stored photo as sent by the API; use [resolvedImageUrl] to show it.
  final String? imageUrl;
  final List<IssueImage> images;
  final DateTime createdAt;

  String? get resolvedImageUrl => resolveMediaUrl(imageUrl);

  @override
  List<Object?> get props => [
    issueId,
    issueNumber,
    status,
    category,
    latitude,
    longitude,
    addressText,
    zoneId,
    departmentId,
    imageUrl,
    images,
    createdAt,
  ];
}

/// `UpvoteResponse` — `upvoteCount` is the trigger-computed total.
class UpvoteResponse extends Equatable {
  const UpvoteResponse({
    required this.issueId,
    required this.userId,
    required this.upvoteCount,
    required this.createdAt,
  });

  factory UpvoteResponse.fromJson(Json json) => UpvoteResponse(
    issueId: requireString(json, 'issue_id'),
    userId: requireString(json, 'user_id'),
    upvoteCount: requireInt(json, 'upvote_count'),
    createdAt: requireDate(json, 'created_at'),
  );

  final String issueId;
  final String userId;
  final int upvoteCount;
  final DateTime createdAt;

  @override
  List<Object?> get props => [issueId, userId, upvoteCount, createdAt];
}
