import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:is_takip_sistemi/config/api_config.dart';
import 'package:is_takip_sistemi/models/chat_model.dart';
import 'package:is_takip_sistemi/models/message_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChatService {
  final http.Client _client;
  final io.Socket _socket;
  
  ChatService({http.Client? client})
      : _client = client ?? http.Client(),
        _socket = io.io(
          ApiConfig.socketUrl,
          io.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .build(),
        );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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

  Future<ChatModel> createChat(String user2Id) async {
    final token = await _getToken();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chats}'),
      headers: ApiConfig.getHeaders(token: token),
      body: jsonEncode({
        'user2Id': user2Id,
      }),
    );

    if (response.statusCode == 201) {
      return ChatModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Sohbet oluşturulamadı');
    }
  }

  Future<List<ChatModel>> getChats() async {
    final token = await _getToken();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chats}'),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ChatModel.fromJson(json)).toList();
    } else {
      throw Exception('Sohbetler alınamadı');
    }
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    final token = await _getToken();
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatById}$chatId/messages'),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception('Mesajlar alınamadı');
    }
  }

  Future<MessageModel> sendMessage(String chatId, String content) async {
    final token = await _getToken();
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatById}$chatId/messages'),
      headers: ApiConfig.getHeaders(token: token),
      body: jsonEncode({
        'content': content,
      }),
    );

    if (response.statusCode == 201) {
      return MessageModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Mesaj gönderilemedi');
    }
  }

  Future<void> markAsRead(String chatId) async {
    final token = await _getToken();
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.chatById}$chatId/read'),
      headers: ApiConfig.getHeaders(token: token),
    );

    if (response.statusCode != 200) {
      throw Exception('Mesajlar okundu olarak işaretlenemedi');
    }
  }

  Stream<MessageModel> onNewMessage() {
    return _socket.fromEvent('new_message').map((data) {
      return MessageModel.fromJson(data);
    });
  }

  Stream<ChatModel> onChatUpdated() {
    return _socket.fromEvent('chat_updated').map((data) {
      return ChatModel.fromJson(data);
    });
  }

  void dispose() {
    _socket.dispose();
    _client.close();
  }
} 