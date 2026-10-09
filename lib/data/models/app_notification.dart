/// In-app notification (`GET /notifications` items).
///
// TODO(contract): confirm against B-NOTIF. Modelled from the Phase 0 mock in
// weft-backend/app/routers/notifications.py and the `notifications` table in
// 05_weft_backend_schema.md §3.12. openapi.yaml declares no schema for it yet.
// Fields kept optional where the real endpoint may differ (channel, issue_id).
library;

import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'json_utils.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.channel,
    this.issueId,
  });

  factory AppNotification.fromJson(Json json) => AppNotification(
    id: requireString(json, 'id'),
    type: NotificationType.fromWire(optString(json, 'type')),
    channel: optString(json, 'channel'),
    title: requireString(json, 'title'),
    body: requireString(json, 'body'),
    issueId: optString(json, 'issue_id'),
    isRead: requireBool(json, 'is_read'),
    createdAt: requireDate(json, 'created_at'),
  );

  final String id;
  final NotificationType type;

  /// PUSH / IN_APP / EMAIL — informational only.
  final String? channel;
  final String title;
  final String body;

  /// Deep-link target (`/issues/{issueId}`), when the notification is about
  /// an issue.
  final String? issueId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    channel: channel,
    title: title,
    body: body,
    issueId: issueId,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    channel,
    title,
    body,
    issueId,
    isRead,
    createdAt,
  ];
}
