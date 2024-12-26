import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileService {
  static Future<String> uploadFile(File file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/files/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Token'ı ekle
      request.headers['Authorization'] = 'Bearer $token';

      // Dosya tipini belirle
      final mimeType = lookupMimeType(file.path);
      
      // Dosyayı ekle
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: path.basename(file.path),
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );
      
      request.files.add(multipartFile);

      // İsteği gönder
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception('Dosya yüklenirken bir hata oluştu');
      }

      // Sunucudan dönen dosya URL'ini al
      final responseData = json.decode(responseBody);
      return responseData['url'];
    } catch (e) {
      throw Exception('Dosya yüklenirken bir hata oluştu: $e');
    }
  }

  static Future<File> downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        throw Exception('Dosya indirilirken bir hata oluştu');
      }

      // Geçici dizini al
      final tempDir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final filePath = path.join(tempDir.path, fileName);

      // Dosyayı kaydet
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return file;
    } catch (e) {
      throw Exception('Dosya indirilirken bir hata oluştu: $e');
    }
  }

  static Future<void> deleteFile(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Token bulunamadı');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/files/delete');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'url': url}),
      );

      if (response.statusCode != 200) {
        throw Exception('Dosya silinirken bir hata oluştu');
      }
    } catch (e) {
      throw Exception('Dosya silinirken bir hata oluştu: $e');
    }
  }
} 