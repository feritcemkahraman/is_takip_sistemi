import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class FileHelper {
  // Geçici dosya oluştur
  static Future<File?> createTempFile(String title, String extension) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = _sanitizeFileName('${title}_$timestamp.$extension');
      return File('${tempDir.path}/$fileName');
    } catch (e) {
      print('Geçici dosya oluşturulurken hata: $e');
      return null;
    }
  }

  // Dosya adını temizle
  static String _sanitizeFileName(String fileName) {
    // Türkçe karakterleri değiştir
    final turkishChars = {
      'ı': 'i', 'ğ': 'g', 'ü': 'u', 'ş': 's', 'ö': 'o', 'ç': 'c',
      'İ': 'I', 'Ğ': 'G', 'Ü': 'U', 'Ş': 'S', 'Ö': 'O', 'Ç': 'C'
    };
    
    String cleanName = fileName;
    turkishChars.forEach((key, value) {
      cleanName = cleanName.replaceAll(key, value);
    });

    // Sadece alfanumerik karakterler, tire ve alt çizgi kullan
    return cleanName.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '_')
        .replaceAll(RegExp(r'_+'), '_'); // Birden fazla alt çizgiyi tekleştir
  }

  // Geçici dosyaları temizle
  static Future<void> cleanupTempFiles({Duration? maxAge}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      final now = DateTime.now();
      final maxAgeDate = now.subtract(maxAge ?? const Duration(days: 1));
      
      for (var file in files) {
        if (file is File && 
            (file.path.endsWith('.pdf') || file.path.endsWith('.xlsx'))) {
          final stat = await file.stat();
          if (stat.modified.isBefore(maxAgeDate)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Geçici dosyalar temizlenirken hata: $e');
    }
  }

  // Dosya boyutunu kontrol et
  static Future<bool> checkFileSize(File file, {int maxSizeMB = 10}) async {
    try {
      final sizeInBytes = await file.length();
      final sizeInMB = sizeInBytes / (1024 * 1024);
      return sizeInMB <= maxSizeMB;
    } catch (e) {
      print('Dosya boyutu kontrol edilirken hata: $e');
      return false;
    }
  }

  // Dosya izinlerini kontrol et
  static Future<bool> checkFilePermissions(File file) async {
    try {
      // Okuma izni kontrolü
      final canRead = await file.exists();
      if (!canRead) return false;

      // Yazma izni kontrolü
      try {
        final tempContent = await file.readAsBytes();
        await file.writeAsBytes(tempContent);
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      print('Dosya izinleri kontrol edilirken hata: $e');
      return false;
    }
  }

  // Desteklenen dosya formatları
  static final supportedFormats = {
    'pdf': 'application/pdf',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'csv': 'text/csv',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  };

  // MIME tipini kontrol et
  static bool isValidMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return supportedFormats.containsKey(extension);
  }

  // Dosya yolunu kontrol et
  static bool isValidPath(String path) {
    // Tehlikeli karakterleri kontrol et
    if (path.contains('..') || path.contains('/')) return false;
    
    // Sadece izin verilen karakterleri kontrol et
    return RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(path);
  }

  // Dosyayı parçalı olarak oku
  static Stream<List<int>> readFileInChunks(File file, {int chunkSize = 1024 * 1024}) async* {
    final reader = file.openRead();
    List<int> buffer = [];

    await for (var chunk in reader) {
      buffer.addAll(chunk);
      while (buffer.length >= chunkSize) {
        yield buffer.sublist(0, chunkSize);
        buffer = buffer.sublist(chunkSize);
      }
    }

    if (buffer.isNotEmpty) {
      yield buffer;
    }
  }

  // Dosyayı parçalı olarak yaz
  static Future<void> writeFileInChunks(
    File file,
    Stream<List<int>> chunks,
  ) async {
    final writer = file.openWrite();
    try {
      await for (var chunk in chunks) {
        writer.add(chunk);
      }
    } finally {
      await writer.close();
    }
  }

  // Dosya transferi için ilerleme durumu
  static Stream<double> transferWithProgress(File source, File destination) async* {
    final length = await source.length();
    var transferred = 0;

    final reader = source.openRead();
    final writer = destination.openWrite();

    await for (var chunk in reader) {
      writer.add(chunk);
      transferred += chunk.length;
      yield transferred / length;
    }

    await writer.close();
  }

  // Büyük dosyalar için parçalı transfer
  static Future<bool> chunkedTransfer(
    File source,
    File destination, {
    int chunkSize = 1024 * 1024, // 1MB chunks
    Function(double)? onProgress,
  }) async {
    try {
      final length = await source.length();
      var transferred = 0;
      final reader = source.openRead();
      final writer = destination.openWrite();

      await for (var chunk in reader) {
        writer.add(chunk);
        transferred += chunk.length;
        onProgress?.call(transferred / length);
      }

      await writer.close();
      return true;
    } catch (e) {
      print('Parçalı transfer hatası: $e');
      return false;
    }
  }
}