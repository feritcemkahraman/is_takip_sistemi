import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalStorageService {
  // Görev dosyaları için ana dizini al
  Future<String> get _taskFilesDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final taskFilesDir = Directory(path.join(appDir.path, 'task_files'));
    if (!await taskFilesDir.exists()) {
      await taskFilesDir.create(recursive: true);
    }
    return taskFilesDir.path;
  }

  // Medya dosyaları için ana dizini al
  Future<String> get _mediaDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(path.join(appDir.path, 'media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir.path;
  }

  // Görev için dosya dizinini al
  Future<String> _getTaskDir(String taskId) async {
    final baseDir = await _taskFilesDir;
    final taskDir = Directory(path.join(baseDir, taskId));
    if (!await taskDir.exists()) {
      await taskDir.create(recursive: true);
    }
    return taskDir.path;
  }

  // Genel dosya kaydetme metodu
  Future<String> saveFile(File file, String fileName) async {
    try {
      final mediaDir = await _mediaDir;
      final safeFileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + 
          fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');
      final targetPath = path.join(mediaDir, safeFileName);
      
      // Dosyayı kopyala
      await file.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      print('Dosya kaydetme hatası: $e');
      rethrow;
    }
  }

  // Görev eki kaydetme metodu
  Future<String> saveTaskAttachment(String taskId, String fileName, File file) async {
    try {
      final taskDir = await _getTaskDir(taskId);
      final safeFileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + 
          fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_');
      final targetPath = path.join(taskDir, safeFileName);
      
      // Dosyayı kopyala
      await file.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      print('Görev eki kaydetme hatası: $e');
      rethrow;
    }
  }

  // Dosyayı kaydet
  Future<String> saveTaskFile(String taskId, File file, String fileName) async {
    try {
      final taskDir = await _getTaskDir(taskId);
      
      // Dosya adını güvenli hale getir
      final extension = path.extension(fileName);
      final baseName = path.basenameWithoutExtension(fileName)
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final safeFileName = '${DateTime.now().millisecondsSinceEpoch}_$baseName$extension';
      
      final targetPath = path.join(taskDir, safeFileName);
      
      // Dosyayı kopyala
      await file.copy(targetPath);
      
      return targetPath;
    } catch (e) {
      print('Dosya kaydetme hatası: $e');
      rethrow;
    }
  }

  // Dosyayı sil
  Future<void> deleteTaskFile(String taskId, String filePath) async {
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

  // Görev dosyalarını getir
  Future<List<String>> getTaskAttachments(String taskId) async {
    try {
      final taskDir = await _getTaskDir(taskId);
      final directory = Directory(taskDir);
      
      if (!await directory.exists()) {
        return [];
      }

      final files = await directory
          .list()
          .where((entity) => entity is File)
          .map((entity) => entity.path)
          .toList();

      return files;
    } catch (e) {
      print('Dosya listesi alma hatası: $e');
      return [];
    }
  }

  // Tüm görev dosyalarını sil
  Future<void> deleteTaskAttachments(String taskId) async {
    try {
      final taskDir = await _getTaskDir(taskId);
      final directory = Directory(taskDir);
      
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      print('Görev dosyaları silme hatası: $e');
      rethrow;
    }
  }

  // Dosya boyutunu formatla
  String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Dosyayı oku
  Future<File?> getTaskFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Dosya okuma hatası: $e');
      return null;
    }
  }

  // Dosya var mı kontrol et
  Future<bool> doesFileExist(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      print('Dosya kontrol hatası: $e');
      return false;
    }
  }
}
