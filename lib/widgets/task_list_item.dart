import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../constants/app_constants.dart';
import '../screens/task_detail_screen.dart';

class TaskListItem extends StatelessWidget {
  final TaskModel task;

  const TaskListItem({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: ListTile(
        leading: Container(
          width: 12,
          height: double.infinity,
          color: AppConstants.statusColors[task.status],
        ),
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: AppConstants.statusColors[task.status],
                ),
                const SizedBox(width: 4),
                Text(
                  AppConstants.statusLabels[task.status] ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.calendar_today,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: task.priority == TaskModel.priorityHigh
            ? const Icon(
                Icons.priority_high,
                color: Colors.red,
              )
            : null,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/task_detail',
            arguments: task,
          );
        },
      ),
    );
  }
} 