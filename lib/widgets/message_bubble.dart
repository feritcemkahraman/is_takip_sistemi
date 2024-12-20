import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final ChatModel chat;
  final String? senderName;
  final VoidCallback? onLongPress;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.chat,
    this.senderName,
    this.onLongPress,
  }) : super(key: key);

  String _formatTime() {
    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      message.createdAt.year,
      message.createdAt.month,
      message.createdAt.day,
    );

    if (messageDate == today) {
      return '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Dün ${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${message.createdAt.day}/${message.createdAt.month}/${message.createdAt.year} ${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (chat.isGroup && !isMe && senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                senderName!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          GestureDetector(
            onLongPress: onLongPress,
            child: Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isMe ? 12 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 12),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.type != MessageModel.typeText)
                        _buildAttachment(context),
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    if (message.attachmentUrl == null) return const SizedBox.shrink();

    switch (message.type) {
      case MessageModel.typeImage:
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.attachmentUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        );
      default:
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.attach_file),
          title: Text(
            'Dosya: ${message.content}',
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
            ),
          ),
          onTap: () {
            // TODO: Implement file download/open
          },
        );
    }
  }
} 