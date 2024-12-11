import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Görev oluştur
  Future<void> createTask({
    required String title,
    required String description,
    required String assignedTo,
    required DateTime dueDate,
    String? priority,
    List<String>? attachments,
  }) async {
    try {
      final task = {
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': Timestamp.fromDate(dueDate),
        'status': 'pending',
        'priority': priority ?? 'medium',
        'attachments': attachments ?? [],
        'comments': [],
      };

      await _firestore.collection('tasks').add(task);
    } catch (e) {
      throw 'Görev oluşturulurken bir hata oluştu: $e';
    }
  }

  // Görevleri getir
  Stream<List<TaskModel>> getTasks() {
    return _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    });
  }

  // Görevleri atanan kişiye göre getir
  Stream<List<TaskModel>> getTasksByAssignee(String userId) {
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
    });
  }

  // Görev durumunu güncelle
  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Görev durumu güncellenirken bir hata oluştu: $e';
    }
  }

  // Göreve yorum ekle
  Future<void> addComment(String taskId, String userId, String comment) async {
    try {
      final commentData = {
        'userId': userId,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('tasks').doc(taskId).update({
        'comments': FieldValue.arrayUnion([commentData]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Yorum eklenirken bir hata oluştu: $e';
    }
  }

  // Göreve dosya ekle
  Future<void> addAttachment(String taskId, String attachmentUrl) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'attachments': FieldValue.arrayUnion([attachmentUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Dosya eklenirken bir hata oluştu: $e';
    }
  }
}
