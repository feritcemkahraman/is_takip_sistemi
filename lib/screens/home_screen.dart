import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/dashboard_card.dart';
import 'chat_list_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<UserService>().currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Kullanıcı oturumu bulunamadı'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Ana Sayfa' : 'Mesajlar'),
        actions: [
          if (_selectedIndex == 0)
            StreamBuilder<int>(
              stream: context.read<ChatService>().getUnreadMessagesCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login-screen');
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          TasksScreen(),
          ChatListScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Görevler',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                StreamBuilder<int>(
                  stream: context.read<ChatService>().getUnreadMessagesCount(),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    if (unreadCount == 0) return const SizedBox();

                    return Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            label: 'Mesajlar',
          ),
        ],
      ),
    );
  }
} 