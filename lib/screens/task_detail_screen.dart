import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/file_upload_widget.dart';
import '../widgets/file_list_widget.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _commentController = TextEditingController();
  bool _isLoading = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _progress = widget.task.progress;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      final taskService = Provider.of<TaskService>(context, listen: false);
      await taskService.updateStatus(widget.task.id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Durum güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProgress(double value) async {
    setState(() => _isLoading = true);
    try {
      final taskService = Provider.of<TaskService>(context, listen: false);
      await taskService.updateProgress(widget.task.id, value);
      setState(() => _progress = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlerleme güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final taskService = Provider.of<TaskService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) throw 'Kullanıcı bulunamadı';

      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.uid,
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await taskService.addComment(widget.task.id, comment);
      if (mounted) {
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorum eklendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppConstants.statusColors[widget.task.status] ?? Colors.grey;
    final priorityColor = AppConstants.priorityColors[widget.task.priority] ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Detayı'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.task.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.circle, size: 16, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  AppConstants.statusLabels[widget.task.status] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 24),
                Icon(Icons.flag, size: 16, color: priorityColor),
                const SizedBox(width: 8),
                Text(
                  AppConstants.priorityLabels[widget.task.priority] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Bitiş: ${widget.task.dueDate.day}/${widget.task.dueDate.month}/${widget.task.dueDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'İlerleme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _progress,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${_progress.toInt()}%',
                    onChanged: (value) {
                      setState(() => _progress = value);
                    },
                    onChangeEnd: _updateProgress,
                  ),
                ),
                Text(
                  '%${_progress.toInt()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Durum Güncelle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.statusLabels.entries.map((entry) {
                return FilterChip(
                  label: Text(entry.value),
                  selected: widget.task.status == entry.key,
                  onSelected: (_) => _updateStatus(entry.key),
                  backgroundColor: Colors.grey[200],
                  selectedColor: AppConstants.statusColors[entry.key],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Yorumlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.task.comments.length,
              itemBuilder: (context, index) {
                final comment = widget.task.comments[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.content,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Yorum yaz...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 8),
                CustomButton(
                  text: 'Gönder',
                  onPressed: _isLoading ? null : _addComment,
                  isLoading: _isLoading,
                ),
              ],
            ),
            const SizedBox(height: 24),
            FileUploadWidget(taskId: widget.task.id),
            const SizedBox(height: 16),
            const Text(
              'Dosyalar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FileListWidget(taskId: widget.task.id),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
