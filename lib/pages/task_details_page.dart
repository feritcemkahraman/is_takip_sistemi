import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskDetailsPage extends StatefulWidget {
  final String taskId;

  const TaskDetailsPage({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late Future<Task> _taskFuture;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTask();
    // Socket.IO odasına katıl
    SocketService.joinTask(widget.taskId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    // Socket.IO odasından ayrıl
    SocketService.leaveTask(widget.taskId);
    super.dispose();
  }

  Future<void> _loadTask() async {
    setState(() {
      _taskFuture = ApiService.getTaskById(widget.taskId);
    });
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.updateTask(widget.taskId, {'status': newStatus});
      _loadTask();
    } catch (e) {
      setState(() {
        _errorMessage = 'Görev durumu güncellenirken bir hata oluştu';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.addComment(
        widget.taskId,
        _commentController.text.trim(),
      );
      _commentController.clear();
      _loadTask();
    } catch (e) {
      setState(() {
        _errorMessage = 'Yorum eklenirken bir hata oluştu';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Detayı'),
      ),
      body: FutureBuilder<Task>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Görev yüklenirken bir hata oluştu',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadTask,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Öncelik: ${task.priority}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Durum: ${task.status}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Bitiş: ${DateFormat('dd.MM.yyyy').format(task.dueDate)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: task.dueDate.isBefore(DateTime.now())
                                ? Colors.red
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Oluşturulma: ${DateFormat('dd.MM.yyyy').format(task.createdAt)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _updateTaskStatus('beklemede'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              task.status == 'beklemede' ? Colors.orange : null,
                        ),
                        child: const Text('Beklemede'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _updateTaskStatus('devam ediyor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              task.status == 'devam ediyor' ? Colors.blue : null,
                        ),
                        child: const Text('Devam Ediyor'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _updateTaskStatus('tamamlandı'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              task.status == 'tamamlandı' ? Colors.green : null,
                        ),
                        child: const Text('Tamamlandı'),
                      ),
                    ),
                  ],
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
                if (task.attachments.isEmpty)
                  const Text('Henüz ek bulunmuyor')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: task.attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = task.attachments[index];
                      return ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(attachment.split('/').last),
                        onTap: () {
                          // Dosyayı indir veya görüntüle
                        },
                      );
                    },
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
                  itemCount: task.comments.length,
                  itemBuilder: (context, index) {
                    final comment = task.comments[index];
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
                              DateFormat('dd.MM.yyyy HH:mm')
                                  .format(comment.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
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
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _isLoading ? null : _addComment,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 