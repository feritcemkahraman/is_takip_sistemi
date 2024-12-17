import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../constants/color_constants.dart';

class TaskListWidget extends StatelessWidget {
  const TaskListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context);
    final userService = Provider.of<UserService>(context);

    return FutureBuilder<List<TaskModel>>(
      future: taskService.getAllTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];
        final activeTasks = tasks.where((task) => task.status == 'active').toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final recentTasks = activeTasks.take(5).toList();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Devam Eden Görevler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/tasks');
                      },
                      child: Text(
                        'Tümünü Gör',
                        style: TextStyle(
                          color: ColorConstants.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (recentTasks.isEmpty)
                  const Center(
                    child: Text('Devam eden görev bulunmamaktadır'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentTasks.length,
                    itemBuilder: (context, index) {
                      final task = recentTasks[index];
                      return FutureBuilder<UserModel?>(
                        future: userService.getUserById(task.assignedTo),
                        builder: (context, userSnapshot) {
                          final user = userSnapshot.data;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: ColorConstants.primaryColor.withOpacity(0.2),
                              child: Text(
                                user?.name.substring(0, 1).toUpperCase() ?? '?',
                                style: TextStyle(
                                  color: ColorConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(task.title),
                            subtitle: Text(
                              'Atanan: ${user?.name ?? 'Yükleniyor...'}\n'
                              'Bitiş: ${task.deadline.toString().split(' ')[0]}',
                            ),
                            trailing: _getPriorityIcon(task.priority),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getPriorityIcon(int priority) {
    IconData iconData;
    Color color;
    
    switch (priority) {
      case 3:
        iconData = Icons.priority_high;
        color = Colors.red;
        break;
      case 2:
        iconData = Icons.priority_high;
        color = Colors.orange;
        break;
      default:
        iconData = Icons.low_priority;
        color = Colors.green;
    }

    return Icon(iconData, color: color);
  }
}
