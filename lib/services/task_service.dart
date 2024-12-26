import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/task_model.dart';

class TaskService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<TaskModel>> getAllTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Görevler alınırken bir hata oluştu: $e');
    }
  }

  Future<TaskModel> getTaskById(String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return TaskModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Görev alınırken bir hata oluştu: $e');
    }
  }

  Future<TaskModel> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: await _getHeaders(),
        body: jsonEncode(taskData),
      );

      if (response.statusCode == 201) {
        return TaskModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Görev oluşturulurken bir hata oluştu: $e');
    }
  }

  Future<TaskModel> updateTask(String taskId, Map<String, dynamic> taskData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: await _getHeaders(),
        body: jsonEncode(taskData),
      );

      if (response.statusCode == 200) {
        return TaskModel.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Görev güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Görev silinirken bir hata oluştu: $e');
    }
  }

  Future<List<TaskModel>> getTasksByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks?status=$status'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Görevler alınırken bir hata oluştu: $e');
    }
  }

  Future<List<TaskModel>> getTasksByAssignee(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks?assignee=$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Görevler alınırken bir hata oluştu: $e');
    }
  }

  Future<void> addComment(String taskId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/$taskId/comments'),
        headers: await _getHeaders(),
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode != 201) {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Yorum eklenirken bir hata oluştu: $e');
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/status'),
        headers: await _getHeaders(),
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Görev durumu güncellenirken bir hata oluştu: $e');
    }
  }

  Future<void> assignTask(String taskId, String userId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/tasks/$taskId/assign'),
        headers: await _getHeaders(),
        body: jsonEncode({'assigneeId': userId}),
      );

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Görev atanırken bir hata oluştu: $e');
    }
  }

  Future<void> uploadTaskAttachment(String taskId, List<int> fileBytes, String filename) async {
    try {
      final uri = Uri.parse('$baseUrl/tasks/$taskId/attachments');
      final request = http.MultipartRequest('POST', uri);
      
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 201) {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Dosya yüklenirken bir hata oluştu: $e');
    }
  }

  Future<void> deleteTaskAttachment(String taskId, String attachmentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId/attachments/$attachmentId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Dosya silinirken bir hata oluştu: $e');
    }
  }
}
