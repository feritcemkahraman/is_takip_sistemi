class SearchFilter {
  final String? searchText;
  final List<String>? departments;
  final List<String>? statuses;
  final List<String>? priorities;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? assignedTo;
  final String? createdBy;
  final bool? isCompleted;
  final String? type; // task, meeting, document
  final List<String>? tags;
  final String? sortBy;
  final bool? sortAscending;

  SearchFilter({
    this.searchText,
    this.departments,
    this.statuses,
    this.priorities,
    this.startDate,
    this.endDate,
    this.assignedTo,
    this.createdBy,
    this.isCompleted,
    this.type,
    this.tags,
    this.sortBy,
    this.sortAscending,
  });

  // Boş filtre kontrolü
  bool get isEmpty {
    return searchText == null &&
        departments == null &&
        statuses == null &&
        priorities == null &&
        startDate == null &&
        endDate == null &&
        assignedTo == null &&
        createdBy == null &&
        isCompleted == null &&
        type == null &&
        tags == null &&
        sortBy == null;
  }

  // Filtre tiplerini kontrol et
  bool hasDateFilter() => startDate != null || endDate != null;
  bool hasStatusFilter() => statuses != null && statuses!.isNotEmpty;
  bool hasDepartmentFilter() => departments != null && departments!.isNotEmpty;
  bool hasPriorityFilter() => priorities != null && priorities!.isNotEmpty;
  bool hasTagFilter() => tags != null && tags!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'searchText': searchText,
      'departments': departments,
      'statuses': statuses,
      'priorities': priorities,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'isCompleted': isCompleted,
      'type': type,
      'tags': tags,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
    };
  }

  factory SearchFilter.fromMap(Map<String, dynamic> map) {
    return SearchFilter(
      searchText: map['searchText'] as String?,
      departments: map['departments'] != null
          ? List<String>.from(map['departments'])
          : null,
      statuses:
          map['statuses'] != null ? List<String>.from(map['statuses']) : null,
      priorities:
          map['priorities'] != null ? List<String>.from(map['priorities']) : null,
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'])
          : null,
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
      assignedTo: map['assignedTo'] as String?,
      createdBy: map['createdBy'] as String?,
      isCompleted: map['isCompleted'] as bool?,
      type: map['type'] as String?,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      sortBy: map['sortBy'] as String?,
      sortAscending: map['sortAscending'] as bool?,
    );
  }

  SearchFilter copyWith({
    String? searchText,
    List<String>? departments,
    List<String>? statuses,
    List<String>? priorities,
    DateTime? startDate,
    DateTime? endDate,
    String? assignedTo,
    String? createdBy,
    bool? isCompleted,
    String? type,
    List<String>? tags,
    String? sortBy,
    bool? sortAscending,
  }) {
    return SearchFilter(
      searchText: searchText ?? this.searchText,
      departments: departments ?? this.departments,
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  // Filtreyi temizle
  SearchFilter clear() {
    return SearchFilter();
  }

  // Belirli bir filtreyi kaldır
  SearchFilter removeFilter(String filterType) {
    switch (filterType) {
      case 'searchText':
        return copyWith(searchText: null);
      case 'departments':
        return copyWith(departments: null);
      case 'statuses':
        return copyWith(statuses: null);
      case 'priorities':
        return copyWith(priorities: null);
      case 'dateRange':
        return copyWith(startDate: null, endDate: null);
      case 'assignedTo':
        return copyWith(assignedTo: null);
      case 'createdBy':
        return copyWith(createdBy: null);
      case 'isCompleted':
        return copyWith(isCompleted: null);
      case 'type':
        return copyWith(type: null);
      case 'tags':
        return copyWith(tags: null);
      case 'sort':
        return copyWith(sortBy: null, sortAscending: null);
      default:
        return this;
    }
  }
}

class SearchResult<T> {
  final List<T> items;
  final int totalCount;
  final bool hasMore;
  final String? nextPageToken;
  final SearchFilter appliedFilter;

  SearchResult({
    required this.items,
    required this.totalCount,
    this.hasMore = false,
    this.nextPageToken,
    required this.appliedFilter,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
} 