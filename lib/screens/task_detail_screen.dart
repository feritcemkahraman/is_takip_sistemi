import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../services/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
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
      final taskService = context.read<TaskService>();
      final notificationService = context.read<NotificationService>();
      final currentUser = context.read<UserService>().currentUser;

      await taskService.addComment(
        widget.task.id,
        _commentController.text,
        currentUser?.id ?? '',
      );

      // Görev sahibine bildirim gönder
      if (widget.task.assignedTo != currentUser?.id) {
        await notificationService.sendNotification(
          userId: widget.task.assignedTo,
          title: 'Yeni Yorum',
          body: '${currentUser?.name} görevinize yorum ekledi',
          data: {'taskId': widget.task.id},
        );
      }

      if (mounted) {
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addAttachment() async {
    try {
      final taskService = context.read<TaskService>();
      final notificationService = context.read<NotificationService>();
      final currentUser = context.read<UserService>().currentUser;

      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null) {
        setState(() => _isLoading = true);
        
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        
        // Dosyayı yükle ve yolunu al
        String filePath = '${widget.task.id}/$fileName';
        await taskService.addAttachment(widget.task.id, filePath);

        // Görev sahibine bildirim gönder
        if (widget.task.assignedTo != currentUser?.id) {
          await notificationService.sendNotification(
            userId: widget.task.assignedTo,
            title: 'Yeni Dosya',
            body: '${currentUser?.name} göreve dosya ekledi',
            data: {'taskId': widget.task.id},
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya eklendi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
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
    final userService = context.watch<UserService>();
    final currentUser = userService.currentUser;
    final canInteract = currentUser?.id == widget.task.assignedTo || 
                       currentUser?.role == UserModel.roleAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Detayı'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(widget.task.description),
                  const SizedBox(height: 16),
                  FutureBuilder<UserModel?>(
                    future: userService.getUserById(widget.task.assignedTo),
                    builder: (context, snapshot) {
                      final assignedUser = snapshot.data;
                      return Text(
                        'Atanan: ${assignedUser?.name ?? 'Yükleniyor...'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bitiş: ${widget.task.deadline.day}/${widget.task.deadline.month}/${widget.task.deadline.year}',
                    style: TextStyle(
                      color: widget.task.deadline.isBefore(DateTime.now()) ? 
                             Colors.red : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ekler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.task.attachments.isEmpty)
                    const Text('Henüz ek bulunmuyor')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.task.attachments.length,
                      itemBuilder: (context, index) {
                        final attachment = widget.task.attachments[index];
                        final fileName = attachment.split('/').last;
                        return ListTile(
                          leading: const Icon(Icons.attachment),
                          title: Text(fileName),
                          onTap: () {
                            // Dosyayı aç
                          },
                        );
                      },
                    ),
                  if (canInteract) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addAttachment,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Dosya Ekle'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Yorumlar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: context.read<TaskService>().getTaskComments(widget.task.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final comments = snapshot.data ?? [];

                      if (comments.isEmpty) {
                        return const Text('Henüz yorum yapılmamış');
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return FutureBuilder<UserModel?>(
                            future: userService.getUserById(comment['userId']),
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            user?.name ?? 'Bilinmeyen Kullanıcı',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatDate(comment['timestamp']),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(comment['text']),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  if (canInteract) ...[
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
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addComment,
                          icon: const Icon(Icons.send),
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
