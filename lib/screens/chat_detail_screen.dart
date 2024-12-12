import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import 'chat_info_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatModel chat;
  final String currentUserId;

  const ChatDetailScreen({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _chatService = ChatService();
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _isAttachmentMenuOpen = false;
  MessageModel? _replyMessage;

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    await _chatService.sendMessage(
      chatId: widget.chat.id,
      content: text,
      type: MessageModel.typeText,
      senderId: widget.currentUserId,
      replyTo: _replyMessage?.id,
    );

    _textController.clear();
    setState(() => _replyMessage = null);
  }

  void _handleAttachmentPressed(String type) async {
    setState(() => _isAttachmentMenuOpen = false);

    switch (type) {
      case 'image':
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          await _chatService.sendFileMessage(
            chatId: widget.chat.id,
            senderId: widget.currentUserId,
            filePath: image.path,
            fileName: image.name,
            type: MessageModel.typeImage,
            replyTo: _replyMessage?.id,
          );
        }
        break;

      case 'file':
        final result = await FilePicker.platform.pickFiles();
        if (result != null) {
          final file = File(result.files.single.path!);
          await _chatService.sendFileMessage(
            chatId: widget.chat.id,
            senderId: widget.currentUserId,
            filePath: file.path,
            fileName: result.files.single.name,
            type: MessageModel.typeFile,
            replyTo: _replyMessage?.id,
          );
        }
        break;

      case 'voice':
        // TODO: Sesli mesaj kaydetme özelliği eklenecek
        break;
    }

    setState(() => _replyMessage = null);
  }

  void _handleMessageLongPress(MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.senderId == widget.currentUserId)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Sil'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _chatService.deleteMessage(
                      widget.chat.id,
                      message.id,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Yanıtla'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _replyMessage = message);
                },
              ),
              if (!message.isReadBy(widget.currentUserId))
                ListTile(
                  leading: const Icon(Icons.mark_chat_read),
                  title: const Text('Okundu olarak işaretle'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _chatService.markMessageAsRead(
                      widget.chat.id,
                      message.id,
                      widget.currentUserId,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatInfoScreen(
                  chat: widget.chat,
                  currentUserId: widget.currentUserId,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.chat
                        .getChatAvatar(widget.currentUserId)
                        .startsWith('http')
                    ? NetworkImage(widget.chat.getChatAvatar(widget.currentUserId))
                    : AssetImage(widget.chat.getChatAvatar(widget.currentUserId))
                        as ImageProvider,
                radius: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chat.getChatName(widget.currentUserId),
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (widget.chat.isGroupChat)
                      Text(
                        '${widget.chat.participants.length} üye',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Sohbet menüsü
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getChatMessages(widget.chat.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Bir hata oluştu: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
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
                    final isMe = message.senderId == widget.currentUserId;

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      chat: widget.chat,
                      onLongPress: () => _handleMessageLongPress(message),
                    );
                  },
                );
              },
            ),
          ),
          if (_replyMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _replyMessage!.senderId == widget.currentUserId
                              ? 'Sen'
                              : widget.chat
                                  .participantNames[_replyMessage!.senderId]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _replyMessage!.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _replyMessage = null),
                  ),
                ],
              ),
            ),
          ChatInput(
            controller: _textController,
            onSendPressed: _handleSendMessage,
            onAttachmentPressed: () {
              setState(() => _isAttachmentMenuOpen = !_isAttachmentMenuOpen);
            },
          ),
          if (_isAttachmentMenuOpen)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: () => _handleAttachmentPressed('image'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () => _handleAttachmentPressed('file'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () => _handleAttachmentPressed('voice'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 