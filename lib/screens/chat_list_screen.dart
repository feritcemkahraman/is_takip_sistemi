import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = false;

  Future<void> _showNewChatDialog(BuildContext context) async {
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

      final selectedUser = await showDialog<UserModel>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Yeni Sohbet'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  onTap: () => Navigator.of(context).pop(user),
                );
              },
            ),
          ),
        ),
      );

      if (selectedUser != null && mounted) {
        setState(() => _isLoading = true);

        // Yeni sohbet oluştur
        final chat = await chatService.createChat(
          name: selectedUser.name,
          participants: [selectedUser.id],
        );

        if (mounted) {
          setState(() => _isLoading = false);

          // Yeni sohbet ekranına git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chat: chat,
                currentUser: currentUser,
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
                              subtitle: Text(user.email),
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
              builder: (context) => ChatScreen(
                chat: chat,
                currentUser: currentUser,
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
        title: const Text('Mesajlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_add),
                      title: const Text('Yeni Sohbet'),
                      onTap: () {
                        Navigator.pop(context);
                        _showNewChatDialog(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.group_add),
                      title: const Text('Yeni Grup'),
                      onTap: () {
                        Navigator.pop(context);
                        _showNewGroupDialog(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Yeni Sohbet'),
                  onTap: () {
                    Navigator.pop(context);
                    _showNewChatDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: const Text('Yeni Grup'),
                  onTap: () {
                    Navigator.pop(context);
                    _showNewGroupDialog(context);
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
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
                return const Center(
                  child: Text('Henüz mesajlaşma bulunmamaktadır'),
                );
              }

              return ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(chat.name[0].toUpperCase()),
                    ),
                    title: Text(chat.name),
                    subtitle: Text(chat.lastMessage ?? 'Henüz mesaj yok'),
                    trailing: chat.unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chat: chat,
                            currentUser: currentUser,
                          ),
                        ),
                      );
                    },
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
    );
  }
} 