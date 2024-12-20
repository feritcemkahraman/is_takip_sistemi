import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'package:provider/provider.dart';

class ChatMediaScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatMediaScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatMediaScreen> createState() => _ChatMediaScreenState();
}

class _ChatMediaScreenState extends State<ChatMediaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatService = ChatService(userService: UserService());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildMediaGrid(String type) {
    return StreamBuilder<List<MessageModel>>(
      stream: _chatService.getMessages(widget.chat.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Bir hata oluştu'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data!
            .where((message) => message.attachments.any((a) => a.type == type))
            .toList();

        if (messages.isEmpty) {
          return const Center(child: Text('Medya bulunamadı'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final attachment = message.attachments.firstWhere((a) => a.type == type);
            return _buildMediaPreview(message, attachment);
          },
        );
      },
    );
  }

  Widget _buildMediaPreview(MessageModel message, MessageAttachment attachment) {
    switch (attachment.type) {
      case MessageModel.typeImage:
        return InkWell(
          onTap: () => _showImageViewer(attachment.url),
          child: Image.network(
            attachment.url,
            fit: BoxFit.cover,
          ),
        );
      case MessageModel.typeVideo:
        return InkWell(
          onTap: () => _showVideoPlayer(attachment.url),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                attachment.url,
                fit: BoxFit.cover,
              ),
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      case MessageModel.typeVoice:
        return InkWell(
          onTap: () => _playAudio(attachment.url),
          child: Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.mic, size: 32),
            ),
          ),
        );
      case MessageModel.typeFile:
        return InkWell(
          onTap: () => _openFile(attachment.url),
          child: Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getFileIcon(attachment.fileExtension ?? ''),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  attachment.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showImageViewer(String url) {
    // TODO: Implement image viewer
  }

  void _showVideoPlayer(String url) {
    // TODO: Implement video player
  }

  void _playAudio(String url) {
    // TODO: Implement audio player
  }

  void _openFile(String url) {
    // TODO: Implement file opener
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medya'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Resimler'),
            Tab(text: 'Videolar'),
            Tab(text: 'Sesler'),
            Tab(text: 'Dosyalar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMediaGrid(MessageModel.typeImage),
          _buildMediaGrid(MessageModel.typeVideo),
          _buildMediaGrid(MessageModel.typeVoice),
          _buildMediaGrid(MessageModel.typeFile),
        ],
      ),
    );
  }
} 