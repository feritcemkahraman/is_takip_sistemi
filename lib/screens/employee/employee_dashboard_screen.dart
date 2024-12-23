import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/dashboard_card.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/completed_tasks_screen.dart';
import '../chat_list_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  late TaskService _taskService;
  int _completedTaskCount = 0;

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<UserService>(context, listen: false);
    _taskService = TaskService(userService);
    _loadCompletedTaskCount();
  }

  Future<void> _loadCompletedTaskCount() async {
    final tasks = await _taskService.getCompletedTasks();
    setState(() {
      _completedTaskCount = tasks.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final currentUser = userService.currentUser;

    if (currentUser == null) {
      print('Current user is null in employee dashboard');
      return const Scaffold(
        body: Center(
          child: Text('Kullanıcı oturumu bulunamadı'),
        ),
      );
    }

    print('Building employee dashboard for user: ${currentUser.id}');
    print('User Role: ${currentUser.role}');
    print('User Name: ${currentUser.name}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Hoş Geldin, ${currentUser.name}'),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadCompletedTaskCount();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Özet Kartları
                StreamBuilder<List<TaskModel>>(
                  stream: _taskService.getActiveTasksStream(),
                  builder: (context, activeSnapshot) {
                    print('Active tasks stream builder update');
                    
                    if (activeSnapshot.connectionState == ConnectionState.waiting) {
                      print('Active tasks stream is waiting');
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (activeSnapshot.hasError) {
                      print('Active tasks stream error: ${activeSnapshot.error}');
                      return Center(child: Text('Hata: ${activeSnapshot.error}'));
                    }

                    final activeTasks = activeSnapshot.data ?? [];
                    print('Active tasks count: ${activeTasks.length}');

                    return StreamBuilder<List<TaskModel>>(
                      stream: _taskService.getCompletedTasksStream(),
                      builder: (context, completedSnapshot) {
                        print('Completed tasks stream builder update');
                        
                        if (completedSnapshot.connectionState == ConnectionState.waiting) {
                          print('Completed tasks stream is waiting');
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (completedSnapshot.hasError) {
                          print('Completed tasks stream error: ${completedSnapshot.error}');
                          return Center(child: Text('Hata: ${completedSnapshot.error}'));
                        }

                        final completedTasks = completedSnapshot.data ?? [];
                        print('Completed tasks count: ${completedTasks.length}');

                        // Bugün teslim edilecek görevler
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);
                        final tomorrow = today.add(const Duration(days: 1));
                        final todayTasks = activeTasks.where((task) =>
                            task.deadline.isAfter(today) &&
                            task.deadline.isBefore(tomorrow)).toList();
                        print('Today tasks count: ${todayTasks.length}');

                        // Geciken görevler
                        final overdueTasks = activeTasks
                            .where((task) => task.deadline.isBefore(today))
                            .toList();
                        print('Overdue tasks count: ${overdueTasks.length}');

                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            DashboardCard(
                              title: 'Aktif Görevler',
                              count: activeTasks.length,
                              icon: Icons.assignment,
                              color: Colors.blue,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/active-tasks-screen',
                                  arguments: {
                                    'filterByUser': true,
                                    'userId': currentUser.id,
                                  },
                                );
                              },
                            ),
                            DashboardCard(
                              title: 'Tamamlanan',
                              count: completedTasks.length,
                              icon: Icons.task_alt,
                              color: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CompletedTasksScreen(),
                                  ),
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
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Aktif Görevler Listesi
                const Text(
                  'Aktif Görevlerim',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<TaskModel>>(
                  stream: _taskService.getActiveTasksStream(),
                  builder: (context, snapshot) {
                    print('Active tasks list stream builder update');
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      print('Active tasks list stream is waiting');
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      print('Active tasks list stream error: ${snapshot.error}');
                      return Center(child: Text('Hata: ${snapshot.error}'));
                    }

                    final tasks = snapshot.data ?? [];
                    print('Active tasks list count: ${tasks.length}');

                    if (tasks.isEmpty) {
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
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        print('Building task card: ${task.title} (${task.id})');
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            title: Text(task.title),
                            subtitle: Text(
                              'Teslim Tarihi: ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                            ),
                            trailing: Icon(
                              Icons.circle,
                              color: task.priority == 3
                                  ? Colors.red
                                  : task.priority == 2
                                      ? Colors.orange
                                      : Colors.green,
                              size: 12,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTaskPriorityColor(int priority) {
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