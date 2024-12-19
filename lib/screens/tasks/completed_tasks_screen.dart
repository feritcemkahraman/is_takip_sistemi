import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import 'task_detail_screen.dart';

class CompletedTasksScreen extends StatelessWidget {
  const CompletedTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskService = context.watch<TaskService>();
    final userService = context.watch<UserService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamamlanan Görevler'),
      ),
      body: FutureBuilder<List<TaskModel>>(
        future: taskService.getCompletedTasks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;

          if (tasks.isEmpty) {
            return const Center(
              child: Text('Tamamlanan görev bulunmuyor'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return FutureBuilder<UserModel?>(
                future: userService.getUserById(task.assignedTo),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Atanan: ${user?.name ?? 'Yükleniyor...'}\n'
                        'Tamamlanma: ${task.completedAt?.toString().split(' ')[0] ?? 'Belirsiz'}\n'
                        'Açıklama: ${task.description}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Görevi Sil'),
                              content: const Text('Bu görevi silmek istediğinize emin misiniz?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('İptal'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await taskService.deleteTask(task.id);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Görev silindi')),
                                      );
                                    }
                                  },
                                  child: const Text('Sil'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailScreen(
                              task: task,
                              canInteract: false,
                            ),
                          ),
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
    );
  }
}
