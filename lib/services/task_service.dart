import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:is_takip_sistemi/config/api_config.dart';
import 'package:is_takip_sistemi/models/task_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class TaskService {
  final http.Client _client;
  late final io.Socket _socket;

  TaskService({http.Client? client}) : _client = client ?? http.Client() {
    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
  }

  Future<void> connect() async {
    final token = await _getToken();
    if (token != null) {
      _socket.io.options?['extraHeaders'] = {
        'Authorization': 'Bearer $token'
      };
      _socket.connect();
    }
  }

  void disconnect() {
    _socket.disconnect();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required String assignedTo,
    required DateTime deadline,
    required int priority,
  }) async {
    final token = await _getToken();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tasks}'),
      headers: ApiConfig.getHeaders(token: token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'deadline': deadline.toIso8601String(),
        'priority': priority,
      }),
    );

    if (response.statusCode == 201) {
      return TaskModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Görev oluşturulamadı');
    }
  }

  Future<List<TaskModel>> getTasks({
    String? assignedTo,
    String? status,
    int? priority,
  }) async {
    final token = await _getToken();
    final queryParams = <String, String>{};
    if (assignedTo != null) queryParams['assignedTo'] = assignedTo;
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tasks}')
        .replace(queryParameters: queryParams);

    final response = await _client.get(
      uri,
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TaskModel.fromJson(json)).toList();
    } else {
      throw Exception('Görevler alınamadı');
    }
  }

  Future<TaskModel> getTaskById(String taskId) async {
    final token = await _getToken();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.taskById}$taskId'),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      return TaskModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Görev bulunamadı');
    }
  }

  Future<TaskModel> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? assignedTo,
    DateTime? deadline,
    int? priority,
    String? status,
  }) async {
    final token = await _getToken();
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.taskById}$taskId'),
      headers: ApiConfig.getHeaders(token: token),
      body: jsonEncode({
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (assignedTo != null) 'assignedTo': assignedTo,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
        if (priority != null) 'priority': priority,
        if (status != null) 'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return TaskModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Görev güncellenemedi');
    }
  }

  Future<void> deleteTask(String taskId) async {
    final token = await _getToken();
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.taskById}$taskId'),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode != 204) {
      throw Exception('Görev silinemedi');
    }
  }

  Future<CommentModel> addComment(String taskId, String content) async {
    final token = await _getToken();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.taskComments}$taskId'),
      headers: ApiConfig.getHeaders(token: token),
      body: jsonEncode({
        'content': content,
      }),
    );

    if (response.statusCode == 201) {
      return CommentModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Yorum eklenemedi');
    }
  }

  Stream<TaskModel> onTaskUpdated() {
    return _socket.fromEvent('task_updated').map((data) {
      return TaskModel.fromJson(data);
    });
  }

  Stream<CommentModel> onNewComment() {
    return _socket.fromEvent('new_comment').map((data) {
      return CommentModel.fromJson(data);
    });
  }

  void dispose() {
    _socket.dispose();
    _client.close();
  }
}
