import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../constants/app_constants.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = AppConstants.tasksCollection;

  // Yeni görev oluştur
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final taskWithId = task.copyWith(id: docRef.id);
      await docRef.set(taskWithId.toMap());
      return taskWithId;
    } catch (e) {
      print('Görev oluşturma hatası: $e');
      throw 'Görev oluşturulurken bir hata oluştu';
    }
  }

  // Görevi güncelle
  Future<void> updateTask(TaskModel task) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(task.id)
          .update(task.toMap());
    } catch (e) {
      print('Görev güncelleme hatası: $e');
      throw 'Görev güncellenirken bir hata oluştu';
    }
  }

  // Görevi sil
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
    } catch (e) {
      print('Görev silme hatası: $e');
      throw 'Görev silinirken bir hata oluştu';
    }
  }

  // Görev detaylarını getir
  Future<TaskModel> getTask(String taskId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(taskId).get();
      if (!doc.exists) {
        throw 'Görev bulunamadı';
      }
      return TaskModel.fromMap(doc.data()!);
    } catch (e) {
      print('Görev getirme hatası: $e');
      throw 'Görev getirilirken bir hata oluştu';
    }
  }

  // Tüm görevleri getir
  Stream<List<TaskModel>> getAllTasks() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data()))
            .toList());
  }

  // Departman görevlerini getir
  Stream<List<TaskModel>> getDepartmentTasks(String department) {
    return _firestore
        .collection(_collection)
        .where('department', isEqualTo: department)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data()))
            .toList());
  }

  // Kullanıcıya atanan görevleri getir
  Stream<List<TaskModel>> getUserTasks(String userId) {
    return _firestore
        .collection(_collection)
        .where('assignedTo', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data()))
            .toList());
  }

  // Geciken görevleri getir
  Stream<List<TaskModel>> getDelayedTasks() {
    return _firestore
        .collection(_collection)
        .where('dueDate', isLessThan: DateTime.now())
        .where('status', isNotEqualTo: 'completed')
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromMap(doc.data()))
            .toList());
  }

  // Yorum ekle
  Future<void> addComment(String taskId, Comment comment) async {
    try {
      final task = await getTask(taskId);
      final updatedComments = [...task.comments, comment];
      await _firestore.collection(_collection).doc(taskId).update({
        'comments': updatedComments.map((c) => c.toMap()).toList(),
      });
    } catch (e) {
      print('Yorum ekleme hatası: $e');
      throw 'Yorum eklenirken bir hata oluştu';
    }
  }

  // Dosya ekle
  Future<void> addAttachment(String taskId, String attachmentUrl) async {
    try {
      final task = await getTask(taskId);
      final updatedAttachments = [...task.attachments, attachmentUrl];
      await _firestore.collection(_collection).doc(taskId).update({
        'attachments': updatedAttachments,
      });
    } catch (e) {
      print('Dosya ekleme hatası: $e');
      throw 'Dosya eklenirken bir hata oluştu';
    }
  }

  // İlerleme durumunu güncelle
  Future<void> updateProgress(String taskId, double progress) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'progress': progress,
      });
    } catch (e) {
      print('İlerleme güncelleme hatası: $e');
      throw 'İlerleme güncellenirken bir hata oluştu';
    }
  }

  // Durumu güncelle
  Future<void> updateStatus(String taskId, String status) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'status': status,
      });
    } catch (e) {
      print('Durum güncelleme hatası: $e');
      throw 'Durum güncellenirken bir hata oluştu';
    }
  }

  // Takipçi ekle
  Future<void> addWatcher(String taskId, String userId) async {
    try {
      final task = await getTask(taskId);
      if (!task.watchers.contains(userId)) {
        final updatedWatchers = [...task.watchers, userId];
        await _firestore.collection(_collection).doc(taskId).update({
          'watchers': updatedWatchers,
        });
      }
    } catch (e) {
      print('Takipçi ekleme hatası: $e');
      throw 'Takipçi eklenirken bir hata oluştu';
    }
  }

  // Takipçi çıkar
  Future<void> removeWatcher(String taskId, String userId) async {
    try {
      final task = await getTask(taskId);
      final updatedWatchers = task.watchers.where((id) => id != userId).toList();
      await _firestore.collection(_collection).doc(taskId).update({
        'watchers': updatedWatchers,
      });
    } catch (e) {
      print('Takipçi çıkarma hatası: $e');
      throw 'Takipçi çıkarılırken bir hata oluştu';
    }
  }
}
