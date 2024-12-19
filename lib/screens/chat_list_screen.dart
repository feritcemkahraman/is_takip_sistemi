import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/user_search_delegate.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = false;

  Future<void> _showNewChatDialog(BuildContext context) async {
    try {
      final userService = context.read<UserService>();
      final chatService = context.read<ChatService>();
      final currentUser = userService.currentUser;

      if (currentUser == null) return;

      setState(() => _isLoading = true);

      // Tüm kullanıcıları getir
      final users = await userService.getAllUsers();
      // Mevcut kullanıcıyı listeden çıkar
      users.removeWhere((user) => user.id == currentUser.id);

      if (!mounted) return;

      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Yeni Sohbet'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: UserSearchDelegate(
                        userService: userService,
                        chatService: chatService,
                      ),
                    );
                  },
                ),
              ],
            ),
            body: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.department),
                  onTap: () async {
                    try {
                      // Yeni sohbet oluştur
                      final chat = await chatService.createChat(
                        name: user.name,
                        participants: [user.id],
                      );

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              chat: chat,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: $e')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _showNewGroupDialog(BuildContext context) async {
    final userService = context.read<UserService>();
    final chatService = context.read<ChatService>();
    final currentUser = userService.currentUser;

    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Tüm kullanıcıları getir
      final users = await userService.getAllUsers();
      // Mevcut kullanıcıyı listeden çıkar
      users.removeWhere((user) => user.id == currentUser.id);

      if (!mounted) return;

      setState(() => _isLoading = false);

      final result = await showDialog<(String, List<UserModel>)?>(
        context: context,
        builder: (context) {
          final selectedUsers = <UserModel>[];
          final nameController = TextEditingController();

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Yeni Grup'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Grup Adı',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return CheckboxListTile(
                              value: selectedUsers.contains(user),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedUsers.add(user);
                                  } else {
                                    selectedUsers.remove(user);
                                  }
                                });
                              },
                              title: Text(user.name),
                              subtitle: Text(user.department),
                              secondary: CircleAvatar(
                                child: Text(user.name[0].toUpperCase()),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Grup adı boş olamaz')),
                        );
                        return;
                      }
                      if (selectedUsers.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('En az bir kullanıcı seçmelisiniz')),
                        );
                        return;
                      }
                      Navigator.pop(context, (name, selectedUsers));
                    },
                    child: const Text('Oluştur'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result != null && mounted) {
        final (name, selectedUsers) = result;
        setState(() => _isLoading = true);

        // Yeni grup sohbeti oluştur
        final chat = await chatService.createChat(
          name: name,
          participants: selectedUsers.map((u) => u.id).toList(),
          isGroup: true,
        );

        if (mounted) {
          setState(() => _isLoading = false);

          // Yeni sohbet ekranına git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                chat: chat,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();
    final userService = context.read<UserService>();
    final currentUser = userService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Kullanıcı oturumu bulunamadı'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sohbetler',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: UserSearchDelegate(
                  userService: context.read<UserService>(),
                  chatService: context.read<ChatService>(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<ChatModel>>(
            stream: chatService.getChats(),
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

              final chats = snapshot.data!;

              if (chats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz sohbet bulunmuyor',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showNewChatDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Yeni Sohbet Başlat'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: chat.isGroup ? Colors.blue : Colors.purple,
                        child: chat.avatar != null
                            ? ClipOval(
                                child: Image.network(
                                  chat.avatar!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                chat.isGroup ? Icons.group : Icons.person,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (chat.isGroup && chat.participants.isNotEmpty)
                                  Text(
                                    '${chat.participants.length} katılımcı',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (chat.lastMessageTime != null)
                            Text(
                              _formatTime(chat.lastMessageTime!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage ?? 'Henüz mesaj yok',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              chat: chat,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Icon(Icons.person_add, color: Colors.white),
                    ),
                    title: const Text('Yeni Sohbet'),
                    subtitle: const Text('Bire bir sohbet başlat'),
                    onTap: () {
                      Navigator.pop(context);
                      _showNewChatDialog(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.group_add, color: Colors.white),
                    ),
                    title: const Text('Yeni Grup'),
                    subtitle: const Text('Grup sohbeti oluştur'),
                    onTap: () {
                      Navigator.pop(context);
                      _showNewGroupDialog(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Dün';
    } else if (now.difference(time).inDays < 7) {
      switch (time.weekday) {
        case 1:
          return 'Pzt';
        case 2:
          return 'Sal';
        case 3:
          return 'Çar';
        case 4:
          return 'Per';
        case 5:
          return 'Cum';
        case 6:
          return 'Cmt';
        case 7:
          return 'Paz';
        default:
          return '';
      }
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
} 