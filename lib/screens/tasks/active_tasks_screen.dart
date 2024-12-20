import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import 'task_detail_screen.dart';

class ActiveTasksScreen extends StatelessWidget {
  const ActiveTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context);
    final userService = Provider.of<UserService>(context);
    final currentUser = userService.currentUser;
    
    // Route argümanlarını al
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final filterByUser = arguments?['filterByUser'] as bool?;
    final filterByDate = arguments?['filterByDate'] as String?;
    final filterByStatus = arguments?['filterByStatus'] as String?;

    // Başlık metnini belirle
    String title = 'Devam Eden Görevler';
    if (filterByDate == 'today') {
      title = 'Bugün Teslim';
    } else if (filterByStatus == 'overdue') {
      title = 'Geciken Görevler';
    } else if (filterByUser == true) {
      title = 'Görevlerim';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<List<TaskModel>>(
        future: taskService.getActiveTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          var tasks = snapshot.data ?? [];

          // Filtreleri uygula
          if (filterByUser == true && currentUser != null) {
            tasks = tasks.where((task) => task.assignedTo == currentUser.id).toList();
          }

          if (filterByDate == 'today') {
            final now = DateTime.now();
            tasks = tasks.where((task) {
              return task.deadline.year == now.year &&
                     task.deadline.month == now.month &&
                     task.deadline.day == now.day;
            }).toList();
          }

          if (filterByStatus == 'overdue') {
            final now = DateTime.now();
            tasks = tasks.where((task) => task.deadline.isBefore(now)).toList();
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
                      '${task.priority}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: FutureBuilder<UserModel?>(
                    future: userService.getUserById(task.assignedTo),
                    builder: (context, userSnapshot) {
                      final user = userSnapshot.data;
                      return Text(
                        'Atanan: ${user?.name ?? 'Yükleniyor...'}\n'
                        'Bitiş: ${task.deadline.toString().split(' ')[0]}\n'
                        'Kalan: ${isOverdue ? '${-daysLeft} gün gecikme' : '$daysLeft gün'}\n'
                        'Açıklama: ${task.description}',
                        style: TextStyle(
                          color: isOverdue ? Colors.red : null,
                        ),
                      );
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOverdue)
                        const Icon(Icons.warning, color: Colors.red),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(
                                task: task,
                                canInteract: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
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
