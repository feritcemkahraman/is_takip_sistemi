import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/meeting_model.dart';
import '../models/workflow_model.dart';
import '../models/user_model.dart';

class ReportService {
  final FirebaseFirestore _firestore;

  ReportService({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  // Görev istatistikleri
  Future<Map<String, dynamic>> getTaskStats(String userId) async {
    try {
      final tasks = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get();

      final taskList = tasks.docs.map((doc) => TaskModel.fromMap(doc.data())).toList();

      final stats = {
        'total': taskList.length,
        'completed': taskList.where((t) => t.isCompleted()).length,
        'pending': taskList.where((t) => t.isPending()).length,
        'inProgress': taskList.where((t) => t.isInProgress()).length,
        'overdue': taskList.where((t) => t.isOverdue()).length,
        'highPriority': taskList.where((t) => t.isHighPriority()).length,
        'mediumPriority': taskList.where((t) => t.isMediumPriority()).length,
        'lowPriority': taskList.where((t) => t.isLowPriority()).length,
        'withAttachments': taskList.where((t) => t.hasAttachments()).length,
        'withComments': taskList.where((t) => t.hasComments()).length,
      };

      return stats;
    } catch (e) {
      print('Görev istatistikleri getirme hatası: $e');
      rethrow;
    }
  }

  // Toplantı istatistikleri
  Future<Map<String, dynamic>> getMeetingStats(String userId) async {
    try {
      final meetings = await _firestore
          .collection('meetings')
          .where('participants', arrayContains: userId)
          .get();

      final meetingList =
          meetings.docs.map((doc) => MeetingModel.fromMap(doc.data())).toList();

      final stats = {
        'total': meetingList.length,
        'upcoming': meetingList.where((m) => m.isUpcoming()).length,
        'ongoing': meetingList.where((m) => m.isOngoing()).length,
        'past': meetingList.where((m) => m.isPast()).length,
        'organized': meetingList.where((m) => m.isOrganizer(userId)).length,
        'participated': meetingList.where((m) => m.isParticipant(userId)).length,
        'online': meetingList.where((m) => m.isOnline).length,
        'offline': meetingList.where((m) => !m.isOnline).length,
        'withMinutes': meetingList.where((m) => m.minutes != null).length,
        'withDecisions':
            meetingList.where((m) => m.decisions?.isNotEmpty ?? false).length,
      };

      return stats;
    } catch (e) {
      print('Toplantı istatistikleri getirme hatası: $e');
      rethrow;
    }
  }

  // İş akışı istatistikleri
  Future<Map<String, dynamic>> getWorkflowStats(String userId) async {
    try {
      final workflows = await _firestore
          .collection('workflows')
          .where('participants', arrayContains: userId)
          .get();

      final workflowList =
          workflows.docs.map((doc) => WorkflowModel.fromMap(doc.data())).toList();

      final stats = {
        'total': workflowList.length,
        'active': workflowList.where((w) => w.isActive()).length,
        'completed': workflowList.where((w) => w.isCompleted()).length,
        'cancelled': workflowList.where((w) => w.isCancelled()).length,
        'overdue': workflowList.where((w) => w.isOverdue()).length,
        'created': workflowList.where((w) => w.createdBy == userId).length,
        'assigned': workflowList
            .where((w) => w.currentStepObject.assignedTo == userId)
            .length,
        'withAttachments': workflowList.where((w) => w.hasAttachments()).length,
        'withComments': workflowList.where((w) => w.hasComments()).length,
      };

      return stats;
    } catch (e) {
      print('İş akışı istatistikleri getirme hatası: $e');
      rethrow;
    }
  }

  // Görev dağılımı
  Future<Map<String, dynamic>> getTaskDistribution(String userId) async {
    try {
      final tasks = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get();

      final taskList = tasks.docs.map((doc) => TaskModel.fromMap(doc.data())).toList();

      // Öncelik dağılımı
      final priorityDistribution = {
        TaskModel.priorityLow: 0,
        TaskModel.priorityMedium: 0,
        TaskModel.priorityHigh: 0,
      };

      for (final task in taskList) {
        priorityDistribution[task.priority] =
            (priorityDistribution[task.priority] ?? 0) + 1;
      }

      // Durum dağılımı
      final statusDistribution = {
        TaskModel.statusPending: 0,
        TaskModel.statusInProgress: 0,
        TaskModel.statusCompleted: 0,
        TaskModel.statusCancelled: 0,
        TaskModel.statusOverdue: 0,
      };

      for (final task in taskList) {
        statusDistribution[task.status] = (statusDistribution[task.status] ?? 0) + 1;
      }

      // Etiket dağılımı
      final tagDistribution = <String, int>{};
      for (final task in taskList) {
        for (final tag in task.tags) {
          tagDistribution[tag] = (tagDistribution[tag] ?? 0) + 1;
        }
      }

      return {
        'priority': priorityDistribution,
        'status': statusDistribution,
        'tags': tagDistribution,
      };
    } catch (e) {
      print('Görev dağılımı getirme hatası: $e');
      rethrow;
    }
  }

  // Toplantı dağılımı
  Future<Map<String, dynamic>> getMeetingDistribution(String userId) async {
    try {
      final meetings = await _firestore
          .collection('meetings')
          .where('participants', arrayContains: userId)
          .get();

      final meetingList =
          meetings.docs.map((doc) => MeetingModel.fromMap(doc.data())).toList();

      // Platform dağılımı
      final platformDistribution = {
        MeetingModel.platformZoom: 0,
        MeetingModel.platformMeet: 0,
        MeetingModel.platformTeams: 0,
        MeetingModel.platformSkype: 0,
      };

      for (final meeting in meetingList) {
        if (meeting.meetingPlatform != null) {
          platformDistribution[meeting.meetingPlatform] =
              (platformDistribution[meeting.meetingPlatform] ?? 0) + 1;
        }
      }

      // Departman dağılımı
      final departmentDistribution = <String, int>{};
      for (final meeting in meetingList) {
        for (final department in meeting.departments) {
          departmentDistribution[department] =
              (departmentDistribution[department] ?? 0) + 1;
        }
      }

      // Katılım durumu dağılımı
      final participationDistribution = {
        MeetingParticipant.statusPending: 0,
        MeetingParticipant.statusAccepted: 0,
        MeetingParticipant.statusDeclined: 0,
        MeetingParticipant.statusTentative: 0,
      };

      for (final meeting in meetingList) {
        final status = meeting.getParticipantStatus(userId);
        if (status != null) {
          participationDistribution[status] =
              (participationDistribution[status] ?? 0) + 1;
        }
      }

      return {
        'platform': platformDistribution,
        'department': departmentDistribution,
        'participation': participationDistribution,
      };
    } catch (e) {
      print('Toplantı dağılımı getirme hatası: $e');
      rethrow;
    }
  }

  // İş akışı dağılımı
  Future<Map<String, dynamic>> getWorkflowDistribution(String userId) async {
    try {
      final workflows = await _firestore
          .collection('workflows')
          .where('participants', arrayContains: userId)
          .get();

      final workflowList =
          workflows.docs.map((doc) => WorkflowModel.fromMap(doc.data())).toList();

      // Durum dağılımı
      final statusDistribution = {
        WorkflowModel.statusActive: 0,
        WorkflowModel.statusCompleted: 0,
        WorkflowModel.statusCancelled: 0,
      };

      for (final workflow in workflowList) {
        statusDistribution[workflow.status] =
            (statusDistribution[workflow.status] ?? 0) + 1;
      }

      // Departman dağılımı
      final departmentDistribution = <String, int>{};
      for (final workflow in workflowList) {
        for (final department in workflow.departments) {
          departmentDistribution[department] =
              (departmentDistribution[department] ?? 0) + 1;
        }
      }

      // Etiket dağılımı
      final tagDistribution = <String, int>{};
      for (final workflow in workflowList) {
        for (final tag in workflow.tags) {
          tagDistribution[tag] = (tagDistribution[tag] ?? 0) + 1;
        }
      }

      return {
        'status': statusDistribution,
        'department': departmentDistribution,
        'tags': tagDistribution,
      };
    } catch (e) {
      print('İş akışı dağılımı getirme hatası: $e');
      rethrow;
    }
  }

  // Performans metrikleri
  Future<Map<String, dynamic>> getPerformanceMetrics(String userId) async {
    try {
      final tasks = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get();

      final taskList = tasks.docs.map((doc) => TaskModel.fromMap(doc.data())).toList();

      // Tamamlanan görev sayısı
      final completedTasks = taskList.where((t) => t.isCompleted()).length;

      // Zamanında tamamlanan görev sayısı
      final onTimeTasks = taskList
          .where((t) => t.isCompleted() && !t.isOverdue())
          .length;

      // Ortalama tamamlanma süresi (gün)
      final completionTimes = taskList
          .where((t) => t.isCompleted())
          .map((task) =>
              task.dueDate.difference(task.startDate).inDays)
          .toList();

      final averageCompletionTime = completionTimes.isNotEmpty
          ? completionTimes.reduce((a, b) => a + b) / completionTimes.length
          : 0;

      // Aylık tamamlanan görev sayısı
      final monthlyCompletions = <String, int>{};
      final now = DateTime.now();
      for (var i = 0; i < 12; i++) {
        final current = DateTime(now.year, now.month - i);
        final count = taskList.where((t) =>
            t.isCompleted() &&
            t.startDate.year == current.year &&
            t.startDate.month == current.month).length;
        monthlyCompletions['${current.year}-${current.month}'] = count;
      }

      return {
        'totalCompleted': completedTasks,
        'onTimeCompletion': onTimeTasks,
        'completionRate': taskList.isNotEmpty
            ? (completedTasks / taskList.length * 100).round()
            : 0,
        'averageCompletionTime': averageCompletionTime.round(),
        'monthlyCompletions': monthlyCompletions,
      };
    } catch (e) {
      print('Performans metrikleri getirme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı aktivite raporu
  Future<Map<String, dynamic>> getUserActivityReport(String userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Görevler
      final tasks = await _firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: userId)
          .get();

      final taskList = tasks.docs.map((doc) => TaskModel.fromMap(doc.data())).toList();

      // Toplantılar
      final meetings = await _firestore
          .collection('meetings')
          .where('participants', arrayContains: userId)
          .get();

      final meetingList =
          meetings.docs.map((doc) => MeetingModel.fromMap(doc.data())).toList();

      // İş akışları
      final workflows = await _firestore
          .collection('workflows')
          .where('participants', arrayContains: userId)
          .get();

      final workflowList =
          workflows.docs.map((doc) => WorkflowModel.fromMap(doc.data())).toList();

      // Haftalık aktiviteler
      final weeklyTasks = taskList
          .where((t) =>
              t.startDate.isAfter(startOfWeek) ||
              t.startDate.isAtSameMomentAs(startOfWeek))
          .length;

      final weeklyMeetings = meetingList
          .where((m) =>
              m.startTime.isAfter(startOfWeek) ||
              m.startTime.isAtSameMomentAs(startOfWeek))
          .length;

      final weeklyWorkflows = workflowList
          .where((w) =>
              w.startDate.isAfter(startOfWeek) ||
              w.startDate.isAtSameMomentAs(startOfWeek))
          .length;

      // Aylık aktiviteler
      final monthlyTasks = taskList
          .where((t) =>
              t.startDate.isAfter(startOfMonth) ||
              t.startDate.isAtSameMomentAs(startOfMonth))
          .length;

      final monthlyMeetings = meetingList
          .where((m) =>
              m.startTime.isAfter(startOfMonth) ||
              m.startTime.isAtSameMomentAs(startOfMonth))
          .length;

      final monthlyWorkflows = workflowList
          .where((w) =>
              w.startDate.isAfter(startOfMonth) ||
              w.startDate.isAtSameMomentAs(startOfMonth))
          .length;

      return {
        'weekly': {
          'tasks': weeklyTasks,
          'meetings': weeklyMeetings,
          'workflows': weeklyWorkflows,
          'total': weeklyTasks + weeklyMeetings + weeklyWorkflows,
        },
        'monthly': {
          'tasks': monthlyTasks,
          'meetings': monthlyMeetings,
          'workflows': monthlyWorkflows,
          'total': monthlyTasks + monthlyMeetings + monthlyWorkflows,
        },
      };
    } catch (e) {
      print('Kullanıcı aktivite raporu getirme hatası: $e');
      rethrow;
    }
  }

  // Departman performans raporu
  Future<Map<String, dynamic>> getDepartmentPerformanceReport(
      String department) async {
    try {
      // Departmandaki kullanıcılar
      final users = await _firestore
          .collection('users')
          .where('department', isEqualTo: department)
          .get();

      final userList =
          users.docs.map((doc) => UserModel.fromMap(doc.data())).toList();

      // Departman görevleri
      final tasks = await _firestore
          .collection('tasks')
          .where('assignedTo', whereIn: userList.map((u) => u.id).toList())
          .get();

      final taskList = tasks.docs.map((doc) => TaskModel.fromMap(doc.data())).toList();

      // Departman toplantıları
      final meetings = await _firestore
          .collection('meetings')
          .where('departments', arrayContains: department)
          .get();

      final meetingList =
          meetings.docs.map((doc) => MeetingModel.fromMap(doc.data())).toList();

      // Departman iş akışları
      final workflows = await _firestore
          .collection('workflows')
          .where('departments', arrayContains: department)
          .get();

      final workflowList =
          workflows.docs.map((doc) => WorkflowModel.fromMap(doc.data())).toList();

      // Görev metrikleri
      final completedTasks = taskList.where((t) => t.isCompleted()).length;
      final onTimeTasks =
          taskList.where((t) => t.isCompleted() && !t.isOverdue()).length;
      final overdueTasks = taskList.where((t) => t.isOverdue()).length;

      // Toplantı metrikleri
      final completedMeetings =
          meetingList.where((m) => m.isCompleted()).length;
      final cancelledMeetings =
          meetingList.where((m) => m.isCancelled()).length;
      final meetingsWithMinutes =
          meetingList.where((m) => m.minutes != null).length;

      // İş akışı metrikleri
      final completedWorkflows =
          workflowList.where((w) => w.isCompleted()).length;
      final overdueWorkflows = workflowList.where((w) => w.isOverdue()).length;
      final activeWorkflows = workflowList.where((w) => w.isActive()).length;

      return {
        'users': userList.length,
        'tasks': {
          'total': taskList.length,
          'completed': completedTasks,
          'onTime': onTimeTasks,
          'overdue': overdueTasks,
          'completionRate': taskList.isNotEmpty
              ? (completedTasks / taskList.length * 100).round()
              : 0,
        },
        'meetings': {
          'total': meetingList.length,
          'completed': completedMeetings,
          'cancelled': cancelledMeetings,
          'withMinutes': meetingsWithMinutes,
          'completionRate': meetingList.isNotEmpty
              ? (completedMeetings / meetingList.length * 100).round()
              : 0,
        },
        'workflows': {
          'total': workflowList.length,
          'completed': completedWorkflows,
          'active': activeWorkflows,
          'overdue': overdueWorkflows,
          'completionRate': workflowList.isNotEmpty
              ? (completedWorkflows / workflowList.length * 100).round()
              : 0,
        },
      };
    } catch (e) {
      print('Departman performans raporu getirme hatası: $e');
      rethrow;
    }
  }
} 