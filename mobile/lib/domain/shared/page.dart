// Defines a generic Page<T> for paginated data responses from repositories.

import 'package:flutter/foundation.dart';

/// A page of items from a paginated data source.
@immutable
class Page<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const Page({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasNextPage => (page + 1) * pageSize < totalCount;

  int get totalPages => (totalCount / pageSize).ceil();

  bool get isEmpty => items.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Page<T> &&
          other.totalCount == totalCount &&
          other.page == page &&
          other.pageSize == pageSize);

  @override
  int get hashCode => Object.hash(totalCount, page, pageSize);

  @override
  String toString() =>
      'Page(page: $page, pageSize: $pageSize, totalCount: $totalCount, hasNextPage: $hasNextPage)';
}
