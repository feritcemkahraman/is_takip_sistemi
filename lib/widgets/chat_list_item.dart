import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = chat.lastMessage;
    final unreadCount = chat.getUnreadCount(currentUserId);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: chat.getChatAvatar(currentUserId).startsWith('http')
            ? NetworkImage(chat.getChatAvatar(currentUserId))
            : AssetImage(chat.getChatAvatar(currentUserId)) as ImageProvider,
        child: chat.getChatAvatar(currentUserId).startsWith('assets')
            ? Icon(
                chat.isGroupChat ? Icons.group : Icons.person,
                color: Colors.white,
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.getChatName(currentUserId),
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lastMessage != null)
            Text(
              timeago.format(lastMessage.createdAt, locale: 'tr'),
              style: TextStyle(
                fontSize: 12,
                color: unreadCount > 0 ? Colors.blue : Colors.grey,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              _getLastMessagePreview(lastMessage),
              style: TextStyle(
                color: unreadCount > 0 ? Colors.black87 : Colors.grey,
                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getLastMessagePreview(MessageModel? message) {
    if (message == null) {
      return 'Henüz mesaj yok';
    }

    if (message.isDeleted) {
      return 'Bu mesaj silindi';
    }

    if (message.isSystemMessage) {
      return message.content;
    }

    final prefix = message.senderId == currentUserId ? 'Sen: ' : '';

    switch (message.type) {
      case MessageModel.typeText:
        return '$prefix${message.content}';
      case MessageModel.typeImage:
        return '${prefix}📷 Fotoğraf';
      case MessageModel.typeFile:
        return '${prefix}📎 Dosya: ${message.content}';
      case MessageModel.typeVoice:
        return '${prefix}🎤 Sesli mesaj';
      case MessageModel.typeVideo:
        return '${prefix}🎥 Video';
      default:
        return '$prefix${message.content}';
    }
  }
} 