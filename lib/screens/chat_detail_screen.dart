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

class ChatDetailScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatDetailScreen({
    Key? key,
    required this.chat,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;
  late UserService _userService;
  bool _isEmojiVisible = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _chatService.getCurrentUser();
      setState(() => _currentUser = user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcı bilgileri yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final file = File(result.files.single.path!);
        await _chatService.sendFileMessage(
          chatId: widget.chat.id,
          filePath: file.path,
          fileName: result.files.single.name,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya gönderilirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        await _chatService.sendFileMessage(
          chatId: widget.chat.id,
          filePath: pickedFile.path,
          fileName: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resim gönderilirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _deleteMessage(MessageModel message) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mesajı Sil'),
          content: const Text('Bu mesajı silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil'),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await _chatService.deleteMessage(
          widget.chat.id,
          message.id,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj silinemedi: $e')),
        );
      }
    }
  }

  void _toggleEmojiPicker() {
    setState(() => _isEmojiVisible = !_isEmojiVisible);
  }

  void _onEmojiSelected(String emoji) {
    _messageController.text += emoji;
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

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
    }
  }

  void _showGroupInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatInfoScreen(chat: widget.chat),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Chat isGroup: ${widget.chat.isGroup}');
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: widget.chat.isGroup ? _showGroupInfo : null,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.chat.isGroup ? Colors.blue : Colors.purple,
                  child: widget.chat.avatar != null
                      ? ClipOval(
                          child: Image.network(
                            widget.chat.avatar!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          widget.chat.isGroup ? Icons.group : Icons.person,
                          color: Colors.white,
                        ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.chat.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (widget.chat.isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showGroupInfo,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _chatService.getChatParticipants(widget.chat.id),
              builder: (context, participantsSnapshot) {
                final participantMap = participantsSnapshot.data?.fold<Map<String, String>>(
                  {},
                  (map, user) => map..[user.id] = user.name,
                ) ?? {};

                return StreamBuilder<List<MessageModel>>(
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
                      controller: _scrollController,
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = _currentUser?.id == message.senderId;
                        final senderName = participantMap[message.senderId];

                        return MessageBubble(
                          message: message,
                          isMe: isMe,
                          chat: widget.chat,
                          senderName: senderName,
                          onLongPress: isMe ? () => _deleteMessage(message) : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Container(
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
              child: Column(
                children: [
                  if (_isEmojiVisible)
                    EmojiPickerWidget(
                      onEmojiSelected: _onEmojiSelected,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isEmojiVisible
                                ? Icons.keyboard
                                : Icons.emoji_emotions_outlined,
                          ),
                          onPressed: _toggleEmojiPicker,
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: _pickAndSendFile,
                        ),
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: _pickAndSendImage,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Mesaj yazın...',
                              border: InputBorder.none,
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