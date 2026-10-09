/// `PaginatedResponse[T]` — weft-backend/app/schemas/common.py.
library;

import 'package:equatable/equatable.dart';

import 'json_utils.dart';

class PaginatedResponse<T> extends Equatable {
  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(Json json, T Function(Json) parseItem) =>
      PaginatedResponse<T>(
        items: requireList(json, 'items', parseItem),
        total: requireInt(json, 'total'),
        page: requireInt(json, 'page'),
        pageSize: requireInt(json, 'page_size'),
        totalPages: requireInt(json, 'total_pages'),
      );

  factory PaginatedResponse.empty() => PaginatedResponse<T>(
    items: const [],
    total: 0,
    page: 1,
    pageSize: 20,
    totalPages: 1,
  );

  final List<T> items;

  /// Total matching items across all pages.
  final int total;

  /// 1-indexed.
  final int page;
  final int pageSize;

  /// Always ≥ 1, even when [total] is 0 (server rule).
  final int totalPages;

  bool get hasNextPage => page < totalPages;
  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items, total, page, pageSize, totalPages];
}
