import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  final UserModel currentUser;
  final bool showAssignedTasks;

  const TasksScreen({
    Key? key,
    required this.currentUser,
    this.showAssignedTasks = true,
  }) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _taskService = TaskService();
  String _selectedStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.showAssignedTasks ? 'Görevlerim' : 'Oluşturduğum Görevler',
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '',
                child: Text('Tümü'),
              ),
              ...AppConstants.taskStatusLabels.entries.map(
                (status) => PopupMenuItem(
                  value: status.key,
                  child: Text(status.value),
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: widget.showAssignedTasks
            ? _taskService.getAssignedTasks(widget.currentUser.uid)
            : _taskService.getCreatedTasks(widget.currentUser.uid),
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
          final filteredTasks = _selectedStatus.isEmpty
              ? tasks
              : tasks.where((task) => task.status == _selectedStatus).toList();

          if (filteredTasks.isEmpty) {
            return Center(
              child: Text(
                _selectedStatus.isEmpty
                    ? 'Henüz görev yok'
                    : '${AppConstants.taskStatusLabels[_selectedStatus]} durumunda görev yok',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return TaskCard(
                task: task,
                showAssignee: !widget.showAssignedTasks,
                onStatusChanged: () => setState(() {}),
              );
            },
          );
        },
      ),
    );
  }
}
