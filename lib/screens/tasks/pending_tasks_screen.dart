import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';

class PendingTasksScreen extends StatelessWidget {
  const PendingTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bekleyen Görevler'),
      ),
      body: Consumer<TaskService>(
        builder: (context, taskService, child) {
          return FutureBuilder<List<TaskModel>>(
            future: taskService.getPendingTasks(),
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
                  child: Text('Bekleyen görev bulunmuyor'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    child: ListTile(
                      title: Text(task.title),
                      subtitle: Text(task.description),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'activate',
                            child: const Text('Aktifleştir'),
                            onTap: () async {
                              await taskService.updateTaskStatus(
                                task.id,
                                'active',
                              );
                            },
                          ),
                          PopupMenuItem(
                            value: 'complete',
                            child: const Text('Tamamlandı'),
                            onTap: () async {
                              await taskService.updateTaskStatus(
                                task.id,
                                'completed',
                              );
                            },
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Text('Sil'),
                            onTap: () async {
                              await taskService.deleteTask(task.id);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create_task'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
