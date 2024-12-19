import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import 'task_detail_screen.dart';

class ActiveTasksScreen extends StatelessWidget {
  const ActiveTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devam Eden Görevler'),
      ),
      body: Consumer<TaskService>(
        builder: (context, taskService, child) {
          return FutureBuilder<List<TaskModel>>(
            future: taskService.getActiveTasks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              final tasks = snapshot.data ?? [];

              if (tasks.isEmpty) {
                return const Center(
                  child: Text('Devam eden görev bulunmuyor'),
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
                            'Bitiş: ${task.deadline.toString().split(' ')[0]}\n'
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-task-screen'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
