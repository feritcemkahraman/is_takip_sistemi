import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/task_model.dart';
import '../constants/app_constants.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  // Rapor oluştur
  Future<ReportModel> createReport({
    required String title,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
    List<String> sharedWith = const [],
  }) async {
    try {
      final data = await _generateReportData(type, startDate, endDate);
      
      final report = ReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        type: type,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        createdBy: createdBy,
        data: data,
        sharedWith: sharedWith,
      );

      await _firestore
          .collection(_collection)
          .doc(report.id)
          .set(report.toMap());

      return report;
    } catch (e) {
      throw 'Rapor oluşturulurken bir hata oluştu: $e';
    }
  }

  // Rapor getir
  Future<ReportModel> getReport(String reportId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reportId).get();
      if (!doc.exists) {
        throw 'Rapor bulunamadı';
      }
      return ReportModel.fromMap(doc.data()!);
    } catch (e) {
      throw 'Rapor alınırken bir hata oluştu: $e';
    }
  }

  // Raporları getir
  Stream<List<ReportModel>> getReports(String userId) {
    return _firestore
        .collection(_collection)
        .where(Filter.or(
          Filter('createdBy', isEqualTo: userId),
          Filter('sharedWith', arrayContains: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromMap(doc.data()))
            .toList());
  }

  // Rapor sil
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection(_collection).doc(reportId).delete();
    } catch (e) {
      throw 'Rapor silinirken bir hata oluştu: $e';
    }
  }

  // Rapor paylaş
  Future<void> shareReport(String reportId, List<String> userIds) async {
    try {
      await _firestore.collection(_collection).doc(reportId).update({
        'sharedWith': FieldValue.arrayUnion(userIds),
      });
    } catch (e) {
      throw 'Rapor paylaşılırken bir hata oluştu: $e';
    }
  }

  // Rapor verilerini oluştur
  Future<Map<String, dynamic>> _generateReportData(
    String type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final tasksQuery = await _firestore
        .collection('tasks')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .get();

    final tasks = tasksQuery.docs
        .map((doc) => TaskModel.fromMap(doc.data()))
        .toList();

    final Map<String, dynamic> data = {
      'totalTasks': tasks.length,
      'completedTasks': tasks.where((t) => t.status == 'completed').length,
      'overdueTasks': tasks
          .where((t) =>
              t.status != 'completed' && t.dueDate.isBefore(DateTime.now()))
          .length,
    };

    // Tamamlanma oranı
    data['completionRate'] = tasks.isEmpty
        ? 0.0
        : (data['completedTasks'] / data['totalTasks']) * 100;

    // Durum dağılımı
    final statusDistribution = <String, int>{};
    for (final task in tasks) {
      statusDistribution[task.status] =
          (statusDistribution[task.status] ?? 0) + 1;
    }
    data['statusDistribution'] = statusDistribution;

    // Öncelik dağılımı
    final priorityDistribution = <String, int>{};
    for (final task in tasks) {
      priorityDistribution[task.priority] =
          (priorityDistribution[task.priority] ?? 0) + 1;
    }
    data['priorityDistribution'] = priorityDistribution;

    // Departman performansı
    if (type == ReportModel.typeDepartment) {
      final departmentPerformance = <String, double>{};
      for (final department in AppConstants.departments) {
        final departmentTasks =
            tasks.where((t) => t.department == department).toList();
        final completedTasks =
            departmentTasks.where((t) => t.status == 'completed').length;
        departmentPerformance[department] = departmentTasks.isEmpty
            ? 0.0
            : (completedTasks / departmentTasks.length) * 100;
      }
      data['departmentPerformance'] = departmentPerformance;
    }

    // Kullanıcı görev tamamlama
    if (type == ReportModel.typeUser) {
      final userTaskCompletion = <String, int>{};
      for (final task in tasks.where((t) => t.status == 'completed')) {
        userTaskCompletion[task.assignedTo] =
            (userTaskCompletion[task.assignedTo] ?? 0) + 1;
      }
      data['userTaskCompletion'] = userTaskCompletion;
    }

    // Ortalama tamamlanma süresi (gün olarak)
    final completedTasks = tasks.where((t) => t.status == 'completed');
    if (completedTasks.isNotEmpty) {
      final totalDays = completedTasks.fold<int>(
        0,
        (sum, task) =>
            sum +
            task.dueDate.difference(task.createdAt).inDays,
      );
      data['averageCompletionTime'] =
          totalDays / completedTasks.length;
    } else {
      data['averageCompletionTime'] = 0.0;
    }

    // Zaman çizelgesi
    final timeline = <Map<String, dynamic>>[];
    DateTime current = startDate;
    while (current.isBefore(endDate)) {
      final dayTasks = tasks
          .where((t) =>
              t.createdAt.year == current.year &&
              t.createdAt.month == current.month &&
              t.createdAt.day == current.day)
          .toList();

      timeline.add({
        'date': current,
        'total': dayTasks.length,
        'completed': dayTasks.where((t) => t.status == 'completed').length,
      });

      current = current.add(const Duration(days: 1));
    }
    data['timeline'] = timeline;

    return data;
  }
} 