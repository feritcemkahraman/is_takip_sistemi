import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../services/local_storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/comment_model.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final bool canInteract;

  const TaskDetailScreen({
    Key? key,
    required this.taskId,
    this.canInteract = true,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskService _taskService;
  late TaskModel? _task;
  bool _isLoading = true;
  bool _isUploadingFile = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<UserService>(context, listen: false);
    _taskService = TaskService(userService);
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final task = await _taskService.getTask(widget.taskId);
      if (task != null) {
        setState(() {
          _task = task;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Görev bulunamadı')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error loading task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görev yüklenirken hata oluştu: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _task == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userService = Provider.of<UserService>(context);
    final currentUser = userService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_task!.title),
        actions: [
          if (widget.canInteract && _task!.status != 'completed')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(
                  Icons.check_circle,
                  size: 24,
                ),
                label: const Text(
                  'Tamamlandı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _completeTask,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Görev Kartı
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _task!.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_task!.priority > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(_task!.priority),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getPriorityText(_task!.priority),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _task!.description,
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
                                  color: _getStatusColor(_task!.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(_task!.status),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          FutureBuilder<UserModel?>(
                            future: userService.getUserById(_task!.assignedTo),
                            builder: (context, snapshot) {
                              final assignedUser = snapshot.data;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    'Atanan',
                                    assignedUser?.name ?? 'Yükleniyor...',
                                    Icons.person,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Teslim Tarihi',
                                    '${_task!.deadline.day}/${_task!.deadline.month}/${_task!.deadline.year}',
                                    Icons.calendar_today,
                                  ),
                                  if (_task!.completedAt != null) ...[
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      'Tamamlanma Tarihi',
                                      '${_task!.completedAt!.day}/${_task!.completedAt!.month}/${_task!.completedAt!.year}',
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ekler Bölümü
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text(
                            'Ekler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: currentUser != null
                              ? ElevatedButton.icon(
                                  onPressed: _isUploadingFile ? null : _pickFile,
                                  icon: _isUploadingFile
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.attach_file),
                                  label: Text(_isUploadingFile ? 'Yükleniyor...' : 'Dosya Ekle'),
                                )
                              : null,
                        ),
                        const Divider(height: 1),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _taskService.getTaskAttachmentsStream(widget.taskId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(child: Text('Hata: ${snapshot.error}'));
                            }

                            final attachments = snapshot.data ?? [];

                            if (attachments.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Henüz dosya eklenmemiş'),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: attachments.length,
                              itemBuilder: (context, index) {
                                final attachment = attachments[index];
                                final fileName = attachment['name'] ?? '';
                                final extension = fileName.split('.').last.toLowerCase();
                                final localPath = attachment['localPath'] ?? '';

                                return ListTile(
                                  leading: Icon(
                                    _getFileIcon(extension),
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  title: Text(fileName),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () => _downloadFile(localPath),
                                      ),
                                      if (widget.canInteract)
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _deleteFile(localPath),
                                        ),
                                    ],
                                  ),
                                  onTap: () => _previewFile(localPath),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Yorumlar Bölümü
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text(
                            'Yorumlar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        if (widget.canInteract && currentUser != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
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
                                  onPressed: _addComment,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ],
                            ),
                          ),
                        StreamBuilder<List<CommentModel>>(
                          stream: _taskService.getTaskCommentsStream(widget.taskId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(child: Text('Hata: ${snapshot.error}'));
                            }

                            final comments = snapshot.data ?? [];

                            if (comments.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('Henüz yorum yapılmamış'),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                return FutureBuilder<UserModel?>(
                                  future: userService.getUserById(comment.userId),
                                  builder: (context, userSnapshot) {
                                    final user = userSnapshot.data;
                                    final isCurrentUser = currentUser?.id == comment.userId;
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                        children: [
                                          if (!isCurrentUser) ...[
                                            CircleAvatar(
                                              backgroundColor: Theme.of(context).primaryColor,
                                              child: Text(
                                                user?.name.substring(0, 1).toUpperCase() ?? '?',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isCurrentUser 
                                                    ? Theme.of(context).primaryColor.withOpacity(0.2)
                                                    : Colors.grey[200],
                                                borderRadius: BorderRadius.only(
                                                  topLeft: const Radius.circular(16),
                                                  topRight: const Radius.circular(16),
                                                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                                                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: isCurrentUser 
                                                    ? CrossAxisAlignment.end 
                                                    : CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        user?.name ?? 'Yükleniyor...',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: isCurrentUser 
                                                              ? Theme.of(context).primaryColor
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    comment.content,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (isCurrentUser) ...[
                                            const SizedBox(width: 8),
                                            CircleAvatar(
                                              backgroundColor: Theme.of(context).primaryColor,
                                              child: Text(
                                                user?.name.substring(0, 1).toUpperCase() ?? '?',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ],
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
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(color: color),
        ),
      ],
    );
  }

  Future<void> _completeTask() async {
    try {
      await _taskService.updateTaskStatus(widget.taskId, 'completed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görev tamamlandı')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() => _isUploadingFile = true);
        
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        
        await _taskService.uploadTaskFile(widget.taskId, file, fileName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya yüklendi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya yüklenirken hata: $e')),
        );
      }
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _downloadFile(String filePath) async {
    try {
      final file = await _taskService.getTaskFile(filePath);
      if (file == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya bulunamadı')),
          );
        }
        return;
      }

      final fileInfo = await _taskService.getTaskFileInfo(widget.taskId, filePath);
      if (fileInfo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya bilgisi bulunamadı')),
          );
        }
        return;
      }

      final downloadPath = await getExternalStorageDirectory();
      if (downloadPath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('İndirme dizini bulunamadı')),
          );
        }
        return;
      }

      final targetPath = path.join(downloadPath.path, fileInfo['name']);
      await file.copy(targetPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya indirildi: ${fileInfo['name']}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya indirme hatası: $e')),
        );
      }
    }
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      await _taskService.deleteTaskFile(widget.taskId, filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya silinirken hata: $e')),
        );
      }
    }
  }

  Future<void> _previewFile(String filePath) async {
    try {
      final file = await _taskService.getTaskFile(filePath);
      if (file == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya bulunamadı')),
          );
        }
        return;
      }

      final fileInfo = await _taskService.getTaskFileInfo(widget.taskId, filePath);
      if (fileInfo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dosya bilgisi bulunamadı')),
          );
        }
        return;
      }

      final extension = fileInfo['type']?.toLowerCase() ?? '';
      
      if (extension == 'jpg' || extension == 'jpeg' || extension == 'png') {
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Image.file(file),
            ),
          );
        }
      } else {
        if (mounted) {
          final uri = Uri.file(file.path);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dosya açılamadı')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya önizleme hatası: $e')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    try {
      await _taskService.addTaskComment(widget.taskId, comment);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yorum eklenirken hata: $e')),
        );
      }
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Düşük';
      case 2:
        return 'Orta';
      case 3:
        return 'Yüksek';
      default:
        return 'Belirsiz';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Devam Ediyor';
      case 'completed':
        return 'Tamamlandı';
      case 'pending':
        return 'Beklemede';
      default:
        return 'Belirsiz';
    }
  }
}
