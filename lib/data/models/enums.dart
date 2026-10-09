/// Wire enums, mirroring `weft-backend/app/schemas/*.py` exactly.
///
/// Every enum carries its wire string in [wire] and a forgiving `fromWire`:
/// a value this build predates must not crash a list parse. Unknown values map
/// to an explicit `unknown` member (status/role/notification type) or to
/// [IssueCategory.other] (category), and are never sent back to the server.
library;

/// `IssueCategory` in schemas/issue.py (also the `issue_category` PG enum).
enum IssueCategory {
  pothole('POTHOLE'),
  garbageAccumulation('GARBAGE_ACCUMULATION'),
  waterLogging('WATER_LOGGING'),
  brokenStreetLight('BROKEN_STREET_LIGHT'),
  damagedFootpath('DAMAGED_FOOTPATH'),
  sewageOverflow('SEWAGE_OVERFLOW'),
  other('OTHER');

  const IssueCategory(this.wire);
  final String wire;

  static IssueCategory fromWire(String? value) {
    for (final c in values) {
      if (c.wire == value) return c;
    }
    return IssueCategory.other;
  }
}

/// `IssueStatus` in schemas/issue.py. Legal transitions (server-enforced,
/// D-12): REPORTED → {IN_PROGRESS, RESOLVED, REJECTED}; IN_PROGRESS →
/// {RESOLVED, REJECTED}; RESOLVED → {IN_PROGRESS}; REJECTED → {} (terminal).
enum IssueStatus {
  reported('REPORTED'),
  inProgress('IN_PROGRESS'),
  resolved('RESOLVED'),
  rejected('REJECTED'),

  /// A status this build does not know. Display neutrally; never send.
  unknown('UNKNOWN');

  const IssueStatus(this.wire);
  final String wire;

  /// Statuses a citizen can actually filter by / see (excludes [unknown]).
  static const List<IssueStatus> known = [
    reported,
    inProgress,
    resolved,
    rejected,
  ];

  static IssueStatus fromWire(String? value) {
    for (final s in known) {
      if (s.wire == value) return s;
    }
    return IssueStatus.unknown;
  }

  static IssueStatus? fromWireOrNull(String? value) =>
      value == null ? null : fromWire(value);

  /// PRD US-004: citizens cannot upvote resolved issues; rejected ones are
  /// closed too. (The server is the authority.)
  bool get isOpen => this == reported || this == inProgress;
}

/// `ImageType` in schemas/issue.py.
enum ImageType {
  report('REPORT'),
  resolutionProof('RESOLUTION_PROOF');

  const ImageType(this.wire);
  final String wire;

  static ImageType fromWire(String? value) =>
      value == resolutionProof.wire ? resolutionProof : report;
}

/// `UserRole` in schemas/user.py.
enum UserRole {
  citizen('CITIZEN'),
  authority('AUTHORITY'),
  admin('ADMIN'),
  unknown('UNKNOWN');

  const UserRole(this.wire);
  final String wire;

  static UserRole fromWire(String? value) {
    for (final r in values) {
      if (r.wire == value) return r;
    }
    return UserRole.unknown;
  }
}

/// `notification_type` PG enum (05_weft_backend_schema.md §2).
// TODO(contract): confirm against B-NOTIF — notifications schema not yet in
// weft-backend/app/schemas; values taken from the schema doc + Phase 0 mock.
enum NotificationType {
  statusChange('STATUS_CHANGE'),
  issueAssigned('ISSUE_ASSIGNED'),
  upvoteMilestone('UPVOTE_MILESTONE'),
  gamificationReward('GAMIFICATION_REWARD'),
  system('SYSTEM'),
  unknown('UNKNOWN');

  const NotificationType(this.wire);
  final String wire;

  static NotificationType fromWire(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return NotificationType.unknown;
  }
}
