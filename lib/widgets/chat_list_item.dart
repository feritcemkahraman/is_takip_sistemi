import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

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

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbeti Sil'),
        content: const Text('Bu sohbeti silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await context.read<ChatService>().deleteChat(chat.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sohbet silindi')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          chat.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        chat.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: chat.lastMessage != null
          ? Text(
              _getLastMessagePreview(chat.lastMessage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : const Text('Henüz mesaj yok'),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) async {
          if (value == 'delete') {
            await _handleDelete(context);
          } else if (value == 'mute') {
            try {
              if (chat.mutedBy.contains(currentUserId)) {
                await context.read<ChatService>().unmuteChatNotifications(chat.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bildirimler açıldı')),
                  );
                }
              } else {
                await context.read<ChatService>().muteChatNotifications(chat.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sohbet sessize alındı')),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            }
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'mute',
            child: Row(
              children: [
                Icon(
                  chat.mutedBy.contains(currentUserId)
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  chat.mutedBy.contains(currentUserId)
                      ? 'Bildirimleri Aç'
                      : 'Sessize Al',
                ),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Sohbeti Sil', style: TextStyle(color: Colors.red)),
              ],
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