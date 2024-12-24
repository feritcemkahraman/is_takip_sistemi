import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import 'dart:io';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    Key? key, 
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            if (message.type != MessageModel.typeText) ...[
              _buildAttachmentPreview(message),
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

  Widget _buildAttachmentPreview(MessageModel message) {
    if (message.attachmentUrl == null) return const SizedBox();

    switch (message.type) {
      case MessageModel.typeImage:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(message.attachmentUrl!),
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error),
                ),
              );
            },
          ),
        );
      case MessageModel.typeFile:
        return ListTile(
          leading: const Icon(Icons.attach_file),
          title: Text(message.content),
          contentPadding: EdgeInsets.zero,
          dense: true,
          onTap: () async {
            try {
              final file = File(message.attachmentUrl!);
              if (await file.exists()) {
                // Dosyayı aç
                // TODO: Implement file opening
              }
            } catch (e) {
              print('Dosya açma hatası: $e');
            }
          },
        );
      default:
        return const SizedBox();
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
} 