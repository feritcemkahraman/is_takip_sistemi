import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../widgets/user_search_delegate.dart';
import 'chat_screen.dart';

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

      final users = await userService.getAllUsers();
      users.removeWhere((user) => user.id == currentUser.id);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (!mounted) return;
      await Navigator.of(context).push(
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
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.department),
                  onTap: () async {
                    try {
                      // Önce mevcut sohbeti kontrol et
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

                      // Mevcut sohbet yoksa, geçici bir chat objesi oluştur
                      final now = DateTime.now();
                      final tempChat = ChatModel(
                        id: 'temp_${now.millisecondsSinceEpoch}',
                        name: user.name,
                        participants: [user.id, currentUser.id],
                        createdBy: currentUser.id,
                        createdAt: now,
                        updatedAt: now,
                        isGroup: false,
                        mutedBy: [],
                        messages: [],
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
                      if (!context.mounted) return;
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _showUserSearch() async {
    final currentUser = context.read<UserService>().currentUser;
    if (currentUser == null) return;

    final users = await context.read<UserService>().getAllUsers();
    
    if (!mounted) return;

    final selectedUser = await showSearch<UserModel?>(
      context: context,
      delegate: UserSearchDelegate(
        users: users,
        currentUserId: currentUser.id,
      ),
    );

    if (selectedUser != null && mounted) {
      final chatService = context.read<ChatService>();
      
      // Mevcut sohbeti kontrol et
      final existingChat = await chatService.findExistingChat(selectedUser.id);
      
      if (existingChat != null) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: existingChat),
          ),
        );
        return;
      }

      // Yeni sohbet oluştur
      final chat = await chatService.createChat(
        name: selectedUser.name,
        participants: [selectedUser.id],
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserService>().currentUser;
    if (currentUser == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbetler'),
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
                    'Henüz sohbet yok',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showNewChatDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Sohbet'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherParticipants = chat.participants
                  .where((id) => id != currentUser.id)
                  .toList();

              return Dismissible(
                key: Key(chat.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
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
                },
                onDismissed: (direction) async {
                  try {
                    await context.read<ChatService>().deleteChat(chat.id);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e')),
                    );
                  }
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      chat.isGroup
                          ? chat.name[0].toUpperCase()
                          : otherParticipants.isNotEmpty
                              ? chat.name[0].toUpperCase()
                              : '?',
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.mutedBy.contains(currentUser.id))
                        const Icon(
                          Icons.notifications_off,
                          size: 16,
                          color: Colors.grey,
                        ),
                    ],
                  ),
                  subtitle: chat.lastMessage != null
                      ? Text(
                          chat.lastMessage!.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
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
                        builder: (context) => ChatScreen(chat: chat),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : () => _showNewChatDialog(context),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }
} 