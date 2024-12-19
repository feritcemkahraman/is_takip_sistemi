import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  final UserModel currentUser;

  const ChatScreen({
    Key? key,
    required this.chat,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final ChatService _chatService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chatService = context.read<ChatService>();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markAllMessagesAsRead(widget.chat.id);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _chatService.sendMessage(
        chatId: widget.chat.id,
        content: message,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chat.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Henüz mesaj yok'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMyMessage = message.senderId == widget.currentUser.id;

                    return Align(
                      alignment: isMyMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          left: isMyMessage ? 64 : 16,
                          right: isMyMessage ? 16 : 64,
                          top: 8,
                          bottom: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMyMessage
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.attachment != null) ...[
                              Image.network(
                                message.attachment!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              message.content,
                              style: TextStyle(
                                color: isMyMessage ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      hintText: 'Mesaj yazın...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 