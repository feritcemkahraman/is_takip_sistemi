import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class TaskFile {
  final String id;
  final String name;
  final String url;
  final String uploadedBy;
  final String? uploaderName;
  final DateTime uploadedAt;
  final String type;
  final int size;
  final String? description;
  final Map<String, dynamic>? metadata;

  const TaskFile({
    required this.id,
    required this.name,
    required this.url,
    required this.uploadedBy,
    this.uploaderName,
    required this.uploadedAt,
    required this.type,
    required this.size,
    this.description,
    this.metadata,
  });

  factory TaskFile.fromMap(Map<String, dynamic> map) {
    return TaskFile(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      url: map['url'] as String? ?? '',
      uploadedBy: map['uploadedBy'] as String? ?? '',
      uploaderName: map['uploaderName'] as String?,
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
      type: map['type'] as String? ?? '',
      size: map['size'] as int? ?? 0,
      description: map['description'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'uploadedBy': uploadedBy,
      'uploaderName': uploaderName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'type': type,
      'size': size,
      'description': description,
      'metadata': metadata,
    };
  }

  TaskFile copyWith({
    String? id,
    String? name,
    String? url,
    String? uploadedBy,
    String? uploaderName,
    DateTime? uploadedAt,
    String? type,
    int? size,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return TaskFile(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploaderName: uploaderName ?? this.uploaderName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      type: type ?? this.type,
      size: size ?? this.size,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  String getFormattedSize() {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String getFileExtension() {
    return name.split('.').last.toLowerCase();
  }

  bool isImage() {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    return imageExtensions.contains(getFileExtension());
  }

  bool isPdf() {
    return getFileExtension() == 'pdf';
  }

  bool isDocument() {
    final docExtensions = ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'pdf', 'txt'];
    return docExtensions.contains(getFileExtension());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          url == other.url &&
          uploadedBy == other.uploadedBy &&
          uploadedAt == other.uploadedAt &&
          type == type &&
          size == size;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      url.hashCode ^
      uploadedBy.hashCode ^
      uploadedAt.hashCode ^
      type.hashCode ^
      size.hashCode;

  @override
  String toString() {
    return 'TaskFile(id: $id, name: $name, type: $type)';
  }
}