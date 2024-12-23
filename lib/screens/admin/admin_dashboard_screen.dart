import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../widgets/admin/user_activity_widget.dart';
import '../../widgets/dashboard_card.dart';
import '../../models/task_model.dart';
import '../chat_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;
    final userService = Provider.of<UserService>(context);
    final taskService = Provider.of<TaskService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Paneli'),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/create-task-screen');
                },
                icon: const Icon(Icons.add),
                label: const Text('Yeni Görev Oluştur'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<List<TaskModel>>(
              stream: taskService.getActiveTasksStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activeTasks = snapshot.data ?? [];
                final upcomingTasks = activeTasks.where((task) {
                  final now = DateTime.now();
                  final difference = task.deadline.difference(now).inDays;
                  return difference >= 0 && difference <= 7;
                }).toList();

                return Column(
                  children: [
                    if (isSmallScreen)
                      Column(
                        children: [
                          DashboardCard(
                            title: 'Devam Eden Görevler',
                            count: activeTasks.length,
                            icon: Icons.assignment,
                            color: Colors.blue,
                            onTap: () => Navigator.pushNamed(context, '/active-tasks-screen'),
                          ),
                          const SizedBox(height: 16),
                          DashboardCard(
                            title: 'Yaklaşan Görevler',
                            count: upcomingTasks.length,
                            icon: Icons.upcoming,
                            color: Colors.orange,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/active-tasks-screen',
                              arguments: {'filterByUpcoming': true},
                            ),
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<TaskModel>>(
                            stream: taskService.getCompletedTasksStream(),
                            builder: (context, completedSnapshot) {
                              final completedTasks = completedSnapshot.data ?? [];
                              return DashboardCard(
                                title: 'Tamamlanan Görevler',
                                count: completedTasks.length,
                                icon: Icons.task_alt,
                                color: Colors.green,
                                onTap: () => Navigator.pushNamed(context, '/completed-tasks-screen'),
                              );
                            },
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: DashboardCard(
                              title: 'Devam Eden Görevler',
                              count: activeTasks.length,
                              icon: Icons.assignment,
                              color: Colors.blue,
                              onTap: () => Navigator.pushNamed(context, '/active-tasks-screen'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DashboardCard(
                              title: 'Yaklaşan Görevler',
                              count: upcomingTasks.length,
                              icon: Icons.upcoming,
                              color: Colors.orange,
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/active-tasks-screen',
                                arguments: {'filterByUpcoming': true},
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StreamBuilder<List<TaskModel>>(
                              stream: taskService.getCompletedTasksStream(),
                              builder: (context, completedSnapshot) {
                                final completedTasks = completedSnapshot.data ?? [];
                                return DashboardCard(
                                  title: 'Tamamlanan Görevler',
                                  count: completedTasks.length,
                                  icon: Icons.task_alt,
                                  color: Colors.green,
                                  onTap: () => Navigator.pushNamed(context, '/completed-tasks-screen'),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                    const UserActivityWidget(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatListScreen(),
            ),
          );
        },
        child: const Icon(Icons.chat),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
