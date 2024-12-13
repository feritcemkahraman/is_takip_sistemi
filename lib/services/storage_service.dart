import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:flutter/material.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Dosya yükleme
  Future<String> uploadFile({
    required File file,
    required String taskId,
    required String userId,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final mimeType = lookupMimeType(fileName);
      final extension = path.extension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newFileName = '${timestamp}_$fileName';

      final ref = _storage
          .ref()
          .child('tasks')
          .child(taskId)
          .child('attachments')
          .child(newFileName);

      final metadata = SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'userId': userId,
          'fileName': fileName,
          'uploadedAt': DateTime.now().toIso8601String(),
          'fileType': extension,
        },
      );

      final uploadTask = await ref.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Dosya yüklenirken bir hata oluştu: $e';
    }
  }

  // Dosya silme
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw 'Dosya silinirken bir hata oluştu: $e';
    }
  }

  // Dosya bilgilerini getir
  Future<Map<String, dynamic>> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();
      
      return {
        'fileName': metadata.customMetadata?['fileName'] ?? '',
        'uploadedAt': metadata.customMetadata?['uploadedAt'] ?? '',
        'userId': metadata.customMetadata?['userId'] ?? '',
        'fileType': metadata.customMetadata?['fileType'] ?? '',
        'size': metadata.size ?? 0,
        'contentType': metadata.contentType ?? '',
      };
    } catch (e) {
      throw 'Dosya bilgileri alınırken bir hata oluştu: $e';
    }
  }

  // Dosya listesini getir
  Future<List<Map<String, dynamic>>> getTaskFiles(String taskId) async {
    try {
      final ref = _storage.ref().child('tasks').child(taskId).child('attachments');
      final result = await ref.listAll();
      
      final files = await Future.wait(
        result.items.map((item) async {
          final url = await item.getDownloadURL();
          final metadata = await item.getMetadata();
          
          return {
            'url': url,
            'fileName': metadata.customMetadata?['fileName'] ?? '',
            'uploadedAt': metadata.customMetadata?['uploadedAt'] ?? '',
            'userId': metadata.customMetadata?['userId'] ?? '',
            'fileType': metadata.customMetadata?['fileType'] ?? '',
            'size': metadata.size ?? 0,
            'contentType': metadata.contentType ?? '',
          };
        }),
      );

      return files;
    } catch (e) {
      throw 'Dosya listesi alınırken bir hata oluştu: $e';
    }
  }

  // Dosya boyutunu formatla
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Dosya türüne göre icon getir
  IconData getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image;
      case '.mp4':
      case '.avi':
      case '.mov':
        return Icons.video_library;
      default:
        return Icons.insert_drive_file;
    }
  }
} 