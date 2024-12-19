import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'tasks/task_detail_screen.dart';
import '../widgets/task_card.dart';
import 'chat_list_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _taskService = TaskService();
  String _selectedStatus = '';

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
        title: const Text('Görevlerim'),
        actions: [
          StreamBuilder<int>(
            stream: context.read<ChatService>().getUnreadMessagesCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatListScreen(),
                        ),
                      );
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '',
                child: Text('Tümü'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Bekleyen'),
              ),
              const PopupMenuItem(
                value: 'in_progress',
                child: Text('Devam Eden'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Tamamlanan'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _taskService.getAssignedTasks(currentUser.id),
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

          final tasks = snapshot.data!;
          final filteredTasks = _selectedStatus.isEmpty
              ? tasks
              : tasks.where((task) => task.status == _selectedStatus).toList();

          if (filteredTasks.isEmpty) {
            return Center(
              child: Text(
                _selectedStatus.isEmpty
                    ? 'Henüz görev yok'
                    : '${_getStatusLabel(_selectedStatus)} durumunda görev yok',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return TaskCard(
                task: task,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailScreen(task: task),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'chat_button',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatListScreen(),
                ),
              );
            },
            child: Stack(
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
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_task_button',
            onPressed: () {
              Navigator.pushNamed(context, '/create-task-screen');
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Bekleyen';
      case 'in_progress':
        return 'Devam Eden';
      case 'completed':
        return 'Tamamlanan';
      default:
        return '';
    }
  }
}
