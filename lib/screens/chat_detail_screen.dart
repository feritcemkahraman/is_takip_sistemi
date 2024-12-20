import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_info_screen.dart';
import '../widgets/message_bubble.dart';
import '../widgets/emoji_picker_widget.dart';

class ChatDetailScreen extends StatelessWidget {
  final ChatModel chat;

  const ChatDetailScreen({
    Key? key,
    required this.chat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserService>().currentUser;
    if (currentUser == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatInfoScreen(chat: chat),
              ),
            );
          },
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: chat.isGroup ? Colors.blue : Colors.purple,
                  child: chat.avatar != null
                      ? ClipOval(
                          child: Image.network(
                            chat.avatar!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          chat.isGroup ? Icons.group : Icons.person,
                          color: Colors.white,
                        ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StreamBuilder<List<UserModel>>(
                      stream: context.read<ChatService>().getChatParticipants(chat.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final participants = snapshot.data!;
                        return Text(
                          chat.isGroup
                              ? '${participants.length} katılımcı'
                              : participants
                                  .where((p) => p.id != currentUser.id)
                                  .map((p) => p.department)
                                  .join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[200],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'mute':
                  await context.read<ChatService>().toggleMuteChat(chat.id);
                  break;
                case 'info':
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatInfoScreen(chat: chat),
                      ),
                    );
                  }
                  break;
                case 'delete':
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
                    await context.read<ChatService>().deleteChat(chat.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(
                      chat.mutedBy.contains(currentUser.id)
                          ? Icons.notifications_off
                          : Icons.notifications,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      chat.mutedBy.contains(currentUser.id)
                          ? 'Bildirimleri Aç'
                          : 'Sessize Al',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'info',
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Sohbet Bilgileri'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Sohbeti Sil'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: context.read<ChatService>().getChatMessages(chat.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          chat.isGroup ? Icons.group : Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          chat.isGroup
                              ? 'Gruba hoş geldiniz!\nİlk mesajı siz gönderin.'
                              : 'Sohbete hoş geldiniz!\nİlk mesajı siz gönderin.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMe = message.senderId == currentUser.id;
                    final showDate = index == messages.length - 1 ||
                        !_isSameDay(
                          messages[messages.length - 2 - index].createdAt,
                          message.createdAt,
                        );

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              _formatMessageDate(message.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        FutureBuilder<UserModel?>(
                          future: context.read<UserService>().getUserById(message.senderId),
                          builder: (context, senderSnapshot) {
                            return MessageBubble(
                              message: message,
                              isMe: isMe,
                              chat: chat,
                              senderName: senderSnapshot.data?.name,
                              onLongPress: isMe ? () => _showDeleteDialog(context, message) : null,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _MessageInput(chat: chat),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Bugün';
    } else if (messageDate == yesterday) {
      return 'Dün';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Ocak';
      case 2: return 'Şubat';
      case 3: return 'Mart';
      case 4: return 'Nisan';
      case 5: return 'Mayıs';
      case 6: return 'Haziran';
      case 7: return 'Temmuz';
      case 8: return 'Ağustos';
      case 9: return 'Eylül';
      case 10: return 'Ekim';
      case 11: return 'Kasım';
      case 12: return 'Aralık';
      default: return '';
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, MessageModel message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Sil'),
        content: const Text('Bu mesajı silmek istediğinizden emin misiniz?'),
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
        await context.read<ChatService>().deleteMessage(chat.id, message.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }
}

class _MessageInput extends StatefulWidget {
  final ChatModel chat;

  const _MessageInput({
    Key? key,
    required this.chat,
  }) : super(key: key);

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  bool _showEmoji = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await context.read<ChatService>().sendMessage(
        chatId: widget.chat.id,
        content: content,
      );

      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _isLoading = true);
        await context.read<ChatService>().sendFileMessage(
          chatId: widget.chat.id,
          filePath: pickedFile.path,
          fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim gönderilemedi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() => _isLoading = true);
        await context.read<ChatService>().sendFileMessage(
          chatId: widget.chat.id,
          filePath: result.files.single.path!,
          fileName: result.files.single.name,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya gönderilemedi: $e')),
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
    return Column(
      children: [
        if (_showEmoji) EmojiPickerWidget(
          onEmojiSelected: (emoji) {
            _controller.text += emoji;
          },
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: Colors.grey[600],
                  ),
                  onPressed: () => setState(() => _showEmoji = !_showEmoji),
                ),
                IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: Colors.grey[600],
                  ),
                  onPressed: _pickAndSendFile,
                ),
                IconButton(
                  icon: Icon(
                    Icons.image,
                    color: Colors.grey[600],
                  ),
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Mesaj yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
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
                      : Icon(
                          Icons.send,
                          color: Theme.of(context).primaryColor,
                        ),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 