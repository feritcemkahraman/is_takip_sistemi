import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../widgets/task_list_item.dart';
import '../screens/task_detail_screen.dart';
import '../screens/create_task_screen.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';

class TaskListScreen extends StatefulWidget {
  final String? userId;
  final bool isAdminView;

  const TaskListScreen({
    Key? key,
    this.userId,
    this.isAdminView = false,
  }) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDepartment = '';
  String _selectedStatus = '';
  String _selectedPriority = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<UserModel?> get currentUser async {
    final authService = Provider.of<AuthService>(context, listen: false);
    return await authService.getCurrentUserModel();
  }

  Stream<List<TaskModel>> _getFilteredTasks() async* {
    final taskService = Provider.of<TaskService>(context, listen: false);
    final user = await currentUser;

    if (_selectedDepartment.isNotEmpty) {
      yield* taskService.getTasksByDepartment(_selectedDepartment);
    } else if (user != null) {
      yield* taskService.getTasksByUser(user.id);
    } else {
      yield* taskService.getAllTasksStream();
    }
  }

  void _navigateToTaskDetail(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  void _navigateToCreateTask() {
    Navigator.pushNamed(context, '/create_task');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevler'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: _getFilteredTasks(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final tasks = snapshot.data!;
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text('Görev bulunamadı'),
                  );
                }

                final filteredTasks = tasks.where((task) {
                  if (_searchQuery.isNotEmpty &&
                      !task.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
                    return false;
                  }

                  if (_selectedStatus.isNotEmpty && task.status != _selectedStatus) {
                    return false;
                  }

                  if (_selectedPriority.isNotEmpty && task.priority != _selectedPriority) {
                    return false;
                  }

                  return true;
                }).toList();

                if (filteredTasks.isEmpty) {
                  return const Center(
                    child: Text('Filtrelere uygun görev bulunamadı'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TaskListItem(
                        task: task,
                        onTap: () => _navigateToTaskDetail(task),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<UserModel?>(
        future: currentUser,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          
          final isAdmin = snapshot.data?.role == AppConstants.roleAdmin;
          if (!isAdmin) return const SizedBox();

          return FloatingActionButton(
            onPressed: _navigateToCreateTask,
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Görev ara...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final user = await currentUser;
    final isAdmin = user?.role == AppConstants.roleAdmin;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrele'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAdmin) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedDepartment.isEmpty ? null : _selectedDepartment,
                      decoration: const InputDecoration(
                        labelText: 'Departman',
                        border: OutlineInputBorder(),
                      ),
                      items: AppConstants.departments.map((department) {
                        return DropdownMenuItem<String>(
                          value: department,
                          child: Text(department),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedDepartment = value ?? '');
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<String>(
                    value: _selectedStatus.isEmpty ? null : _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(),
                    ),
                    items: AppConstants.taskStatusLabels.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value ?? '');
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPriority.isEmpty ? null : _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Öncelik',
                      border: OutlineInputBorder(),
                    ),
                    items: AppConstants.taskPriorityLabels.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPriority = value ?? '');
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDepartment = '';
                      _selectedStatus = '';
                      _selectedPriority = '';
                    });
                  },
                  child: const Text('Temizle'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }
}