import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/comment_model.dart';
import '../services/local_storage_service.dart';

class TaskService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // Tüm görevleri getir
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all tasks: $e');
      return [];
    }
  }

  // Aktif görevleri getir
  Future<List<TaskModel>> getActiveTasks() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .orderBy('deadline')
          .orderBy('__name__')
          .get();
      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting active tasks: $e');
      return [];
    }
  }

  // Bekleyen görevleri getir
  Future<List<TaskModel>> getPendingTasks() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'pending')
          .orderBy('deadline')
          .orderBy('__name__')
          .get();
      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting pending tasks: $e');
      return [];
    }
  }

  // Tamamlanan görevleri getir
  Future<List<TaskModel>> getCompletedTasks() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .orderBy('__name__', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting completed tasks: $e');
      return [];
    }
  }

  // Yeni görev oluştur
  Future<void> createTask({
    required String title,
    required String description,
    required String assignedTo,
    required String createdBy,
    required DateTime deadline,
    required int priority,
    List<String> attachments = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'deadline': deadline,
        'completedAt': null,
        'status': 'active', // Direkt aktif olarak oluştur
        'priority': priority,
        'attachments': attachments,
        'metadata': metadata,
      });
      notifyListeners();
    } catch (e) {
      print('Error creating task: $e');
      rethrow;
    }
  }

  // Görevi güncelle
  Future<bool> updateTask(String id, TaskModel task) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(id)
          .update(task.toFirestore());
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  // Görevi sil
  Future<void> deleteTask(String taskId) async {
    try {
      // Önce görevin dosyalarını sil
      final localStorageService = LocalStorageService();
      await localStorageService.deleteTaskAttachments(taskId);

      // Sonra görevi sil
      await _firestore.collection(_collection).doc(taskId).delete();
      notifyListeners();
    } catch (e) {
      print('deleteTask hatası: $e');
      rethrow;
    }
  }

  // Görevi tamamla
  Future<bool> completeTask(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      print('Error completing task: $e');
      return false;
    }
  }

  // Görev durumunu güncelle
  Future<bool> updateTaskStatus(String id, String status) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'status': status,
        'completedAt': status == 'completed' ? FieldValue.serverTimestamp() : null,
      });
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating task status: $e');
      return false;
    }
  }

  // Kullanıcıya atanan görevleri getir
  Future<List<TaskModel>> getTasksByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('assignedTo', isEqualTo: userId)
          .orderBy('deadline')
          .get();
      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting tasks by user: $e');
      return [];
    }
  }

  // Göreve yorum ekle
  Future<void> addComment({
    required String taskId,
    required String userId,
    required String content,
  }) async {
    try {
      final commentRef = _firestore
          .collection(_collection)
          .doc(taskId)
          .collection('comments')
          .doc();

      await commentRef.set({
        'id': commentRef.id,
        'userId': userId,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // Yorum sil
  Future<void> deleteComment({
    required String taskId,
    required String commentId,
  }) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(taskId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  // Görev yorumlarını getir
  Stream<List<CommentModel>> getTaskComments(String taskId) {
    return _firestore
        .collection(_collection)
        .doc(taskId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList());
  }

  // Göreve dosya ekle
  Future<void> addAttachment(String taskId, String filePath) async {
    try {
      final taskRef = _firestore.collection(_collection).doc(taskId);
      final task = await taskRef.get();
      
      if (!task.exists) {
        throw Exception('Görev bulunamadı');
      }

      final currentAttachments = List<String>.from(task.data()?['attachments'] ?? []);
      currentAttachments.add(filePath);

      await taskRef.update({
        'attachments': currentAttachments,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Dosya eklenirken hata oluştu: $e');
    }
  }

  // Görev stream'i
  Stream<TaskModel> getTaskStream(String taskId) {
    return _firestore
        .collection(_collection)
        .doc(taskId)
        .snapshots()
        .map((doc) => TaskModel.fromFirestore(doc));
  }

  // Dosya silme
  Future<void> removeAttachment(String taskId, String filePath) async {
    await _firestore.collection(_collection).doc(taskId).update({
      'attachments': FieldValue.arrayRemove([filePath])
    });
  }
}
