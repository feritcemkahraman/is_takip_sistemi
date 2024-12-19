import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../screens/tasks/task_detail_screen.dart';
import 'package:provider/provider.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool showAssignee;
  final VoidCallback onStatusChanged;

  const TaskCard({
    Key? key,
    required this.task,
    this.showAssignee = true,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(
                task: task,
                canInteract: true,
              ),
            ),
          ).then((_) => onStatusChanged());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (task.priority > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getPriorityText(task.priority),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(task.description),
              const SizedBox(height: 8),
              if (showAssignee)
                FutureBuilder<UserModel?>(
                  future: context.read<UserService>().getUserById(task.assignedTo),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return Text(
                      'Atanan: ${user?.name ?? 'Yükleniyor...'}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(task.status),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    'Bitiş: ${task.deadline.day}/${task.deadline.month}/${task.deadline.year}',
                    style: TextStyle(
                      color: task.deadline.isBefore(DateTime.now())
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'active':
        return 'Aktif';
      default:
        return 'Beklemede';
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 3:
        return 'Yüksek';
      case 2:
        return 'Orta';
      default:
        return 'Düşük';
    }
  }
}
