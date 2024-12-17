import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:is_takip_sistemi/models/task_model.dart';

class SearchResult {
  final List<dynamic> items;
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
        'items': items.map((item) {
          if (item is TaskModel) {
            return {'type': 'task', 'data': item.toMap()};
          }
          return item;
        }).toList(),
        'totalCount': totalCount,
        'appliedFilter': appliedFilter,
        'metadata': metadata,
        'nextPageToken': nextPageToken,
      };

  factory SearchResult.fromMap(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>).map((item) {
      if (item is Map<String, dynamic> && item['type'] == 'task') {
        return TaskModel.fromMap(item['data'] as Map<String, dynamic>);
      }
      return item;
    }).toList();

    return SearchResult(
      items: items,
      totalCount: json['totalCount'] as int,
      appliedFilter: json['appliedFilter'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      nextPageToken: json['nextPageToken'] as String?,
    );
  }

  SearchResult copyWith({
    List<dynamic>? items,
    int? totalCount,
    String? appliedFilter,
    Map<String, dynamic>? metadata,
    String? nextPageToken,
  }) {
    return SearchResult(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      appliedFilter: appliedFilter ?? this.appliedFilter,
      metadata: metadata ?? this.metadata,
      nextPageToken: nextPageToken ?? this.nextPageToken,
    );
  }
}

class SearchFilter {
  final String? searchText;
  final List<String>? departments;
  final List<String>? statuses;
  final List<String>? priorities;
  final List<String>? roles;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? assignedTo;
  final String? createdBy;
  final bool? isCompleted;
  final String? type; // task, meeting, document
  final List<String>? tags;
  final String? sortBy;
  final bool? sortAscending;
  final String? query;
  final List<String>? participants;
  final String? status;
  final String? priority;

  SearchFilter({
    this.searchText,
    this.departments,
    this.statuses,
    this.priorities,
    this.roles,
    this.startDate,
    this.endDate,
    this.assignedTo,
    this.createdBy,
    this.isCompleted,
    this.type,
    this.tags,
    this.sortBy,
    this.sortAscending,
    this.query,
    this.participants,
    this.status,
    this.priority,
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
        sortBy == null &&
        query == null &&
        participants == null &&
        roles == null &&
        status == null &&
        priority == null;
  }

  // Filtre tiplerini kontrol et
  bool hasDateFilter() => startDate != null || endDate != null;
  bool hasStatusFilter() => statuses != null && statuses!.isNotEmpty;
  bool hasDepartmentFilter() => departments != null && departments!.isNotEmpty;
  bool hasPriorityFilter() => priorities != null && priorities!.isNotEmpty;
  bool hasTagFilter() => tags != null && tags!.isNotEmpty;
  bool hasParticipantFilter() => participants != null && participants!.isNotEmpty;
  bool hasRoleFilter() => roles != null && roles!.isNotEmpty;
  bool hasStatusFilterNew() => status != null && status!.isNotEmpty;
  bool hasPriorityFilterNew() => priority != null && priority!.isNotEmpty;

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
      'query': query,
      'participants': participants,
      'roles': roles,
      'status': status,
      'priority': priority,
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
      roles:
          map['roles'] != null ? List<String>.from(map['roles']) : null,
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
      query: map['query'] as String?,
      participants: map['participants'] != null
          ? List<String>.from(map['participants'])
          : null,
      status: map['status'] as String?,
      priority: map['priority'] as String?,
    );
  }

  SearchFilter copyWith({
    String? searchText,
    List<String>? departments,
    List<String>? statuses,
    List<String>? priorities,
    List<String>? roles,
    DateTime? startDate,
    DateTime? endDate,
    String? assignedTo,
    String? createdBy,
    bool? isCompleted,
    String? type,
    List<String>? tags,
    String? sortBy,
    bool? sortAscending,
    String? query,
    List<String>? participants,
    String? status,
    String? priority,
  }) {
    return SearchFilter(
      searchText: searchText ?? this.searchText,
      departments: departments ?? this.departments,
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      roles: roles ?? this.roles,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      query: query ?? this.query,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      priority: priority ?? this.priority,
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
      case 'query':
        return copyWith(query: null);
      case 'participants':
        return copyWith(participants: null);
      case 'roles':
        return copyWith(roles: null);
      case 'status':
        return copyWith(status: null);
      case 'priority':
        return copyWith(priority: null);
      default:
        return this;
    }
  }
}