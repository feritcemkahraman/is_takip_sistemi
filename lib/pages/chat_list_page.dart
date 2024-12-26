import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'package:shared_preferences.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<ChatPreview> _chats = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');
      
      if (_currentUserId == null) {
        throw Exception('Kullanıcı bilgisi bulunamadı');
      }

      final chatsData = await ApiService.getChatPreviews();
      setState(() {
        _chats = chatsData.map((data) => ChatPreview.fromJson(data)).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Sohbetler yüklenirken bir hata oluştu';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChats,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_chats.isEmpty) {
      return const Center(
        child: Text('Henüz mesaj bulunmuyor'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final isCurrentUser = chat.lastMessage.senderId == _currentUserId;
          
          return ListTile(
            leading: CircleAvatar(
              child: Text(
                chat.otherUser.username.substring(0, 1).toUpperCase(),
              ),
            ),
            title: Text(chat.otherUser.username),
            subtitle: Row(
              children: [
                if (isCurrentUser)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.done_all,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                Expanded(
                  child: Text(
                    chat.lastMessage.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: chat.unreadCount > 0 && !isCurrentUser
                          ? Colors.black
                          : Colors.grey[600],
                      fontWeight: chat.unreadCount > 0 && !isCurrentUser
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('HH:mm').format(chat.lastMessage.createdAt),
                  style: TextStyle(
                    color: chat.unreadCount > 0 && !isCurrentUser
                        ? Colors.blue
                        : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (chat.unreadCount > 0 && !isCurrentUser) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chat.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/chat',
                arguments: chat.otherUser.id,
              );
            },
          );
        },
      ),
    );
  }
}

class ChatPreview {
  final User otherUser;
  final Message lastMessage;
  final int unreadCount;

  ChatPreview({
    required this.otherUser,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    return ChatPreview(
      otherUser: User.fromJson(json['otherUser']),
      lastMessage: Message.fromJson(json['lastMessage']),
      unreadCount: json['unreadCount'],
    );
  }
} 