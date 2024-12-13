import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore;
  final String _collection = 'tasks';

  TaskService({required FirebaseFirestore firestore}) : _firestore = firestore;

  // Görev oluşturma
  Future<void> createTask(TaskModel task) async {
    try {
      await _firestore.collection(_collection).add(task.toMap());
    } catch (e) {
      print('Görev oluşturma hatası: $e');
      rethrow;
    }
  }

  // Görev güncelleme
  Future<void> updateTask(String taskId, TaskModel task) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update(task.toMap());
    } catch (e) {
      print('Görev güncelleme hatası: $e');
      rethrow;
    }
  }

  // Görev silme
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
    } catch (e) {
      print('Görev silme hatası: $e');
      rethrow;
    }
  }

  // Görev durumu güncelleme
  Future<void> updateStatus(String taskId, String status) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'status': status,
      });
    } catch (e) {
      print('Görev durumu güncelleme hatası: $e');
      rethrow;
    }
  }

  // Görev ilerleme durumu güncelleme
  Future<void> updateProgress(String taskId, double progress) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'progress': progress,
      });
    } catch (e) {
      print('Görev ilerleme durumu güncelleme hatası: $e');
      rethrow;
    }
  }

  // Tek bir görevi getirme
  Future<TaskModel?> getTask(String taskId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(taskId).get();
      if (doc.exists) {
        return TaskModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Görev getirme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcıya atanan görevleri getirme
  Stream<List<TaskModel>> getUserTasks(String userId) {
    try {
      return _firestore
          .collection(_collection)
          .where('assignedTo', isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Kullanıcı görevlerini getirme hatası: $e');
      rethrow;
    }
  }

  // Tüm görevleri getirme
  Stream<List<TaskModel>> getAllTasks() {
    try {
      return _firestore
          .collection(_collection)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Tüm görevleri getirme hatası: $e');
      rethrow;
    }
  }

  // Görevleri filtreleme ve arama
  Stream<List<TaskModel>> filterTasks({
    String? status,
    String? priority,
    String? assignedTo,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    try {
      Query query = _firestore.collection(_collection);

      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      if (priority != null && priority.isNotEmpty) {
        query = query.where('priority', isEqualTo: priority);
      }

      if (assignedTo != null && assignedTo.isNotEmpty) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }

      if (startDate != null) {
        query = query.where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      return query.snapshots().map((snapshot) {
        var tasks = snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

        if (searchQuery != null && searchQuery.isNotEmpty) {
          final lowercaseQuery = searchQuery.toLowerCase();
          tasks = tasks.where((task) {
            return task.title.toLowerCase().contains(lowercaseQuery) ||
                   task.description.toLowerCase().contains(lowercaseQuery);
          }).toList();
        }

        return tasks;
      });
    } catch (e) {
      print('Görev filtreleme hatası: $e');
      rethrow;
    }
  }

  // Yaklaşan görevleri getirme
  Stream<List<TaskModel>> getUpcomingTasks(String userId) {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      return _firestore
          .collection(_collection)
          .where('assignedTo', isEqualTo: userId)
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(nextWeek))
          .where('status', whereIn: ['pending', 'in_progress'])
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Yaklaşan görevleri getirme hatası: $e');
      rethrow;
    }
  }

  // Geciken görevleri getirme
  Stream<List<TaskModel>> getOverdueTasks(String userId) {
    try {
      final now = DateTime.now();

      return _firestore
          .collection(_collection)
          .where('assignedTo', isEqualTo: userId)
          .where('dueDate', isLessThan: Timestamp.fromDate(now))
          .where('status', whereIn: ['pending', 'in_progress'])
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Geciken görevleri getirme hatası: $e');
      rethrow;
    }
  }

  // Yorum ekleme
  Future<void> addComment(String taskId, Comment comment) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });
    } catch (e) {
      print('Yorum ekleme hatası: $e');
      rethrow;
    }
  }

  // Yorum silme
  Future<void> removeComment(String taskId, String commentId) async {
    try {
      final task = await getTask(taskId);
      if (task != null) {
        final updatedComments = task.comments
            .where((comment) => comment.id != commentId)
            .toList();
        await _firestore.collection(_collection).doc(taskId).update({
          'comments': updatedComments.map((c) => c.toMap()).toList(),
        });
      }
    } catch (e) {
      print('Yorum silme hatası: $e');
      rethrow;
    }
  }

  // Etiket ekleme
  Future<void> addTag(String taskId, String tag) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'tags': FieldValue.arrayUnion([tag]),
      });
    } catch (e) {
      print('Etiket ekleme hatası: $e');
      rethrow;
    }
  }

  // Etiket silme
  Future<void> removeTag(String taskId, String tag) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'tags': FieldValue.arrayRemove([tag]),
      });
    } catch (e) {
      print('Etiket silme hatası: $e');
      rethrow;
    }
  }

  // Dosya ekleme
  Future<void> addAttachment(String taskId, String attachmentUrl) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'attachments': FieldValue.arrayUnion([attachmentUrl]),
      });
    } catch (e) {
      print('Dosya ekleme hatası: $e');
      rethrow;
    }
  }

  // Dosya silme
  Future<void> removeAttachment(String taskId, String attachmentUrl) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'attachments': FieldValue.arrayRemove([attachmentUrl]),
      });
    } catch (e) {
      print('Dosya silme hatası: $e');
      rethrow;
    }
  }
}
