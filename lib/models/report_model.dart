import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String title;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> departments;
  final Map<String, dynamic> data;
  final List<ReportFile> files;
  final List<String> sharedWith;
  final Map<String, dynamic>? metadata;

  static const String typeTask = 'task';
  static const String typeMeeting = 'meeting';
  static const String typeWorkflow = 'workflow';
  static const String typeCustom = 'custom';

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.departments,
    required this.data,
    this.files = const [],
    this.sharedWith = const [],
    this.metadata,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      type: map['type'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      departments: List<String>.from(map['departments'] as List<dynamic>),
      data: map['data'] as Map<String, dynamic>,
      files: (map['files'] as List<dynamic>?)
          ?.map((file) => ReportFile.fromMap(file as Map<String, dynamic>))
          .toList() ?? [],
      sharedWith: List<String>.from(map['sharedWith'] as List<dynamic>? ?? []),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'departments': departments,
      'data': data,
      'files': files.map((file) => file.toMap()).toList(),
      'sharedWith': sharedWith,
      'metadata': metadata,
    };
  }

  ReportModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? departments,
    Map<String, dynamic>? data,
    List<ReportFile>? files,
    List<String>? sharedWith,
    Map<String, dynamic>? metadata,
  }) {
    return ReportModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      departments: departments ?? this.departments,
      data: data ?? this.data,
      files: files ?? this.files,
      sharedWith: sharedWith ?? this.sharedWith,
      metadata: metadata ?? this.metadata,
    );
  }

  bool canView(String userId) {
    return createdBy == userId || sharedWith.contains(userId);
  }

  bool canEdit(String userId) {
    return createdBy == userId;
  }
}

class ReportFile {
  final String id;
  final String name;
  final String url;
  final String uploadedBy;
  final DateTime uploadedAt;
  final String type;
  final int size;

  ReportFile({
    required this.id,
    required this.name,
    required this.url,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.type,
    required this.size,
  });

  factory ReportFile.fromMap(Map<String, dynamic> map) {
    return ReportFile(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      uploadedBy: map['uploadedBy'] as String,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      type: map['type'] as String,
      size: map['size'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'type': type,
      'size': size,
    };
  }
}