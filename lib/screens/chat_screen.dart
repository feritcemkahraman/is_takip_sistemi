import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/local_storage_service.dart';
import 'chat_media_screen.dart';
import '../widgets/message_bubble.dart';
import '../widgets/emoji_picker_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  final bool isNewChat;

  const ChatScreen({
    Key? key,
    required this.chat,
    this.isNewChat = false,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final LocalStorageService _storageService = LocalStorageService();
  late final ChatService _chatService;
  late final UserService _userService;
  bool _isLoading = false;
  bool _showEmoji = false;
  ChatModel? _createdChat;
  String get _activeChatId => _createdChat?.id ?? widget.chat.id;

  @override
  void initState() {
    super.initState();
    _chatService = context.read<ChatService>();
    _userService = context.read<UserService>();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (widget.isNewChat) {
      // Önce mevcut sohbeti kontrol et
      final existingChat = await _chatService.findExistingChat(widget.chat.participants.first);
      if (existingChat != null) {
        setState(() => _createdChat = existingChat);
      }
    }
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    if (!widget.isNewChat) {
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id);
      
      final messagesRef = chatRef
          .collection('messages')
          .where('readBy', whereNotIn: [currentUser.id]);

      final messagesSnapshot = await messagesRef.get();

      if (messagesSnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();

        for (final doc in messagesSnapshot.docs) {
          final List<dynamic> readBy = List<dynamic>.from(doc.data()['readBy'] ?? []);
          if (!readBy.contains(currentUser.id)) {
            batch.update(doc.reference, {
              'readBy': FieldValue.arrayUnion([currentUser.id])
            });
          }
        }

        batch.update(chatRef, {'unreadCount': 0});
        await batch.commit();
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      if (widget.isNewChat && _createdChat == null) {
        // Önce mevcut sohbeti kontrol et
        final existingChat = await _chatService.findExistingChat(widget.chat.participants.first);
        if (existingChat != null) {
          _createdChat = existingChat;
        } else {
          // Yeni sohbet oluştur
          _createdChat = await _chatService.createChat(
            name: widget.chat.name,
            participants: widget.chat.participants,
            isGroup: widget.chat.isGroup,
          );
        }
      }

      await _chatService.sendMessage(
        chatId: _createdChat?.id ?? widget.chat.id,
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final file = File(image.path);
      await _sendFile(file, 'image');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = File(result.files.first.path!);
    final fileName = result.files.first.name;

    setState(() => _isLoading = true);

    try {
      if (widget.isNewChat && _createdChat == null) {
        _createdChat = await _chatService.createChat(
          name: widget.chat.name,
          participants: widget.chat.participants,
          isGroup: widget.chat.isGroup,
        );
      }

      final chatId = _createdChat?.id ?? widget.chat.id;
      final savedFilePath = await _storageService.saveFile(file, fileName);

      await _chatService.sendMessage(
        chatId: chatId,
        content: fileName,
        type: MessageModel.typeFile,
        attachmentUrl: savedFilePath,
      );
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

  Future<void> _sendFile(File file, String type) async {
    setState(() => _isLoading = true);

    try {
      if (widget.isNewChat && _createdChat == null) {
        _createdChat = await _chatService.createChat(
          name: widget.chat.name,
          participants: widget.chat.participants,
          isGroup: widget.chat.isGroup,
        );
      }

      final chatId = _createdChat?.id ?? widget.chat.id;
      final fileName = file.path.split('/').last;
      final savedFilePath = await _storageService.saveFile(file, fileName);

      await _chatService.sendMessage(
        chatId: chatId,
        content: type == 'image' ? 'Fotoğraf' : fileName,
        type: type == 'image' ? MessageModel.typeImage : MessageModel.typeFile,
        attachmentUrl: savedFilePath,
      );
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

  void _toggleEmojiPicker() {
    setState(() => _showEmoji = !_showEmoji);
  }

  void _onEmojiSelected(String emoji) {
    _messageController.text += emoji;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(_activeChatId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;

                  if (messages.isEmpty) {
                    return const Center(child: Text('Henüz mesaj yok'));
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == _userService.currentUser?.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MessageBubble(
                          message: message,
                          isMe: isMe,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickFile,
                    color: Theme.of(context).primaryColor,
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo),
                    onPressed: _pickImage,
                    color: Theme.of(context).primaryColor,
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Mesaj yazın...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send),
                            onPressed: _isLoading ? null : _sendMessage,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
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

  Future<void> _showDeleteDialog(MessageModel message) async {
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

    if (confirm == true && mounted) {
      try {
        await _chatService.deleteMessage(widget.chat.id, message.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }
} 