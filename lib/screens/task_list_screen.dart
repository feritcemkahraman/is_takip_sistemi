import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../models/task_model.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import 'task_detail_screen.dart';
import 'admin/create_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _selectedStatus = '';
  String _selectedPriority = '';
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final taskService = Provider.of<TaskService>(context);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevler'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (currentUser?.role == AppConstants.roleAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTaskScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: _getFilteredTasks(taskService, currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                final tasks = snapshot.data ?? [];
                final filteredTasks = _filterTasks(tasks);

                if (filteredTasks.isEmpty) {
                  return const Center(
                    child: Text('Görev bulunamadı'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return _buildTaskCard(task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedStatus.isEmpty ? null : _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Durum',
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Tümü'),
                ),
                ...AppConstants.statusLabels.entries.map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value ?? '');
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPriority.isEmpty ? null : _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Öncelik',
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Tümü'),
                ),
                ...AppConstants.priorityLabels.entries.map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedPriority = value ?? '');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Görev ara...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final statusColor = AppConstants.statusColors[task.status] ?? Colors.grey;
    final priorityColor = AppConstants.priorityColors[task.priority] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: task),
            ),
          );
        },
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(task.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(AppConstants.statusLabels[task.status] ?? ''),
                const SizedBox(width: 12),
                Icon(Icons.flag, size: 12, color: priorityColor),
                const SizedBox(width: 4),
                Text(AppConstants.priorityLabels[task.priority] ?? ''),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            if (task.progress > 0)
              Text(
                '%${task.progress.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Stream<List<TaskModel>> _getFilteredTasks(TaskService taskService, String userId) {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    
    if (currentUser?.role == AppConstants.roleAdmin) {
      return taskService.getAllTasks();
    } else {
      return taskService.getUserTasks(userId);
    }
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    return tasks.where((task) {
      final matchesStatus = _selectedStatus.isEmpty || task.status == _selectedStatus;
      final matchesPriority = _selectedPriority.isEmpty || task.priority == _selectedPriority;
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesPriority && matchesSearch;
    }).toList();
  }
} 