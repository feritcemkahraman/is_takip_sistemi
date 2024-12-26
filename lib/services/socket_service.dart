import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'notification_service.dart';

class SocketService {
  static IO.Socket? _socket;
  static String? _userId;

  static void init(String userId) {
    if (_socket != null) {
      _socket!.disconnect();
    }

    _userId = userId;

    _socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();
    _socket!.emit('joinUser', userId);

    _setupListeners();
  }

  static void _setupListeners() {
    _socket?.on('taskNotification', (data) {
      NotificationService.showTaskNotification(
        title: data['title'],
        body: data['body'],
        payload: data['taskId'],
      );
    });

    _socket?.on('messageNotification', (data) {
      NotificationService.showMessageNotification(
        title: data['title'],
        body: data['body'],
        payload: data['messageId'],
      );
    });

    _socket?.on('userTyping', (data) {
      // Kullanıcı yazıyor bildirimi için event yayınla
      // Provider veya başka bir state management çözümü ile kullanılabilir
    });
  }

  static void joinTask(String taskId) {
    _socket?.emit('joinTask', taskId);
  }

  static void leaveTask(String taskId) {
    _socket?.emit('leaveTask', taskId);
  }

  static void sendTypingStatus(String receiverId, bool isTyping) {
    _socket?.emit('typing', {
      'userId': _userId,
      'receiverId': receiverId,
      'typing': isTyping,
    });
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _userId = null;
  }
} 