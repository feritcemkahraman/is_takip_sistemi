import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadFile(String folderPath, File file) async {
    try {
      final fileName = path.basename(file.path);
      final ref = _storage.ref().child('$folderPath/$fileName');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Dosya yüklenemedi: $e');
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Dosya silinemedi: $e');
    }
  }

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    return uploadFile('profile_images/$userId', imageFile);
  }

  Future<String> uploadChatImage(String chatId, File imageFile) async {
    return uploadFile('chat_images/$chatId', imageFile);
  }

  Future<String> uploadTaskAttachment(String taskId, File file) async {
    return uploadFile('task_attachments/$taskId', file);
  }
} 