import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalStorageService extends ChangeNotifier {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final taskAttachmentsDir = Directory('${directory.path}/task_attachments');
    if (!await taskAttachmentsDir.exists()) {
      await taskAttachmentsDir.create(recursive: true);
    }
    return taskAttachmentsDir.path;
  }

  Future<String> saveTaskAttachment(String taskId, String fileName, File file) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      
      // Görev klasörünü oluştur
      final taskDir = Directory(path.join(await _localPath, taskId));
      if (!await taskDir.exists()) {
        await taskDir.create(recursive: true);
      }

      // Dosyayı kopyala
      final savedFile = await file.copy(path.join(taskDir.path, uniqueFileName));
      print('Dosya kaydedildi: ${savedFile.path}');
      
      return savedFile.path;
    } catch (e) {
      print('Dosya kaydetme hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteTaskAttachment(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Dosya silme hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteTaskAttachments(String taskId) async {
    try {
      final taskDir = Directory(path.join(await _localPath, taskId));
      if (await taskDir.exists()) {
        await taskDir.delete(recursive: true);
      }
    } catch (e) {
      print('Görev dosyaları silme hatası: $e');
      rethrow;
    }
  }

  // Dosyayı açmak için yardımcı metod
  Future<File?> getTaskAttachment(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Dosya getirme hatası: $e');
      return null;
    }
  }
}
