import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../constants/app_constants.dart';

class ReportService {
  final FirebaseFirestore _firestore;
  final String _collection = AppConstants.reportsCollection;

  ReportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getTaskStatistics({
    String? department,
    String? assignedTo,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(AppConstants.tasksCollection);

      if (department != null) {
        query = query.where('department', isEqualTo: department);
      }

      if (assignedTo != null) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      int totalTasks = tasks.length;
      int completedTasks = tasks.where((task) => task.isCompleted).length;
      int overdueTasks = tasks.where((task) => task.isOverdue).length;
      double averageProgress = tasks.isEmpty
          ? 0.0
          : tasks.fold<double>(0.0, (sum, task) => sum + task.progress) /
              tasks.length;

      Map<String, int> priorityDistribution = {
        TaskModel.priorityLow: 0,
        TaskModel.priorityMedium: 0,
        TaskModel.priorityHigh: 0,
        TaskModel.priorityUrgent: 0,
      };

      for (var task in tasks) {
        priorityDistribution[task.priority] = 
            (priorityDistribution[task.priority] ?? 0) + 1;
      }

      Map<String, int> departmentDistribution = {};
      for (var task in tasks) {
        departmentDistribution[task.department] = 
            (departmentDistribution[task.department] ?? 0) + 1;
      }

      Map<String, Map<String, int>> timelineData = {};
      for (var task in tasks) {
        String date = task.createdAt.toIso8601String().split('T')[0];
        timelineData[date] = timelineData[date] ?? {'total': 0, 'completed': 0};
        timelineData[date]!['total'] = (timelineData[date]!['total'] ?? 0) + 1;
        if (task.isCompleted) {
          timelineData[date]!['completed'] = 
              (timelineData[date]!['completed'] ?? 0) + 1;
        }
      }

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'overdueTasks': overdueTasks,
        'averageProgress': averageProgress,
        'priorityDistribution': priorityDistribution,
        'departmentDistribution': departmentDistribution,
        'timeline': timelineData,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'department': department,
        'assignedTo': assignedTo,
      };
    } catch (e) {
      print('Error getting task statistics: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      final userTasksQuery = _firestore.collection(AppConstants.tasksCollection)
          .where('assignedTo', isEqualTo: userId);
      
      final createdTasksQuery = _firestore.collection(AppConstants.tasksCollection)
          .where('createdBy', isEqualTo: userId);

      final userTasksSnapshot = await userTasksQuery.get();
      final createdTasksSnapshot = await createdTasksQuery.get();

      final assignedTasks = userTasksSnapshot.docs
          .map((doc) => TaskModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      
      final createdTasks = createdTasksSnapshot.docs
          .map((doc) => TaskModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      int totalAssignedTasks = assignedTasks.length;
      int completedAssignedTasks = assignedTasks
          .where((task) => task.isCompleted)
          .length;
      
      int totalCreatedTasks = createdTasks.length;
      int completedCreatedTasks = createdTasks
          .where((task) => task.isCompleted)
          .length;

      double averageProgress = assignedTasks.isEmpty
          ? 0.0
          : assignedTasks.fold<double>(
              0.0, (sum, task) => sum + task.progress) / assignedTasks.length;

      return {
        'totalAssignedTasks': totalAssignedTasks,
        'completedAssignedTasks': completedAssignedTasks,
        'totalCreatedTasks': totalCreatedTasks,
        'completedCreatedTasks': completedCreatedTasks,
        'averageProgress': averageProgress,
        'assignedTasksOverdue': assignedTasks
            .where((task) => task.isOverdue)
            .length,
        'createdTasksOverdue': createdTasks
            .where((task) => task.isOverdue)
            .length,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserPerformance(String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('tasks')
          .where('assignedTo', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

      int totalTasks = tasks.length;
      int completedTasks = tasks.where((task) => task.isCompleted).length;
      int overdueTasks = tasks.where((task) => task.isOverdue).length;

      double averageProgress = tasks.isEmpty
          ? 0
          : tasks.fold<double>(0, (sum, task) => sum + task.progress) / tasks.length;

      Duration averageCompletionTime = Duration.zero;
      if (completedTasks > 0) {
        final completedTasksList = tasks.where((task) => task.isCompleted && task.completedAt != null).toList();
        final totalDuration = completedTasksList.fold<Duration>(
          Duration.zero,
          (sum, task) => sum + task.completedAt!.difference(task.createdAt),
        );
        averageCompletionTime = totalDuration ~/ completedTasksList.length;
      }

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'overdueTasks': overdueTasks,
        'averageProgress': averageProgress,
        'completionRate': totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0,
        'overdueRate': totalTasks > 0 ? (overdueTasks / totalTasks) * 100 : 0,
        'averageCompletionTimeInHours': averageCompletionTime.inHours,
      };
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<Map<String, dynamic>> getDepartmentPerformance(String department, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get department tasks
      Query<Map<String, dynamic>> tasksQuery = _firestore.collection('tasks')
          .where('department', isEqualTo: department);

      if (startDate != null) {
        tasksQuery = tasksQuery.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        tasksQuery = tasksQuery.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final tasksSnapshot = await tasksQuery.get();
      final tasks = tasksSnapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

      // Get department users
      final usersSnapshot = await _firestore.collection('users')
          .where('department', isEqualTo: department)
          .get();
      final users = usersSnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      Map<String, dynamic> userPerformance = {};
      for (var user in users) {
        final userTasks = tasks.where((task) => task.assignedTo == user.id).toList();
        final completedTasks = userTasks.where((task) => task.isCompleted).length;

        userPerformance[user.id] = {
          'name': user.name,
          'totalTasks': userTasks.length,
          'completedTasks': completedTasks,
          'completionRate': userTasks.isNotEmpty
              ? (completedTasks / userTasks.length) * 100
              : 0,
        };
      }

      int totalTasks = tasks.length;
      int completedTasks = tasks.where((task) => task.isCompleted).length;
      int overdueTasks = tasks.where((task) => task.isOverdue).length;

      double averageProgress = tasks.isEmpty
          ? 0
          : tasks.fold<double>(0, (sum, task) => sum + task.progress) / tasks.length;

      return {
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'overdueTasks': overdueTasks,
        'averageProgress': averageProgress,
        'completionRate': totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0,
        'overdueRate': totalTasks > 0 ? (overdueTasks / totalTasks) * 100 : 0,
        'totalUsers': users.length,
        'userPerformance': userPerformance,
      };
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<Map<String, dynamic>> getOverallStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> tasksQuery = _firestore.collection('tasks');
      Query<Map<String, dynamic>> usersQuery = _firestore.collection('users');

      if (startDate != null) {
        tasksQuery = tasksQuery.where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        tasksQuery = tasksQuery.where('createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final tasksSnapshot = await tasksQuery.get();
      final usersSnapshot = await usersQuery.get();

      final tasks = tasksSnapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      final users = usersSnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      Map<String, int> tasksByDepartment = {};
      Map<String, int> usersByDepartment = {};
      Map<String, int> completedTasksByDepartment = {};

      for (var task in tasks) {
        tasksByDepartment[task.department] = (tasksByDepartment[task.department] ?? 0) + 1;
        if (task.isCompleted) {
          completedTasksByDepartment[task.department] = 
              (completedTasksByDepartment[task.department] ?? 0) + 1;
        }
      }

      for (var user in users) {
        usersByDepartment[user.department] = (usersByDepartment[user.department] ?? 0) + 1;
      }

      Map<String, double> departmentCompletionRates = {};
      tasksByDepartment.forEach((department, totalTasks) {
        departmentCompletionRates[department] = totalTasks > 0
            ? ((completedTasksByDepartment[department] ?? 0) / totalTasks) * 100
            : 0;
      });

      return {
        'totalTasks': tasks.length,
        'totalUsers': users.length,
        'tasksByDepartment': tasksByDepartment,
        'usersByDepartment': usersByDepartment,
        'completedTasksByDepartment': completedTasksByDepartment,
        'departmentCompletionRates': departmentCompletionRates,
      };
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Future<void> createReport(ReportModel report) async {
    try {
      final docRef = _firestore.collection(AppConstants.reportsCollection).doc();
      await docRef.set({
        ...report.toMap(),
        'id': docRef.id,
      });
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Stream<List<ReportModel>> getReports(String userId) {
    try {
      return _firestore
          .collection(AppConstants.reportsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ReportModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList());
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Stream<ReportModel?> getReportStream(String reportId) {
    try {
      return _firestore
          .collection(AppConstants.reportsCollection)
          .doc(reportId)
          .snapshots()
          .map((doc) => doc.exists 
              ? ReportModel.fromMap({...doc.data()!, 'id': doc.id})
              : null);
    } catch (e) {
      throw _handleFirestoreError(e);
    }
  }

  Stream<List<ReportModel>> getAllReportsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<ReportModel>> getReportsByUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Exception _handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return Exception('Bu işlem için yetkiniz yok');
        case 'unavailable':
          return Exception('Servis şu anda kullanılamıyor');
        case 'not-found':
          return Exception('İstenen veri bulunamadı');
        default:
          return Exception('Bir hata oluştu: ${error.message}');
      }
    }
    return Exception('Beklenmeyen bir hata oluştu');
  }
}