import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../widgets/message_attachment_preview.dart';

class ChatMediaScreen extends StatefulWidget {
  final ChatModel chat;
  final String currentUserId;

  const ChatMediaScreen({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  State<ChatMediaScreen> createState() => _ChatMediaScreenState();
}

class _ChatMediaScreenState extends State<ChatMediaScreen>
    with SingleTickerProviderStateMixin {
  final _chatService = ChatService();
  late TabController _tabController;
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  String _selectedView = 'grid'; // grid, list
  String _sortBy = 'date'; // date, size, name
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMessages();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Seçili sekme değiştiğinde listeyi güncelle
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await _chatService.getChatMediaMessages(widget.chat.id);
      setState(() => _messages = messages);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Medya yükleme hatası: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<MessageModel> _getFilteredMessages(String type) {
    var messages = _messages.where((message) {
      return message.attachments.any((attachment) => attachment.type == type);
    }).toList();

    // Sıralama
    messages.sort((a, b) {
      switch (_sortBy) {
        case 'date':
          return _sortAscending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt);
        case 'size':
          final sizeA = a.attachments.first.size;
          final sizeB = b.attachments.first.size;
          return _sortAscending
              ? sizeA.compareTo(sizeB)
              : sizeB.compareTo(sizeA);
        case 'name':
          final nameA = a.attachments.first.name;
          final nameB = b.attachments.first.name;
          return _sortAscending
              ? nameA.compareTo(nameB)
              : nameB.compareTo(nameA);
        default:
          return 0;
      }
    });

    return messages;
  }

  Future<void> _showSortingOptions() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sıralama Seçenekleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tarihe Göre'),
              value: 'date',
              groupValue: _sortBy,
              onChanged: (value) {
                Navigator.pop(context, {
                  'sortBy': value,
                  'ascending': value == _sortBy ? !_sortAscending : false,
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Boyuta Göre'),
              value: 'size',
              groupValue: _sortBy,
              onChanged: (value) {
                Navigator.pop(context, {
                  'sortBy': value,
                  'ascending': value == _sortBy ? !_sortAscending : false,
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('İsme Göre'),
              value: 'name',
              groupValue: _sortBy,
              onChanged: (value) {
                Navigator.pop(context, {
                  'sortBy': value,
                  'ascending': value == _sortBy ? !_sortAscending : false,
                });
              },
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _sortBy = result['sortBy'];
        _sortAscending = result['ascending'];
      });
    }
  }

  Future<void> _shareMedia(MessageAttachment attachment) async {
    try {
      await Share.share(
        attachment.url,
        subject: attachment.name,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paylaşım hatası: $e')),
        );
      }
    }
  }

  Widget _buildMediaGrid(String type) {
    final messages = _getFilteredMessages(type);

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(type),
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(type),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_selectedView == 'list') {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final attachment = message.attachments.firstWhere(
            (attachment) => attachment.type == type,
          );

          return Card(
            child: ListTile(
              leading: SizedBox(
                width: 48,
                height: 48,
                child: _buildMediaPreview(type, attachment),
              ),
              title: Text(attachment.name),
              subtitle: Text(
                '${attachment.formattedSize} • ${_formatDate(message.createdAt)}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      _shareMedia(attachment);
                      break;
                    case 'preview':
                      _showMediaPreview(message, attachment);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 8),
                        Text('Önizle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Paylaş'),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _showMediaPreview(message, attachment),
            ),
          );
        },
      );
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
        final attachment = message.attachments.firstWhere(
          (attachment) => attachment.type == type,
        );

        return GestureDetector(
          onTap: () => _showMediaPreview(message, attachment),
          onLongPress: () => _showMediaOptions(message, attachment),
          child: Hero(
            tag: attachment.id,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(child: _buildMediaPreview(type, attachment)),
                  if (type != MessageModel.typeImage)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          attachment.formattedSize,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMediaOptions(MessageModel message, MessageAttachment attachment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Önizle'),
              onTap: () {
                Navigator.pop(context);
                _showMediaPreview(message, attachment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Paylaş'),
              onTap: () {
                Navigator.pop(context);
                _shareMedia(attachment);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaPreview(MessageModel message, MessageAttachment attachment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(attachment.name),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareMedia(attachment),
                ),
              ],
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MessageAttachmentPreview(
                      message: message,
                      attachment: attachment,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Boyut: ${attachment.formattedSize}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tarih: ${_formatDate(message.createdAt)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (attachment.mimeType != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Tür: ${attachment.mimeType}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(String type, MessageAttachment attachment) {
    switch (type) {
      case MessageModel.typeImage:
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            attachment.url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.error));
            },
          ),
        );

      case MessageModel.typeVideo:
        return const Center(
          child: Icon(Icons.play_circle_filled, size: 48),
        );

      case MessageModel.typeVoice:
        return const Center(
          child: Icon(Icons.mic, size: 32),
        );

      case MessageModel.typeFile:
      default:
        return Center(
          child: Icon(
            _getFileIcon(attachment.fileExtension),
            size: 32,
          ),
        );
    }
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
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  IconData _getEmptyIcon(String type) {
    switch (type) {
      case MessageModel.typeImage:
        return Icons.image_not_supported;
      case MessageModel.typeVideo:
        return Icons.videocam_off;
      case MessageModel.typeVoice:
        return Icons.mic_off;
      case MessageModel.typeFile:
      default:
        return Icons.folder_off;
    }
  }

  String _getEmptyMessage(String type) {
    switch (type) {
      case MessageModel.typeImage:
        return 'Henüz fotoğraf paylaşılmadı';
      case MessageModel.typeVideo:
        return 'Henüz video paylaşılmadı';
      case MessageModel.typeVoice:
        return 'Henüz sesli mesaj paylaşılmadı';
      case MessageModel.typeFile:
      default:
        return 'Henüz dosya paylaşılmadı';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medya Galerisi'),
        actions: [
          IconButton(
            icon: Icon(_selectedView == 'grid' ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _selectedView = _selectedView == 'grid' ? 'list' : 'grid';
              });
            },
            tooltip: _selectedView == 'grid' ? 'Liste Görünümü' : 'Izgara Görünümü',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortingOptions,
            tooltip: 'Sırala',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Fotoğraflar'),
            Tab(text: 'Videolar'),
            Tab(text: 'Sesler'),
            Tab(text: 'Dosyalar'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
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