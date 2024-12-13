import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../widgets/chat_list_item.dart';
import '../widgets/message_bubble.dart';
import 'chat_detail_screen.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  String? _currentUserId;
  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _showMessages = false;
  String _selectedFilter = 'all'; // all, unread, media
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    final user = await _chatService.getCurrentUser();
    if (user != null) {
      setState(() => _currentUserId = user.uid);
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty && _selectedFilter == 'all' && _startDate == null) {
      setState(() {
        _chats = [];
        _messages = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_showMessages) {
        final messages = await _chatService.searchMessages(
          query,
          _currentUserId!,
          filter: _selectedFilter,
          startDate: _startDate,
          endDate: _endDate,
        );
        setState(() => _messages = messages);
      } else {
        final chats = await _chatService.searchChats(
          query,
          _currentUserId!,
          filter: _selectedFilter,
          startDate: _startDate,
          endDate: _endDate,
        );
        setState(() => _chats = chats);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama hatası: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Arama Filtreleri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedFilter,
                decoration: const InputDecoration(
                  labelText: 'Filtre',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Tümü'),
                  ),
                  DropdownMenuItem(
                    value: 'unread',
                    child: Text('Okunmamış'),
                  ),
                  DropdownMenuItem(
                    value: 'media',
                    child: Text('Medya'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedFilter = value!);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_startDate == null
                          ? 'Başlangıç'
                          : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_endDate == null
                          ? 'Bitiş'
                          : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'all';
                  _startDate = null;
                  _endDate = null;
                });
              },
              child: const Text('Sıfırla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'filter': _selectedFilter,
                  'startDate': _startDate,
                  'endDate': _endDate,
                });
              },
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedFilter = result['filter'];
        _startDate = result['startDate'];
        _endDate = result['endDate'];
      });
      _search(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Sohbet veya mesaj ara...',
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.white70),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: _search,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showMessages ? Icons.chat : Icons.message,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showMessages = !_showMessages;
                _search(_searchController.text);
              });
            },
            tooltip: _showMessages ? 'Sohbetlerde Ara' : 'Mesajlarda Ara',
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list, color: Colors.white),
                if (_selectedFilter != 'all' || _startDate != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrele',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showMessages
              ? _buildMessageList()
              : _buildChatList(),
    );
  }

  Widget _buildChatList() {
    if (_chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Aramaya başlamak için bir şeyler yazın'
                  : 'Sohbet bulunamadı',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return ChatListItem(
          chat: chat,
          currentUserId: _currentUserId!,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chat: chat,
                  currentUserId: _currentUserId!,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Aramaya başlamak için bir şeyler yazın'
                  : 'Mesaj bulunamadı',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return FutureBuilder<ChatModel?>(
          future: _chatService.getChat(message.chatId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final chat = snapshot.data!;
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      chat: chat,
                      currentUserId: _currentUserId!,
                      initialMessageId: message.id,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: chat
                                  .getChatAvatar(_currentUserId!)
                                  .startsWith('http')
                              ? NetworkImage(
                                  chat.getChatAvatar(_currentUserId!))
                              : AssetImage(chat.getChatAvatar(_currentUserId!))
                                  as ImageProvider,
                          radius: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chat.getChatName(_currentUserId!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${message.createdAt.day}/${message.createdAt.month}/${message.createdAt.year} ${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  MessageBubble(
                    message: message,
                    isMe: message.senderId == _currentUserId,
                    chat: chat,
                    onLongPress: () {},
                  ),
                  const Divider(),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 