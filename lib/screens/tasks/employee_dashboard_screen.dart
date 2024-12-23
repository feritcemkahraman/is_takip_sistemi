import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/dashboard_card.dart';
import 'task_detail_screen.dart';
import '../chat_list_screen.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context);
    final userService = Provider.of<UserService>(context);
    final currentUser = userService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Takip Sistemi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login-screen');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Özet Kartları
              StreamBuilder<List<TaskModel>>(
                stream: taskService.getActiveTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  }

                  final tasks = snapshot.data ?? [];
                  final myTasks = tasks.where((task) => task.assignedTo == currentUser?.id).toList();
                  
                  final now = DateTime.now();
                  final todayTasks = myTasks.where((task) {
                    return task.deadline.year == now.year &&
                           task.deadline.month == now.month &&
                           task.deadline.day == now.day;
                  }).toList();
                  
                  final overdueTasks = myTasks.where((task) => 
                    task.deadline.isBefore(now)).toList();

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      DashboardCard(
                        title: 'Aktif Görevlerim',
                        count: myTasks.length,
                        icon: Icons.assignment,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/active-tasks-screen',
                            arguments: {'filterByUser': true},
                          );
                        },
                      ),
                      DashboardCard(
                        title: 'Bugün Teslim',
                        count: todayTasks.length,
                        icon: Icons.today,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/active-tasks-screen',
                            arguments: {'filterByDate': 'today'},
                          );
                        },
                      ),
                      DashboardCard(
                        title: 'Geciken',
                        count: overdueTasks.length,
                        icon: Icons.warning,
                        color: Colors.red,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/active-tasks-screen',
                            arguments: {'filterByStatus': 'overdue'},
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Yaklaşan Görevler
              const Text(
                'Yaklaşan Görevler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<TaskModel>>(
                stream: taskService.getActiveTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  }

                  final tasks = snapshot.data ?? [];
                  final myTasks = tasks
                    .where((task) => task.assignedTo == currentUser?.id)
                    .toList()
                    ..sort((a, b) => a.deadline.compareTo(b.deadline));

                  if (myTasks.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Aktif görev bulunmuyor'),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myTasks.length > 5 ? 5 : myTasks.length,
                    itemBuilder: (context, index) {
                      final task = myTasks[index];
                      final daysLeft = task.deadline.difference(DateTime.now()).inDays;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Teslim: ${task.deadline.toString().split(' ')[0]}\n'
                            'Kalan: ${daysLeft < 0 ? '${-daysLeft} gün gecikme' : '$daysLeft gün'}',
                          ),
                          trailing: Icon(
                            daysLeft < 0 ? Icons.warning : Icons.calendar_today,
                            color: daysLeft < 0 ? Colors.red : Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskDetailScreen(
                                  taskId: task.id,
                                  canInteract: true,
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
            ],
          ),
        ),
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