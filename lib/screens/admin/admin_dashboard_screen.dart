import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../widgets/admin/dashboard_card.dart';
import '../../widgets/admin/task_list_widget.dart';
import '../../widgets/admin/user_activity_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final TaskService _taskService;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _taskService = Provider.of<TaskService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          _taskService.getActiveTasks(),
          _taskService.getPendingTasks(),
          _taskService.getCompletedTasks(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final activeTasks = snapshot.data?[0] ?? [];
          final pendingTasks = snapshot.data?[1] ?? [];
          final completedTasks = snapshot.data?[2] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Görev Durumu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DashboardCard(
                        title: 'Aktif Görevler',
                        count: activeTasks.length,
                        color: Colors.blue,
                        icon: Icons.assignment,
                        onTap: () => Navigator.pushNamed(context, '/active_tasks'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardCard(
                        title: 'Bekleyen Görevler',
                        count: pendingTasks.length,
                        color: Colors.orange,
                        icon: Icons.pending_actions,
                        onTap: () => Navigator.pushNamed(context, '/pending_tasks'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DashboardCard(
                        title: 'Tamamlanan Görevler',
                        count: completedTasks.length,
                        color: Colors.green,
                        icon: Icons.task_alt,
                        onTap: () => Navigator.pushNamed(context, '/completed_tasks'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Görev Oluştur'),
                  onPressed: () => Navigator.pushNamed(context, '/create_task'),
                ),
                const SizedBox(height: 32),
                if (isSmallScreen) ...[
                  const UserActivityWidget(),
                  const SizedBox(height: 24),
                  const TaskListWidget(),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 2,
                        child: UserActivityWidget(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Son Görevler',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  TaskListWidget(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
