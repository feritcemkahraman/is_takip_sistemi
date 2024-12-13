import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/user_selector_widget.dart';

class ChatSettingsScreen extends StatefulWidget {
  final ChatModel chat;
  final String currentUserId;

  const ChatSettingsScreen({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  final _chatService = ChatService();
  final _authService = AuthService();
  final _storageService = StorageService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdmin = false;
  bool _isLoading = false;
  File? _avatarFile;
  bool _muteNotifications = false;
  bool _blockChat = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeSettings() async {
    setState(() => _isLoading = true);

    try {
      _nameController.text = widget.chat.name ?? '';
      _descriptionController.text = widget.chat.description ?? '';
      _isAdmin = widget.chat.createdBy == widget.currentUserId;

      // Bildirim ve engelleme durumlarını yükle
      final settings = await _chatService.getChatSettings(
        widget.chat.id,
        widget.currentUserId,
      );
      setState(() {
        _muteNotifications = settings['mute'] ?? false;
        _blockChat = settings['block'] ?? false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _avatarFile = File(image.path));
    }
  }

  Future<void> _updateSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await _storageService.uploadFile(
          _avatarFile!.path,
          'chat_avatars/${widget.chat.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      await _chatService.updateChat(
        widget.chat.id,
        {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          if (avatarUrl != null) 'avatar': avatarUrl,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar güncellendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme hatası: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleNotifications() async {
    setState(() => _isLoading = true);

    try {
      await _chatService.updateChatSettings(
        widget.chat.id,
        widget.currentUserId,
        {'mute': !_muteNotifications},
      );

      setState(() => _muteNotifications = !_muteNotifications);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bildirim ayarları güncellenemedi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_blockChat ? 'Engeli Kaldır' : 'Sohbeti Engelle'),
        content: Text(_blockChat
            ? 'Bu sohbetin engelini kaldırmak istediğinize emin misiniz?'
            : 'Bu sohbeti engellemek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_blockChat ? 'Engeli Kaldır' : 'Engelle'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _chatService.updateChatSettings(
        widget.chat.id,
        widget.currentUserId,
        {'block': !_blockChat},
      );

      setState(() => _blockChat = !_blockChat);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Engelleme ayarları güncellenemedi: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbetten Ayrıl'),
        content: const Text('Bu sohbetten ayrılmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _chatService.leaveChat(
        widget.chat.id,
        widget.currentUserId,
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayrılma hatası: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addParticipants(List<String> userIds) async {
    if (!_isAdmin || userIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _chatService.addParticipants(
        widget.chat.id,
        userIds,
        widget.currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Katılımcılar eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Katılımcı ekleme hatası: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeParticipant(String userId) async {
    if (!_isAdmin) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Katılımcıyı Çıkar'),
        content: const Text('Bu katılımcıyı çıkarmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _chatService.removeParticipant(
        widget.chat.id,
        userId,
        widget.currentUserId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Katılımcı çıkarıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Katılımcı çıkarma hatası: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbet Ayarları'),
        actions: [
          if (_isAdmin)
            TextButton(
              onPressed: _updateSettings,
              child: const Text(
                'Kaydet',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.chat.isGroupChat) ...[
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: _avatarFile != null
                                  ? FileImage(_avatarFile!)
                                  : widget.chat
                                          .getChatAvatar(widget.currentUserId)
                                          .startsWith('http')
                                      ? NetworkImage(widget.chat
                                          .getChatAvatar(widget.currentUserId))
                                      : AssetImage(widget.chat
                                          .getChatAvatar(widget.currentUserId))
                                          as ImageProvider,
                            ),
                            if (_isAdmin)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    color: Colors.white,
                                    onPressed: _pickAvatar,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Grup Adı',
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isAdmin,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Grup adı gereklidir';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        enabled: _isAdmin,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Katılımcılar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.chat.participants.length,
                        itemBuilder: (context, index) {
                          final userId = widget.chat.participants[index];
                          final isCreator = userId == widget.chat.createdBy;
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(widget.chat
                                      .participantNames[userId]?[0]
                                      .toUpperCase() ??
                                  '?'),
                            ),
                            title: Text(
                              widget.chat.participantNames[userId] ??
                                  'Bilinmeyen Kullanıcı',
                            ),
                            subtitle: isCreator
                                ? const Text(
                                    'Grup Yöneticisi',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                            trailing: _isAdmin && userId != widget.currentUserId
                                ? IconButton(
                                    icon: const Icon(Icons.remove_circle),
                                    color: Colors.red,
                                    onPressed: () => _removeParticipant(userId),
                                  )
                                : null,
                          );
                        },
                      ),
                      if (_isAdmin) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => SizedBox(
                                height: 400,
                                child: UserSelectorWidget(
                                  selectedUserIds: widget.chat.participants,
                                  multiSelect: true,
                                  onUsersSelected: (userIds) {
                                    Navigator.pop(context);
                                    _addParticipants(userIds);
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Katılımcı Ekle'),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                    const Text(
                      'Bildirim Ayarları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Bildirimleri Sessize Al'),
                      subtitle: Text(
                        _muteNotifications
                            ? 'Bildirimler kapalı'
                            : 'Bildirimler açık',
                      ),
                      value: _muteNotifications,
                      onChanged: (value) => _toggleNotifications(),
                    ),
                    const Divider(),
                    const Text(
                      'Gizlilik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Sohbeti Engelle'),
                      subtitle: Text(
                        _blockChat
                            ? 'Bu sohbetten mesaj alamazsınız'
                            : 'Bu sohbetten mesaj alabilirsiniz',
                      ),
                      value: _blockChat,
                      onChanged: (value) => _toggleBlock(),
                    ),
                    const SizedBox(height: 32),
                    if (widget.chat.isGroupChat && !_isAdmin ||
                        !widget.chat.isGroupChat)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _leaveChat,
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('Sohbetten Ayrıl'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
} 