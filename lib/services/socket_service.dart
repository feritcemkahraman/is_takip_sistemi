import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class SocketService {
  static IO.Socket? _socket;
  static String? _userId;

  static void init(String userId) {
    _userId = userId;
    
    _socket = IO.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'userId': userId},
    });

    _socket?.connect();

    _socket?.onConnect((_) {
      print('Socket.IO bağlantısı kuruldu');
    });

    _socket?.onDisconnect((_) {
      print('Socket.IO bağlantısı kesildi');
    });

    _socket?.onError((error) {
      print('Socket.IO hatası: $error');
    });
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _userId = null;
  }

  static void joinTask(String taskId) {
    _socket?.emit('join_task', {'taskId': taskId});
  }

  static void leaveTask(String taskId) {
    _socket?.emit('leave_task', {'taskId': taskId});
  }

  static void onMessageReceived(Function(Map<String, dynamic>) callback) {
    _socket?.on('message', (data) => callback(data));
  }

  static void onTaskUpdated(Function(Map<String, dynamic>) callback) {
    _socket?.on('task_updated', (data) => callback(data));
  }

  static void onCommentAdded(Function(Map<String, dynamic>) callback) {
    _socket?.on('comment_added', (data) => callback(data));
  }

  static void onTypingStatusChanged(Function(Map<String, dynamic>) callback) {
    _socket?.on('typing', (data) => callback(data));
  }

  static void sendTypingStatus(String receiverId, bool isTyping) {
    _socket?.emit('typing', {
      'receiverId': receiverId,
      'typing': isTyping,
    });
  }

  static void onUserStatusChanged(Function(Map<String, dynamic>) callback) {
    _socket?.on('user_status', (data) => callback(data));
  }

  static void updateUserStatus(String status) {
    _socket?.emit('user_status', {'status': status});
  }
} 