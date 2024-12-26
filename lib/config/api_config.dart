import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:3000';
  static String get socketUrl => dotenv.env['SOCKET_URL'] ?? 'http://localhost:3000';
  
  static Map<String, String> getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String changePassword = '/users/change-password';
  
  // Task Endpoints
  static const String tasks = '/tasks';
  static const String taskById = '/tasks/'; // + taskId
  static const String taskComments = '/tasks/comments/'; // + taskId
  static const String taskAttachments = '/tasks/attachments/'; // + taskId
  
  // Chat Endpoints
  static const String chats = '/chats';
  static const String chatById = '/chats/'; // + chatId
  static const String messages = '/messages';
  static const String messageById = '/messages/'; // + messageId
  
  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String notificationById = '/notifications/'; // + notificationId
  static const String markNotificationRead = '/notifications/read/'; // + notificationId
  
  // User Endpoints
  static const String users = '/users';
  static const String userById = '/users/'; // + userId
  static const String searchUsers = '/users/search';
} 