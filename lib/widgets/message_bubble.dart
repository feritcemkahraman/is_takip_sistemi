import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'message_attachment_preview.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final ChatModel chat;
  final VoidCallback onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.chat,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && chat.isGroupChat)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                chat.participantNames[message.senderId] ?? 'Bilinmeyen Kullanıcı',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              margin: EdgeInsets.only(
                left: isMe ? 32 : 12,
                right: isMe ? 12 : 32,
              ),
              decoration: BoxDecoration(
                color: _getBubbleColor(theme),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.replyTo != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.reply, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Yanıtlanan mesaj',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.hasAttachments)
                          ...message.attachments.map(
                            (attachment) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: MessageAttachmentPreview(
                                attachment: attachment,
                                message: message,
                              ),
                            ),
                          ),
                        if (!message.isDeleted)
                          Text(
                            message.content,
                            style: TextStyle(
                              color: _getTextColor(theme),
                              fontSize: 16,
                            ),
                          )
                        else
                          Text(
                            'Bu mesaj silindi',
                            style: TextStyle(
                              color: _getTextColor(theme).withOpacity(0.7),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeago.format(message.createdAt, locale: 'tr'),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getTextColor(theme).withOpacity(0.7),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.readBy.isEmpty
                                    ? Icons.check
                                    : Icons.done_all,
                                size: 14,
                                color: message.readBy.isEmpty
                                    ? _getTextColor(theme).withOpacity(0.7)
                                    : Colors.blue,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBubbleColor(ThemeData theme) {
    if (message.isSystemMessage) {
      return theme.colorScheme.surface;
    }
    return isMe ? theme.colorScheme.primary : theme.colorScheme.surface;
  }

  Color _getTextColor(ThemeData theme) {
    if (message.isSystemMessage) {
      return theme.colorScheme.onSurface;
    }
    return isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
  }
} 