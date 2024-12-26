import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/task_model.dart';
import '../models/comment_model.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import 'package:path/path.dart' as path;

class TaskService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _collection = 'tasks';
  final UserService _userService;

  TaskService(this._userService);

  // Kullanıcı rolünü kontrol et
  Future<bool> _isUserAdmin() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    return userDoc.data()?['role'] == 'admin';
  }

  // Tüm görevleri getir
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final isAdmin = await _isUserAdmin();
      Query query = _firestore.collection(_collection);

      if (!isAdmin) {
        query = query.where('assignedTo', isEqualTo: currentUser.uid);
      }

      final querySnapshot = await query.get();
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
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final isAdmin = await _isUserAdmin();
      Query query = _firestore.collection(_collection).where('status', isEqualTo: 'active');

      if (!isAdmin) {
        query = query.where('assignedTo', isEqualTo: currentUser.uid);
      }

      final querySnapshot = await query
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
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final isAdmin = await _isUserAdmin();
      Query query = _firestore.collection(_collection).where('status', isEqualTo: 'pending');

      if (!isAdmin) {
        query = query.where('assignedTo', isEqualTo: currentUser.uid);
      }

      final querySnapshot = await query
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
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final isAdmin = await _isUserAdmin();
      Query query = _firestore.collection(_collection).where('status', isEqualTo: 'completed');

      if (!isAdmin) {
        query = query.where('assignedTo', isEqualTo: currentUser.uid);
      }

      final querySnapshot = await query
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
  Future<String> createTask({
    required String title,
    required String description,
    required String assignedTo,
    required DateTime deadline,
    required int priority,
  }) async {
    try {
      print('Creating task with following details:'); // Debug log
      print('Title: $title'); // Debug log
      print('AssignedTo: $assignedTo'); // Debug log
      print('Deadline: $deadline'); // Debug log
      print('Priority: $priority'); // Debug log

      // Görevi oluştur
      final taskData = {
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'createdBy': _auth.currentUser?.uid ?? 'system',
        'deadline': Timestamp.fromDate(deadline),
        'priority': priority,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'completedAt': null,
        'attachments': [],
        'metadata': {},
      };

      print('Task data prepared: $taskData'); // Debug log

      final task = await _firestore.collection(_collection).add(taskData);
      
      print('Task created with ID: ${task.id}'); // Debug log

      // Oluşturulan görevi kontrol et
      final createdTask = await task.get();
      print('Created task data: ${createdTask.data()}'); // Debug log

      // Görev atama bildirimi göndermeyi dene
      try {
        final userService = UserService();
        final assignedUser = await userService.getUserById(assignedTo);
        final fcmToken = assignedUser?.fcmToken;
        
        if (fcmToken != null) {
          final notificationService = NotificationService(userService: userService);
          await notificationService.sendChatNotification(
            token: fcmToken,
            sender: 'İş Takip Sistemi',
            message: 'Yeni görev: $title',
            chatId: task.id,
            messageType: 'task',
          );
          print('Notification sent to user: $assignedTo'); // Debug log
        } else {
          print('User FCM token not found for: $assignedTo'); // Debug log
        }
      } catch (e) {
        print('Bildirim gönderme hatası: $e');
      }

      // Değişiklikleri dinleyicilere bildir
      notifyListeners();

      return task.id;
    } catch (e) {
      print('Error creating task: $e');
      print('Stack trace: ${StackTrace.current}'); // Debug log
      throw Exception('Görev oluşturulurken bir hata oluştu: $e');
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
  Future<void> completeTask(String taskId) async {
    try {
      final userService = UserService();
      final notificationService = NotificationService(userService: userService);
      
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Bildirim gönder
      final task = await getTask(taskId);
      if (task != null) {
        final creator = await userService.getUserById(task.createdBy);
        final fcmToken = creator?.fcmToken;
        
        if (fcmToken != null) {
          await notificationService.sendChatNotification(
            token: fcmToken,
            sender: 'İş Takip Sistemi',
            message: '${task.title} görevi tamamlandı',
            chatId: taskId,
            messageType: 'task_completed',
          );
        }
      }
    } catch (e) {
      print('Görev tamamlama hatası: $e');
      rethrow;
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

  // Göreve toplu dosya ekle
  Future<void> addAttachments(String taskId, List<String> filePaths) async {
    try {
      final taskRef = _firestore.collection(_collection).doc(taskId);
      final task = await taskRef.get();
      
      if (!task.exists) {
        throw Exception('Görev bulunamadı');
      }

      final currentAttachments = List<String>.from(task.data()?['attachments'] ?? []);
      currentAttachments.addAll(filePaths);

      await taskRef.update({
        'attachments': currentAttachments,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Dosyalar eklenirken hata oluştu: $e');
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

  // Aktif görevleri stream olarak getir
  Stream<List<TaskModel>> getActiveTasksStream() {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) return Stream.value([]);

      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .orderBy('deadline');

      // Admin değilse sadece kendi görevlerini görsün
      if (currentUser.role != 'admin') {
        query = query.where('assignedTo', isEqualTo: currentUser.id);
      }

      return query
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Error getting active tasks stream: $e');
      return Stream.value([]);
    }
  }

  // Kullanıcının aktif görev sayısını getir
  Future<int> getUserActiveTaskCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('assignedTo', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting user task count: $e');
      return 0;
    }
  }

  // Kullanıcının aktif görev sayısını stream olarak getir
  Stream<int> getUserActiveTaskCountStream(String userId) {
    try {
      return _firestore
          .collection(_collection)
          .where('assignedTo', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      print('Error getting user task count stream: $e');
      return Stream.value(0);
    }
  }

  // Tamamlanan görevleri stream olarak getir
  Stream<List<TaskModel>> getCompletedTasksStream() {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) return Stream.value([]);

      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true);

      // Admin değilse sadece kendi görevlerini görsün
      if (currentUser.role != 'admin') {
        query = query.where('assignedTo', isEqualTo: currentUser.id);
      }

      return query
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList());
    } catch (e) {
      print('Error getting completed tasks stream: $e');
      return Stream.value([]);
    }
  }

  Future<TaskModel?> getTask(String taskId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(taskId).get();
      if (!doc.exists) return null;
      return TaskModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting task: $e');
      return null;
    }
  }

  // Bugün teslim edilecek görevleri getir
  Future<List<TaskModel>> getTodayTasks() async {
    try {
      final userService = UserService();
      final currentUser = userService.currentUser;
      if (currentUser == null) return [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('assignedTo', isEqualTo: currentUser.id)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .where((task) => 
              task.deadline.isAfter(today) &&
              task.deadline.isBefore(tomorrow))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Geciken görevleri getir
  Future<List<TaskModel>> getOverdueTasks() async {
    try {
      final userService = UserService();
      final currentUser = userService.currentUser;
      if (currentUser == null) return [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('assignedTo', isEqualTo: currentUser.id)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .where((task) => task.deadline.isBefore(today))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Yaklaşan görevleri getir
  Future<List<TaskModel>> getUpcomingTasks() async {
    try {
      final userService = UserService();
      final currentUser = userService.currentUser;
      if (currentUser == null) return [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final nextWeek = today.add(const Duration(days: 7));

      final querySnapshot = await _firestore
          .collection(_collection)
          .where('assignedTo', isEqualTo: currentUser.id)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .where((task) => 
              task.deadline.isAfter(today) &&
              task.deadline.isBefore(nextWeek))
          .toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
    } catch (e) {
      return [];
    }
  }

  // Görev eklerini stream olarak getir
  Stream<List<Map<String, dynamic>>> getTaskAttachmentsStream(String taskId) async* {
    try {
      final attachmentsSnapshot = await _firestore
          .collection(_collection)
          .doc(taskId)
          .collection('attachments')
          .orderBy('uploadedAt', descending: true)
          .get();

      final attachments = <Map<String, dynamic>>[];
      
      for (var doc in attachmentsSnapshot.docs) {
        final data = doc.data();
        final localPath = data['localPath'];
        
        if (localPath != null) {
          final file = File(localPath);
          if (await file.exists()) {
            attachments.add({
              'id': doc.id,
              'name': data['name'] ?? path.basename(localPath),
              'localPath': localPath,
              'size': await file.length(),
              'type': data['type'] ?? path.extension(localPath).replaceAll('.', ''),
              'uploadedAt': data['uploadedAt'],
            });
          } else {
            // Dosya yoksa sessizce atla
            await doc.reference.delete();
          }
        }
      }

      yield attachments;
      
      // Stream'i canlı tutmak için Firestore'u dinle
      final stream = _firestore
          .collection(_collection)
          .doc(taskId)
          .collection('attachments')
          .snapshots();
          
      await for (var snapshot in stream) {
        final updatedAttachments = <Map<String, dynamic>>[];
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final localPath = data['localPath'];
          
          if (localPath != null) {
            final file = File(localPath);
            if (await file.exists()) {
              updatedAttachments.add({
                'id': doc.id,
                'name': data['name'] ?? path.basename(localPath),
                'localPath': localPath,
                'size': await file.length(),
                'type': data['type'] ?? path.extension(localPath).replaceAll('.', ''),
                'uploadedAt': data['uploadedAt'],
              });
            } else {
              // Dosya yoksa sessizce atla
              await doc.reference.delete();
            }
          }
        }
        
        yield updatedAttachments;
      }
    } catch (e) {
      print('Dosya listesi alma hatası: $e');
      yield [];
    }
  }

  // Görev yorumlarını stream olarak getir
  Stream<List<CommentModel>> getTaskCommentsStream(String taskId) {
    return _firestore
        .collection(_collection)
        .doc(taskId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              return CommentModel(
                id: doc.id,
                userId: data['userId'] ?? '',
                content: data['content'] ?? '',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            })
            .toList());
  }

  // Göreve dosya yükle
  Future<void> uploadTaskFile(String taskId, File file, String fileName) async {
    try {
      final localStorageService = LocalStorageService();
      final localPath = await localStorageService.saveTaskFile(taskId, file, fileName);
      
      if (localPath == null || !await File(localPath).exists()) {
        throw Exception('Dosya kaydedilemedi');
      }

      await _firestore
          .collection(_collection)
          .doc(taskId)
          .collection('attachments')
          .add({
        'name': fileName,
        'localPath': localPath,
        'uploadedAt': FieldValue.serverTimestamp(),
        'size': file.lengthSync(),
        'type': fileName.split('.').last,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Görev dosyasını sil
  Future<void> deleteTaskFile(String taskId, String filePath) async {
    try {
      final localStorageService = LocalStorageService();
      await localStorageService.deleteTaskFile(taskId, filePath);

      final attachmentsSnapshot = await _firestore
          .collection(_collection)
          .doc(taskId)
          .collection('attachments')
          .where('localPath', isEqualTo: filePath)
          .get();

      for (var doc in attachmentsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Dosya silme hatası: $e');
      rethrow;
    }
  }

  // Göreve yorum ekle
  Future<void> addTaskComment(String taskId, String comment) async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı bilgisi bulunamadı');
      }

      await _firestore
          .collection(_collection)
          .doc(taskId)
          .collection('comments')
          .add({
        'content': comment,
        'userId': currentUser.id,
        'userName': currentUser.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Dosyayı getir
  Future<File?> getTaskFile(String filePath) async {
    try {
      final localStorageService = LocalStorageService();
      return await localStorageService.getTaskFile(filePath);
    } catch (e) {
      print('Dosya getirme hatası: $e');
      return null;
    }
  }

  // Dosya var mı kontrol et
  Future<bool> doesFileExist(String filePath) async {
    try {
      final localStorageService = LocalStorageService();
      return await localStorageService.doesFileExist(filePath);
    } catch (e) {
      print('Dosya kontrol hatası: $e');
      return false;
    }
  }

  // Dosya bilgilerini getir
  Future<Map<String, dynamic>?> getTaskFileInfo(String taskId, String filePath) async {
    try {
      final attachmentsSnapshot = await _firestore
          .collection(_collection)
          .doc(taskId)
          .collection('attachments')
          .where('localPath', isEqualTo: filePath)
          .get();

      if (attachmentsSnapshot.docs.isEmpty) {
        return null;
      }

      final data = attachmentsSnapshot.docs.first.data();
      final file = File(filePath);
      
      if (await file.exists()) {
        final fileSize = await file.length();
        return {
          'name': data['name'] ?? path.basename(filePath),
          'size': fileSize,
          'type': data['type'] ?? path.extension(filePath).replaceAll('.', ''),
          'localPath': filePath,
          'uploadedAt': data['uploadedAt'],
        };
      }
      
      return null;
    } catch (e) {
      print('Dosya bilgisi getirme hatası: $e');
      return null;
    }
  }
}
