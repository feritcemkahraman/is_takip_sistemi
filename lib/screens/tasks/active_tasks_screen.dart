import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import 'task_detail_screen.dart';

class ActiveTasksScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const ActiveTasksScreen({
    Key? key,
    this.arguments,
  }) : super(key: key);

  @override
  State<ActiveTasksScreen> createState() => _ActiveTasksScreenState();
}

class _ActiveTasksScreenState extends State<ActiveTasksScreen> {
  late TaskService _taskService;

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<UserService>(context, listen: false);
    _taskService = TaskService(userService);
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final currentUser = userService.currentUser;
    
    // Route argümanlarını al
    final filterByUser = widget.arguments?['filterByUser'] as bool?;
    final filterByDate = widget.arguments?['filterByDate'] as String?;
    final filterByStatus = widget.arguments?['filterByStatus'] as String?;

    // Başlık metnini belirle
    String title = 'Devam Eden Görevler';
    if (filterByDate == 'today') {
      title = 'Bugün Teslim';
    } else if (filterByStatus == 'overdue') {
      title = 'Geciken Görevler';
    } else if (filterByUser == true) {
      title = 'Görevlerim';
    }

    if (currentUser == null) {
      print('Current user is null in active tasks screen');
      return const Scaffold(
        body: Center(
          child: Text('Kullanıcı oturumu bulunamadı'),
        ),
      );
    }

    print('Building active tasks screen for user: ${currentUser.id}');
    print('User Role: ${currentUser.role}');
    print('User Name: ${currentUser.name}');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: _taskService.getActiveTasksStream(),
        builder: (context, snapshot) {
          print('Active tasks stream builder update');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('Active tasks stream is waiting');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Active tasks stream error: ${snapshot.error}');
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          var tasks = snapshot.data ?? [];
          print('Active tasks count: ${tasks.length}');

          // Filtreleri uygula
          if (filterByUser == true) {
            final userId = widget.arguments?['userId'] as String?;
            if (userId != null) {
              tasks = tasks.where((task) => task.assignedTo == userId).toList();
              print('Filtered tasks by user: ${tasks.length}');
            }
          }

          if (filterByDate == 'today') {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final tomorrow = today.add(const Duration(days: 1));
            tasks = tasks.where((task) =>
                task.deadline.isAfter(today) &&
                task.deadline.isBefore(tomorrow)).toList();
            print('Filtered tasks by today: ${tasks.length}');
          }

          if (filterByStatus == 'overdue') {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            tasks = tasks.where((task) => task.deadline.isBefore(today)).toList();
            print('Filtered tasks by overdue: ${tasks.length}');
          }

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    filterByStatus == 'overdue' ? Icons.check_circle : Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    filterByStatus == 'overdue'
                        ? 'Gecikmiş görev bulunmuyor'
                        : filterByDate == 'today'
                            ? 'Bugün teslim edilecek görev bulunmuyor'
                            : 'Devam eden görev bulunmuyor',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Görevleri teslim tarihine göre sırala
          tasks.sort((a, b) => a.deadline.compareTo(b.deadline));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final daysLeft = task.deadline.difference(DateTime.now()).inDays;
              final isOverdue = daysLeft < 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPriorityColor(task.priority),
                    child: Text(
                      '${daysLeft.abs()}g',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(task.description),
                      const SizedBox(height: 4),
                      Text(
                        'Teslim Tarihi: ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(taskId: task.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
