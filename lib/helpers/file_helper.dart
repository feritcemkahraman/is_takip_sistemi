import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FileHelper {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadFile(File file, String folder) async {
    try {
      final fileName = path.basename(file.path);
      final destination = '$folder/$fileName';
      final ref = _storage.ref(destination);
      
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Dosya yükleme hatası: $e');
      return null;
    }
  }

  static Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Dosya silme hatası: $e');
      return false;
    }
  }

  static Future<List<String>> uploadMultipleFiles(List<File> files, String folder) async {
    final List<String> uploadedUrls = [];
    
    for (final file in files) {
      final url = await uploadFile(file, folder);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }

  static Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Dosya seçme hatası: $e');
      return null;
    }
  }

  static Future<List<File>> pickMultipleFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      
      if (result != null) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
      return [];
    } catch (e) {
      print('Çoklu dosya seçme hatası: $e');
      return [];
    }
  }

  static String getFileExtension(String fileName) {
    return path.extension(fileName).toLowerCase();
  }

  static bool isImageFile(String fileName) {
    final ext = getFileExtension(fileName);
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
  }

  static bool isPdfFile(String fileName) {
    return getFileExtension(fileName) == '.pdf';
  }

  static bool isDocumentFile(String fileName) {
    final ext = getFileExtension(fileName);
    return ['.doc', '.docx', '.txt', '.pdf'].contains(ext);
  }
}
