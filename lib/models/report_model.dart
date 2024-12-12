import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String title;
  final String type; // task_report, department_report, user_report
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final String createdBy;
  final Map<String, dynamic> data;
  final List<String> sharedWith;

  ReportModel({
    required this.id,
    required this.title,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.createdBy,
    required this.data,
    this.sharedWith = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'data': data,
      'sharedWith': sharedWith,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
      data: map['data'] as Map<String, dynamic>,
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
    );
  }

  // Rapor türleri
  static const String typeTask = 'task_report';
  static const String typeDepartment = 'department_report';
  static const String typeUser = 'user_report';

  // Rapor başlıkları
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

  // Veri analizi metodları
  Map<String, int> getTaskStatusDistribution() {
    return (data['statusDistribution'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    );
  }

  Map<String, int> getTaskPriorityDistribution() {
    return (data['priorityDistribution'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    );
  }

  Map<String, double> getDepartmentPerformance() {
    return (data['departmentPerformance'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as double),
    );
  }

  Map<String, int> getUserTaskCompletion() {
    return (data['userTaskCompletion'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    );
  }

  double getAverageTaskCompletionTime() {
    return data['averageCompletionTime'] as double;
  }

  int getTotalTasks() {
    return data['totalTasks'] as int;
  }

  int getCompletedTasks() {
    return data['completedTasks'] as int;
  }

  int getOverdueTasks() {
    return data['overdueTasks'] as int;
  }

  double getCompletionRate() {
    return data['completionRate'] as double;
  }

  List<Map<String, dynamic>> getTimelineData() {
    return List<Map<String, dynamic>>.from(data['timeline'] ?? []);
  }
} 