import 'package:flutter/material.dart';
import '../../../models/task_model.dart';
import '../../../services/task_service.dart';
import '../../../widgets/admin/admin_drawer.dart';
import '../../../constants/color_constants.dart';

class ActiveTasksScreen extends StatelessWidget {
  const ActiveTasksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder<List<TaskModel>>(
        future: TaskService().getActiveTasks(),
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

          if (tasks.isEmpty) {
            return const Center(
              child: Text('Aktif görev bulunmamaktadır.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
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
                      Text(
                        'Son Tarih: ${task.deadline.toString().split(' ')[0]}',
                        style: TextStyle(
                          color: task.deadline.isBefore(DateTime.now())
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.assignment_outlined,
                      color: Colors.white,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // TODO: Görev detayları veya düzenleme seçenekleri
                    },
                  ),
                  onTap: () {
                    // TODO: Görev detay sayfasına yönlendir
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Yeni görev ekleme sayfasına yönlendir
        },
        backgroundColor: ColorConstants.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
