import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingReportModel {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final String createdBy;
  final Map<String, dynamic> data;
  final List<String> sharedWith;

  MeetingReportModel({
    required this.id,
    required this.title,
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
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'data': data,
      'sharedWith': sharedWith,
    };
  }

  factory MeetingReportModel.fromMap(Map<String, dynamic> map) {
    return MeetingReportModel(
      id: map['id'] as String,
      title: map['title'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
      data: map['data'] as Map<String, dynamic>,
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
    );
  }

  // Veri analizi metodları
  Map<String, int> getMeetingStatusDistribution() {
    return (data['statusDistribution'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    );
  }

  Map<String, int> getMeetingTypeDistribution() {
    return (data['typeDistribution'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    );
  }

  Map<String, double> getDepartmentParticipation() {
    return (data['departmentParticipation'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as double),
    );
  }

  Map<String, int> getUserParticipation() {
    return (data['userParticipation'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    );
  }

  Map<String, int> getDecisionStatusDistribution() {
    return (data['decisionStatusDistribution'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    );
  }

  Map<String, int> getDecisionAssigneeDistribution() {
    return (data['decisionAssigneeDistribution'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value as int),
    );
  }

  double getAverageDecisionCompletionTime() {
    return data['averageDecisionCompletionTime'] as double;
  }

  double getAverageMeetingDuration() {
    return data['averageMeetingDuration'] as double;
  }

  int getTotalMeetings() {
    return data['totalMeetings'] as int;
  }

  int getCompletedMeetings() {
    return data['completedMeetings'] as int;
  }

  int getCancelledMeetings() {
    return data['cancelledMeetings'] as int;
  }

  int getTotalDecisions() {
    return data['totalDecisions'] as int;
  }

  int getCompletedDecisions() {
    return data['completedDecisions'] as int;
  }

  int getOverdueDecisions() {
    return data['overdueDecisions'] as int;
  }

  double getDecisionCompletionRate() {
    return data['decisionCompletionRate'] as double;
  }

  double getMeetingAttendanceRate() {
    return data['meetingAttendanceRate'] as double;
  }

  List<Map<String, dynamic>> getTimelineData() {
    return List<Map<String, dynamic>>.from(data['timeline'] ?? []);
  }
} 