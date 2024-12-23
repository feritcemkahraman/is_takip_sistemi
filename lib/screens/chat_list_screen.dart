import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../widgets/user_search_delegate.dart';
import '../widgets/chat_list_item.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

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
      final users = await userService.getAllUsers();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Yeni Sohbet'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    final users = await userService.getAllUsers();
                    if (!context.mounted) return;
                    showSearch(
                      context: context,
                      delegate: UserSearchDelegate(
                        users: users,
                        currentUserId: currentUser.id,
                        userService: userService,
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
                if (user.id == currentUser.id) return const SizedBox.shrink();
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                    child: user.avatar == null ? Text(user.name[0].toUpperCase()) : null,
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.department),
                  onTap: () async {
                    try {
                      final existingChat = await chatService.findExistingChat(user.id);
                      
                      if (existingChat != null) {
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(chat: existingChat),
                          ),
                        );
                        return;
                      }

                      final now = DateTime.now();
                      final tempChat = ChatModel(
                        id: 'temp_${now.millisecondsSinceEpoch}',
                        name: user.name,
                        participants: [user.id],
                        createdBy: currentUser.id,
                        createdAt: now,
                        updatedAt: now,
                        isGroup: false,
                        mutedBy: const [],
                        messages: const [],
                        unreadCount: 0,
                      );

                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chat: tempChat,
                            isNewChat: true,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showUserSearch() async {
    final userService = context.read<UserService>();
    final currentUser = userService.currentUser;
    if (currentUser == null) return;

    final users = await userService.getAllUsers();
    if (!mounted) return;

    final selectedUser = await showSearch<UserModel?>(
      context: context,
      delegate: UserSearchDelegate(
        users: users,
        currentUserId: currentUser.id,
        userService: userService,
      ),
    );

    if (selectedUser != null && mounted) {
      final chatService = context.read<ChatService>();
      final existingChat = await chatService.findExistingChat(selectedUser.id);
      
      if (existingChat != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chat: existingChat,
              isNewChat: false,
            ),
          ),
        );
        return;
      }

      final now = DateTime.now();
      final tempId = 'temp_${now.millisecondsSinceEpoch}_${currentUser.id}_${selectedUser.id}';
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chat: ChatModel(
              id: tempId,
              name: selectedUser.name,
              participants: [selectedUser.id, currentUser.id],
              createdBy: currentUser.id,
              createdAt: now,
              updatedAt: now,
              isGroup: false,
              mutedBy: const [],
              messages: const [],
              unreadCount: 0,
            ),
            isNewChat: true,
          ),
        ),
      );
    }
  }

  void _showChatOptions(BuildContext context, ChatModel chat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Sohbeti Sil', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sohbeti Sil'),
                    content: const Text('Bu sohbeti silmek istediğinizden emin misiniz?'),
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

                if (confirm == true && context.mounted) {
                  try {
                    await context.read<ChatService>().deleteChat(chat.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sohbet silindi')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final userService = context.read<UserService>();
    final chatService = context.read<ChatService>();
    final currentUser = userService.currentUser;
    if (currentUser == null) return;

    final selectedUsers = <UserModel>[];
    String groupName = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Grup Oluştur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Grup Adı',
                    hintText: 'Grup adını girin',
                  ),
                  onChanged: (value) => groupName = value,
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<UserModel>>(
                  future: userService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final users = snapshot.data!
                        .where((user) => user.id != currentUser.id)
                        .toList();

                    return Column(
                      children: users.map((user) => CheckboxListTile(
                        title: Text(user.name),
                        subtitle: Text(user.department),
                        value: selectedUsers.contains(user),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedUsers.add(user);
                            } else {
                              selectedUsers.remove(user);
                            }
                          });
                        },
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (groupName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen grup adı girin')),
                  );
                  return;
                }
                if (selectedUsers.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen en az bir kullanıcı seçin')),
                  );
                  return;
                }
                Navigator.pop(context);
                
                try {
                  final chat = await chatService.createChat(
                    name: groupName,
                    participants: selectedUsers.map((u) => u.id).toList(),
                    isGroup: true,
                  );

                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chat: chat,
                        isNewChat: true,
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserService>().currentUser;
    if (currentUser == null) return const Scaffold();

    final isAdmin = currentUser.role == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Sohbetler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showUserSearch,
          ),
        ],
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: context.read<ChatService>().getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!;

          if (chats.isEmpty) {
            return const Center(
              child: Text('Henüz sohbet bulunmuyor'),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatListItem(
                chat: chat,
                currentUserId: currentUser.id,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chat: chat,
                        isNewChat: false,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: isAdmin 
        ? SpeedDial(
            icon: Icons.add,
            activeIcon: Icons.close,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            activeBackgroundColor: Colors.red,
            activeForegroundColor: Colors.white,
            buttonSize: const Size(56.0, 56.0),
            visible: true,
            closeManually: false,
            curve: Curves.bounceIn,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            elevation: 8.0,
            shape: const CircleBorder(),
            children: [
              SpeedDialChild(
                child: const Icon(Icons.chat),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                label: 'Yeni Sohbet',
                onTap: _showUserSearch,
              ),
              SpeedDialChild(
                child: const Icon(Icons.group_add),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                label: 'Yeni Grup Oluştur',
                onTap: () => _showCreateGroupDialog(context),
              ),
            ],
          )
        : FloatingActionButton(
            onPressed: _showUserSearch,
            child: const Icon(Icons.chat),
          ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}g';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}d';
    } else {
      return 'şimdi';
    }
  }
} 