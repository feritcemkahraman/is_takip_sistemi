import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    Key? key,
    required this.taskId,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final taskService = Provider.of<TaskService>(context, listen: false);
      final currentUser = await authService.getCurrentUserModel();

      if (currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      await taskService.addComment(widget.taskId, _commentController.text, currentUser.id);
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yorum eklenirken hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Detayı'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<TaskModel?>(
        stream: Provider.of<TaskService>(context).getTaskStream(widget.taskId),
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

          final task = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(AppConstants.taskStatusColors[task.status]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppConstants.taskStatusLabels[task.status]!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(AppConstants.taskPriorityColors[task.priority]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppConstants.taskPriorityLabels[task.priority]!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 8),
                    FutureBuilder<UserModel?>(
                      future: Provider.of<AuthService>(context).getUserById(task.assignedTo),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final user = snapshot.data!;
                          return Text(
                            '${user.name} (${user.department})',
                            style: Theme.of(context).textTheme.bodyLarge,
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    Text(
                      'Bitiş: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                      style: TextStyle(
                        color: task.isOverdue ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
                if (task.progress > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: task.progress / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            task.isCompleted ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '%${task.progress.toInt()}',
                        style: TextStyle(
                          color: task.isCompleted ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                if (task.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: task.tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        onDeleted: () async {
                          try {
                            await Provider.of<TaskService>(context, listen: false)
                                .removeTaskTag(task.id, tag);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Etiket silinirken hata oluştu: $e')),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Yorumlar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _commentController,
                        labelText: 'Yorum ekle',
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isLoading ? null : _addComment,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Provider.of<TaskService>(context).getComments(task.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Hata: ${snapshot.error}');
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final comments = snapshot.data!;
                    if (comments.isEmpty) {
                      return const Text('Henüz yorum yok');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return FutureBuilder<UserModel?>(
                          future: Provider.of<AuthService>(context)
                              .getUserById(comment['userId'] as String),
                          builder: (context, snapshot) {
                            final userName = snapshot.data?.name ?? 'Bilinmeyen Kullanıcı';
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(comment['text'] as String),
                                subtitle: Text(userName),
                                trailing: Text(
                                  '${(comment['createdAt'] as Timestamp).toDate().day}/'
                                  '${(comment['createdAt'] as Timestamp).toDate().month}/'
                                  '${(comment['createdAt'] as Timestamp).toDate().year}',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
