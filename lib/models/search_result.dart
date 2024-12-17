import 'package:cloud_firestore/cloud_firestore.dart';

class SearchResult<T> {
  final List<T> items;
  final int totalCount;
  final String? appliedFilter;
  final Map<String, dynamic>? metadata;
  final String? nextPageToken;

  const SearchResult({
    required this.items,
    required this.totalCount,
    this.appliedFilter,
    this.metadata,
    this.nextPageToken,
  });

  Map<String, dynamic> toMap() => {
    'items': items.map((item) => (item as dynamic).toMap()).toList(),
    'totalCount': totalCount,
    'appliedFilter': appliedFilter,
    'metadata': metadata,
    'nextPageToken': nextPageToken,
  };

  factory SearchResult.fromMap(Map<String, dynamic> map, T Function(Map<String, dynamic>) fromMap) {
    return SearchResult<T>(
      items: List<T>.from(map['items']?.map((x) => fromMap(x)) ?? []),
      totalCount: map['totalCount']?.toInt() ?? 0,
      appliedFilter: map['appliedFilter'],
      metadata: map['metadata'],
      nextPageToken: map['nextPageToken'],
    );
  }

  SearchResult<T> copyWith({
    List<T>? items,
    int? totalCount,
    String? appliedFilter,
    Map<String, dynamic>? metadata,
    String? nextPageToken,
  }) {
    return SearchResult<T>(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      appliedFilter: appliedFilter ?? this.appliedFilter,
      metadata: metadata ?? this.metadata,
      nextPageToken: nextPageToken ?? this.nextPageToken,
    );
  }

  bool get hasMore => items.length < totalCount;
  
  bool get isEmpty => items.isEmpty;
  
  bool get isNotEmpty => items.isNotEmpty;
} 