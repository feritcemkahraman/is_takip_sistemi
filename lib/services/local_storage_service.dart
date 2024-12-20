import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalStorageService {
  Future<Directory> get _appDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  Future<Directory> get _taskAttachmentsDir async {
    final dir = await _appDir;
    final taskDir = Directory('${dir.path}/tasks');
    if (!await taskDir.exists()) {
      await taskDir.create(recursive: true);
    }
    return taskDir;
  }

  Future<File> saveFile(File file, String fileName) async {
    final dir = await _appDir;
    final extension = path.extension(file.path);
    final newPath = path.join(dir.path, '$fileName$extension');
    return await file.copy(newPath);
  }

  Future<String> saveTaskAttachment(String taskId, String fileName, File file) async {
    final dir = await _taskAttachmentsDir;
    final taskDir = Directory('${dir.path}/$taskId');
    if (!await taskDir.exists()) {
      await taskDir.create(recursive: true);
    }
    final extension = path.extension(file.path);
    final newPath = path.join(taskDir.path, '$fileName$extension');
    final savedFile = await file.copy(newPath);
    return savedFile.path;
  }

  Future<File?> getTaskAttachment(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  Future<void> deleteTaskAttachments(String taskId) async {
    final dir = await _taskAttachmentsDir;
    final taskDir = Directory('${dir.path}/$taskId');
    if (await taskDir.exists()) {
      await taskDir.delete(recursive: true);
    }
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<File>> getAllFiles() async {
    final dir = await _appDir;
    final files = await dir.list().toList();
    return files.whereType<File>().toList();
  }

  Future<void> clearCache() async {
    final dir = await _appDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
