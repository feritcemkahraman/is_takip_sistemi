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
  Future<void> addComment(CommentModel comment) async {
    try {
      final taskRef = _firestore.collection('tasks').doc(comment.taskId);
      final commentRef = taskRef.collection('comments').doc(comment.id);
      
      await commentRef.set({
        ...comment.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Yorum eklenirken hata oluştu: $e');
    }
  }

  // Göreve yorum ekle
  Future<void> addCommentOld(String taskId, String text, String userId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).collection('comments').add({
        'text': text,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      notifyListeners();
    } catch (e) {
      print('Error adding comment: $e');
      throw e;
    }
  }

  // Göreve dosya ekle
  Future<void> addAttachment(String taskId, String filePath) async {
    try {
      final taskRef = _firestore.collection('tasks').doc(taskId);
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

  // Görev yorumlarını dinle
  Stream<List<Map<String, dynamic>>> getTaskCommentsOld(String taskId) {
    return _firestore
        .collection(_collection)
        .doc(taskId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                ...data,
                'id': doc.id,
                'timestamp': (data['timestamp'] as Timestamp).toDate(),
              };
            }).toList());
  }

  // Görev yorumlarını dinle
  Stream<List<CommentModel>> getTaskComments(String taskId) {
    try {
      return _firestore
          .collection('tasks')
          .doc(taskId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList());
    } catch (e) {
      throw Exception('Yorumlar alınırken hata oluştu: $e');
    }
  }
}
