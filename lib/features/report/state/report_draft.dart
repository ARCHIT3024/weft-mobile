/// Shared state for the 3-step report flow — OWNER: F-REPORT (skeleton by
/// F-CORE). One draft lives for the whole flow (photo → category → details →
/// submit); it is NOT autoDispose so stepping between screens keeps it.
/// Call `reset()` after a successful submit or when the user abandons.
///
// TODO(task 2.12–2.20): F-REPORT fills this in — compression results,
// GPS/manual pin, reverse-geocoded address, captcha token, offline (Hive)
// persistence (task 2.20), submission status.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/enums.dart';
import '../../../data/repositories/issue_repository.dart';

@immutable
class ReportDraft {
  const ReportDraft({
    this.photoPaths = const [],
    this.category,
    this.latitude,
    this.longitude,
    this.addressText,
    this.description = '',
  });

  /// Local file paths of (compressed) photos, ≤ AppConstants.maxImagesPerIssue.
  final List<String> photoPaths;
  final IssueCategory? category;
  final double? latitude;
  final double? longitude;
  final String? addressText;

  /// ≤ AppConstants.maxDescriptionLength.
  final String description;

  bool get hasLocation => latitude != null && longitude != null;
  bool get isReadyToSubmit => category != null && hasLocation;

  ReportDraft copyWith({
    List<String>? photoPaths,
    IssueCategory? category,
    double? latitude,
    double? longitude,
    String? addressText,
    String? description,
  }) => ReportDraft(
    photoPaths: photoPaths ?? this.photoPaths,
    category: category ?? this.category,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    addressText: addressText ?? this.addressText,
    description: description ?? this.description,
  );

  /// Builds the `POST /issues` payload. Requires [isReadyToSubmit].
  CreateIssueInput toInput({String? captchaToken}) {
    assert(isReadyToSubmit, 'ReportDraft is incomplete');
    return CreateIssueInput(
      category: category!,
      latitude: latitude!,
      longitude: longitude!,
      description: description.trim().isEmpty ? null : description.trim(),
      addressText: addressText,
      images: [for (final p in photoPaths) ImageUpload.fromPath(p)],
      captchaToken: captchaToken,
    );
  }
}

class ReportDraftController extends Notifier<ReportDraft> {
  @override
  ReportDraft build() => const ReportDraft();

  void setPhotos(List<String> paths) =>
      state = state.copyWith(photoPaths: List.unmodifiable(paths));

  void setCategory(IssueCategory category) =>
      state = state.copyWith(category: category);

  void setLocation({
    required double latitude,
    required double longitude,
    String? addressText,
  }) => state = state.copyWith(
    latitude: latitude,
    longitude: longitude,
    addressText: addressText,
  );

  void setDescription(String description) =>
      state = state.copyWith(description: description);

  void reset() => state = const ReportDraft();
}

final reportDraftProvider =
    NotifierProvider<ReportDraftController, ReportDraft>(
      ReportDraftController.new,
    );
