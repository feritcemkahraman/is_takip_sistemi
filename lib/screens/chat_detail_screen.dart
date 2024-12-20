import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../widgets/message_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    required this.otherUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;
  late UserService _userService;
  late NotificationService _notificationService;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);
    _notificationService = Provider.of<NotificationService>(context, listen: false);
    _loadFcmToken();
  }

  Future<void> _loadFcmToken() async {
    // Diğer kullanıcının FCM token'ını Firestore'dan al
    final tokenDoc = await FirebaseFirestore.instance
        .collection('fcm_tokens')
        .where('userId', isEqualTo: widget.otherUser.id)
        .get();

    if (tokenDoc.docs.isNotEmpty) {
      setState(() {
        _fcmToken = tokenDoc.docs.first.id;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = MessageModel(
      senderId: _userService.currentUser!.id,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
      type: 'text',
    );

    try {
      await _chatService.sendMessage(widget.chatId, message);
      _messageController.clear();
      _scrollToBottom();

      // Bildirim gönder
      if (_fcmToken != null) {
        await _notificationService.sendNotification(
          token: _fcmToken!,
          title: '${_userService.currentUser!.name}\'den yeni mesaj',
          body: message.content,
          data: {
            'type': 'message',
            'chatId': widget.chatId,
            'senderId': _userService.currentUser!.id,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj gönderilemedi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Bir hata oluştu'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _userService.currentUser!.id;
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 