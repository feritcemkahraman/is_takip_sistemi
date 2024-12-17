import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

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
  }) async {
    try {
      final task = {
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'deadline': Timestamp.fromDate(deadline),
        'completedAt': null,
        'status': 'pending',
        'priority': priority,
        'attachments': attachments,
        'metadata': {},
      };

      await _firestore.collection('tasks').add(task);
    } catch (e) {
      print('createTask hatası: $e');
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
  Future<bool> deleteTask(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
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
}
