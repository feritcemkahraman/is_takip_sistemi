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
    final currentUser = userService.currentUser;
    final isAdmin = currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tamamlanan Görevler'),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: taskService.getCompletedTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var tasks = snapshot.data!;
          
          // Admin değilse sadece kendine atanan görevleri göster
          if (!isAdmin && currentUser != null) {
            tasks = tasks.where((task) => task.assignedTo == currentUser.id).toList();
          }

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tamamlanan görev bulunmuyor',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
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
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                      title: Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Atanan: ${user?.name ?? 'Yükleniyor...'}'),
                          Text('Tamamlanma: ${_formatDate(task.completedAt)}'),
                          Text('Açıklama: ${task.description}'),
                        ],
                      ),
                      trailing: isAdmin
                          ? IconButton(
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
                            )
                          : null,
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Belirsiz';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
