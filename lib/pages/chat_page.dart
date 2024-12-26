import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/file_service.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class ChatPage extends StatefulWidget {
  final String userId;

  const ChatPage({
    super.key,
    required this.userId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  User? _otherUser;
  String? _currentUserId;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  bool _isTyping = false;
  DateTime? _lastTypingNotification;

  @override
  void initState() {
    super.initState();
    _loadChat();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupSocketListeners() {
    SocketService.onMessageReceived((data) {
      if (data['senderId'] == widget.userId) {
        setState(() {
          _messages.insert(0, Message.fromJson(data));
        });
      }
    });

    SocketService.onTypingStatusChanged((data) {
      if (data['userId'] == widget.userId) {
        setState(() {
          _isTyping = data['typing'];
        });
      }
    });
  }

  Future<void> _loadChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');
      
      if (_currentUserId == null) {
        throw Exception('Kullanıcı bilgisi bulunamadı');
      }

      final userData = await ApiService.getUserById(widget.userId);
      final messagesData = await ApiService.getMessages(widget.userId);

      setState(() {
        _otherUser = User.fromJson(userData);
        _messages = messagesData.map((data) => Message.fromJson(data)).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Mesajlar yüklenirken bir hata oluştu';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleTyping(String text) {
    final now = DateTime.now();
    if (_lastTypingNotification == null ||
        now.difference(_lastTypingNotification!) > const Duration(seconds: 2)) {
      _lastTypingNotification = now;
      SocketService.sendTypingStatus(widget.userId, text.isNotEmpty);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.sendMessage(widget.userId, text);
      setState(() {
        _messages.insert(0, Message.fromJson(response));
      });
      _messageController.clear();
      SocketService.sendTypingStatus(widget.userId, false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Mesaj gönderilirken bir hata oluştu';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        final file = File(result.files.single.path!);
        final url = await FileService.uploadFile(file);
        
        // Dosyayı mesaj olarak gönder
        final response = await ApiService.sendMessage(
          widget.userId,
          path.basename(file.path), // Dosya adını mesaj olarak gönder
          attachments: [url],
        );

        setState(() {
          _messages.insert(0, Message.fromJson(response));
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Dosya yüklenirken bir hata oluştu';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    try {
      final picker = ImagePicker();
      final result = await (fromCamera
          ? picker.pickImage(source: ImageSource.camera)
          : picker.pickImage(source: ImageSource.gallery));

      if (result != null) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        final file = File(result.path);
        final url = await FileService.uploadFile(file);
        
        // Resmi mesaj olarak gönder
        final response = await ApiService.sendMessage(
          widget.userId,
          'Fotoğraf',
          attachments: [url],
        );

        setState(() {
          _messages.insert(0, Message.fromJson(response));
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fotoğraf yüklenirken bir hata oluştu';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(fromCamera: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(fromCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Dosya'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(Message message) {
    if (message.attachments.isEmpty) {
      return Text(
        message.content,
        style: TextStyle(
          color: message.senderId == _currentUserId
              ? Colors.white
              : Colors.black,
        ),
      );
    }

    final attachment = message.attachments.first;
    final extension = path.extension(attachment).toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png', '.gif'].contains(extension);

    if (isImage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              attachment,
              width: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
          if (message.content != 'Fotoğraf')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                message.content,
                style: TextStyle(
                  color: message.senderId == _currentUserId
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            try {
              final file = await FileService.downloadFile(attachment);
              await OpenFile.open(file.path);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dosya açılırken bir hata oluştu'),
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: message.senderId == _currentUserId
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 20,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  message.content,
                  style: TextStyle(
                    color: message.senderId == _currentUserId
                        ? Colors.white
                        : Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _otherUser != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_otherUser!.username),
                  if (_isTyping)
                    const Text(
                      'yazıyor...',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadChat,
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isCurrentUser = message.senderId == _currentUserId;

                        return Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.blue
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: isCurrentUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                _buildMessageContent(message),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('HH:mm').format(message.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isCurrentUser
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _isLoading ? null : _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _handleTyping,
                    decoration: const InputDecoration(
                      hintText: 'Mesaj yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 