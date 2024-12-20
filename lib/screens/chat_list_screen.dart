import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
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
    final chatService = Provider.of<ChatService>(context);
    final userService = Provider.of<UserService>(context);
    final currentUser = userService.currentUser;
    final isAdmin = currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbetler'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: () => _showNewGroupDialog(context),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ChatModel>>(
              stream: chatService.getUserChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                final chats = snapshot.data ?? [];

                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Henüz hiç sohbetiniz yok'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showNewChatDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Yeni Sohbet Başlat'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return FutureBuilder<String>(
                      future: _getChatTitle(chat, currentUser?.id ?? '', userService),
                      builder: (context, snapshot) {
                        final title = snapshot.data ?? 'Yükleniyor...';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: chat.isGroup ? Colors.green : Colors.blue,
                            child: Icon(
                              chat.isGroup ? Icons.group : Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(title),
                          subtitle: Text(
                            chat.lastMessage ?? 'Henüz mesaj yok',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: chat.lastMessageTime != null
                              ? Text(
                                  _formatDate(chat.lastMessageTime!),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(chat: chat),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context),
        child: const Icon(Icons.chat),
        tooltip: 'Yeni Sohbet',
      ),
    );
  }

  Future<String> _getChatTitle(ChatModel chat, String currentUserId, UserService userService) async {
    if (chat.isGroup) {
      return chat.name;
    } else {
      // Birebir sohbetlerde diğer kullanıcının adını göster
      final otherUserId = chat.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      if (otherUserId.isEmpty) return chat.name;
      
      final otherUser = await userService.getUserById(otherUserId);
      return otherUser?.name ?? chat.name;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      final weekDays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
      return weekDays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
} 