import 'package:flutter/material.dart';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart';
import '../../../services/task_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/admin/admin_drawer.dart';
import '../../../constants/color_constants.dart';

class ActiveTasksScreen extends StatelessWidget {
  const ActiveTasksScreen({Key? key}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aktif Görevler',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorConstants.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const AdminDrawer(),
      body: StreamBuilder<List<TaskModel>>(
        stream: TaskService().getActiveTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Hata oluştu: ${snapshot.error}'),
            );
          }

          final tasks = snapshot.data ?? [];
          
          // Yaklaşan görevler filtresi
          final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final filterByUpcoming = arguments?['filterByUpcoming'] as bool? ?? false;
          
          final filteredTasks = filterByUpcoming ? tasks.where((task) {
            final now = DateTime.now();
            final difference = task.deadline.difference(now).inDays;
            return difference >= 0 && difference <= 7;
          }).toList() : tasks;

          if (filteredTasks.isEmpty) {
            return const Center(
              child: Text('Aktif görev bulunmamaktadır.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return FutureBuilder<UserModel?>(
                future: userService.getUserById(task.assignedTo),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  final daysLeft = task.deadline.difference(DateTime.now()).inDays;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
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
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user?.name ?? 'Yükleniyor...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: daysLeft < 0 ? Colors.red : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                daysLeft < 0
                                    ? '${-daysLeft} gün gecikmiş'
                                    : daysLeft == 0
                                        ? 'Bugün'
                                        : '$daysLeft gün kaldı',
                                style: TextStyle(
                                  color: daysLeft < 0 ? Colors.red : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _getPriorityColor(task.priority),
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => Container(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: const Text('Görevi Düzenle'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(
                                        context,
                                        '/edit-task-screen',
                                        arguments: task,
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.info),
                                    title: const Text('Görev Detayları'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(
                                        context,
                                        '/task-details-screen',
                                        arguments: task,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/task-details-screen',
                          arguments: task,
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-task-screen');
        },
        backgroundColor: ColorConstants.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
