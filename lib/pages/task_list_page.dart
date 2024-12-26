import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasksData = await ApiService.getTasks();
      setState(() {
        _tasks = tasksData.map((data) => Task.fromJson(data)).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Görevler yüklenirken bir hata oluştu';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await ApiService.deleteTask(taskId);
      setState(() {
        _tasks.removeWhere((task) => task.id == taskId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görev başarıyla silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görev silinirken bir hata oluştu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasks,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return const Center(
        child: Text('Henüz görev bulunmuyor'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return TaskCard(
            task: task,
            onDelete: () => _deleteTask(task.id),
            onTap: () async {
              // Görev detay sayfasına git
              final result = await Navigator.pushNamed(
                context,
                '/task-details',
                arguments: task.id,
              );
              
              // Geri dönüldüğünde listeyi güncelle
              if (result == true) {
                _loadTasks();
              }
            },
          );
        },
      ),
    );
  }
} 