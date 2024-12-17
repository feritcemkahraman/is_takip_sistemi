import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  static const String typeTask = 'task';
  static const String typeDepartment = 'department';
  static const String typeUser = 'user';

  static String getTitle(String type) {
    switch (type) {
      case typeTask:
        return 'Görev Raporu';
      case typeDepartment:
        return 'Departman Raporu';
      case typeUser:
        return 'Kullanıcı Raporu';
      default:
        return 'Rapor';
    }
  }

  final String id;
  final String title;
  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final String userId;
  final int totalTasks;
  final int completedTasks;

  const ReportModel({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.createdAt,
    required this.data,
    required this.userId,
    required this.totalTasks,
    required this.completedTasks,
  });

  double get completionRate => totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
      'userId': userId,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      data: map['data'] as Map<String, dynamic>,
      userId: map['userId'] as String,
      totalTasks: map['totalTasks'] as int,
      completedTasks: map['completedTasks'] as int,
    );
  }

  File toFile() {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/report_${DateTime.now().millisecondsSinceEpoch}.txt');
    
    final content = StringBuffer();
    content.writeln('Rapor: $title');
    content.writeln('Tür: $type');
    content.writeln('Başlangıç: ${startDate.day}/${startDate.month}/${startDate.year}');
    content.writeln('Bitiş: ${endDate.day}/${endDate.month}/${endDate.year}');
    content.writeln('Oluşturulma: ${createdAt.day}/${createdAt.month}/${createdAt.year}');
    content.writeln('Toplam Görev: $totalTasks');
    content.writeln('Tamamlanan Görev: $completedTasks');
    content.writeln('Tamamlanma Oranı: %${(completionRate * 100).toStringAsFixed(1)}');

    file.writeAsStringSync(content.toString());
    return file;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}