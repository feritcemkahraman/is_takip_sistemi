import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../widgets/admin/user_activity_widget.dart';
import '../../widgets/dashboard_card.dart';

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
    final taskService = Provider.of<TaskService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
            FutureBuilder<List<dynamic>>(
              future: Future.wait([
                taskService.getActiveTasks(),
                taskService.getCompletedTasks(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final activeTasks = snapshot.data?[0] ?? [];
                final completedTasks = snapshot.data?[1] ?? [];

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
                            title: 'Tamamlanan Görevler',
                            count: completedTasks.length,
                            icon: Icons.task_alt,
                            color: Colors.green,
                            onTap: () => Navigator.pushNamed(context, '/completed-tasks-screen'),
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
                              title: 'Tamamlanan Görevler',
                              count: completedTasks.length,
                              icon: Icons.task_alt,
                              color: Colors.green,
                              onTap: () => Navigator.pushNamed(context, '/completed-tasks-screen'),
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
    );
  }
}
