import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';

class CompletedTasksScreen extends StatelessWidget {
  const CompletedTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamamlanan Görevler'),
      ),
      body: Consumer<TaskService>(
        builder: (context, taskService, child) {
          return FutureBuilder<List<TaskModel>>(
            future: taskService.getCompletedTasks(),
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
                  child: Text('Tamamlanan görev bulunmuyor'),
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.description),
                          const SizedBox(height: 4),
                          Text(
                            'Tamamlanma: ${task.completedAt?.day}/${task.completedAt?.month}/${task.completedAt?.year}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'reactivate',
                            child: const Text('Tekrar Aktifleştir'),
                            onTap: () async {
                              await taskService.updateTaskStatus(
                                task.id,
                                'active',
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
    );
  }
}
