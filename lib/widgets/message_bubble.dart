import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<UserService>().currentUser;
    final isMe = currentUser?.id == message.senderId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachments.isNotEmpty) ...[
              for (var attachment in message.attachments)
                _buildAttachmentPreview(attachment),
              const SizedBox(height: 8),
            ],
            Text(
              message.content,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(MessageAttachment attachment) {
    switch (attachment.type) {
      case MessageModel.typeImage:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            attachment.url,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        );
      default:
        return ListTile(
          leading: const Icon(Icons.attach_file),
          title: Text(attachment.name),
          subtitle: Text(attachment.formattedSize),
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
} 