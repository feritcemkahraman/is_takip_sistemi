import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/task_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../models/task_model.dart';
import '../chat_list_screen.dart';
import '../tasks/active_tasks_screen.dart';
import '../tasks/completed_tasks_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  late TaskService _taskService;
  late ChatService _chatService;
  late UserService _userService;
  int _unreadMessages = 0;
  int _activeTasks = 0;
  int _completedTasks = 0;

  @override
  void initState() {
    super.initState();
    _taskService = Provider.of<TaskService>(context, listen: false);
    _chatService = Provider.of<ChatService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    // Okunmamış mesaj sayısını al
    _chatService.getUnreadMessagesCount().listen((count) {
      if (mounted) {
        setState(() => _unreadMessages = count);
      }
    });

    // Görev istatistiklerini al
    final currentUser = _userService.currentUser;
    if (currentUser != null) {
      final tasks = await _taskService.getUserTasks(currentUser.id);
      if (mounted) {
        setState(() {
          _activeTasks = tasks.where((task) => !task.isCompleted).length;
          _completedTasks = tasks.where((task) => task.isCompleted).length;
        });
      }
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<List<TaskModel>>(
      stream: _taskService.getUserTasksStream(_userService.currentUser?.id ?? ''),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;
        final activeTasks = tasks.where((task) => !task.isCompleted).toList();

        if (activeTasks.isEmpty) {
          return const Center(
            child: Text('Aktif görev bulunmuyor'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeTasks.length > 3 ? 3 : activeTasks.length,
          itemBuilder: (context, index) {
            final task = activeTasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                title: Text(task.title),
                subtitle: Text(task.description),
                trailing: Text(
                  task.dueDate != null
                      ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                      : 'Tarih yok',
                ),
                leading: const Icon(Icons.task),
                onTap: () {
                  // Görev detayına git
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _userService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Profil sayfasına git
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Karşılama Mesajı
                Text(
                  'Merhaba, ${currentUser?.name ?? ""}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // İstatistik Kartları
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      title: 'Aktif Görevler',
                      value: _activeTasks.toString(),
                      icon: Icons.assignment,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActiveTasksScreen(),
                          ),
                        );
                      },
                    ),
                    _buildStatCard(
                      title: 'Tamamlanan Görevler',
                      value: _completedTasks.toString(),
                      icon: Icons.assignment_turned_in,
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
                    _buildStatCard(
                      title: 'Okunmamış Mesajlar',
                      value: _unreadMessages.toString(),
                      icon: Icons.message,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildStatCard(
                      title: 'Departman',
                      value: currentUser?.department ?? '',
                      icon: Icons.business,
                      color: Colors.purple,
                      onTap: null,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Son Görevler Başlığı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Son Görevler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActiveTasksScreen(),
                          ),
                        );
                      },
                      child: const Text('Tümünü Gör'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Son Görevler Listesi
                _buildTaskList(),
              ],
            ),
          ),
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
        child: const Icon(Icons.message),
        tooltip: 'Yeni Sohbet',
      ),
    );
  }
} 