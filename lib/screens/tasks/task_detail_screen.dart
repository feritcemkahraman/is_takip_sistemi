import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../services/local_storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/comment_model.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  final bool canInteract;

  const TaskDetailScreen({
    Key? key,
    required this.task,
    this.canInteract = true,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingComment = false;
  bool _isUploadingFile = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final currentUser = userService.currentUser;
    final canInteract = widget.canInteract && currentUser != null;

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
                                  widget.task.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (widget.task.priority > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(widget.task.priority),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getPriorityText(widget.task.priority),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.task.description,
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
                                  color: _getStatusColor(widget.task.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(widget.task.status),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          FutureBuilder<UserModel?>(
                            future: userService.getUserById(widget.task.assignedTo),
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
                                    'Oluşturulma',
                                    _formatDate(widget.task.createdAt),
                                    Icons.calendar_today,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    'Bitiş',
                                    _formatDate(widget.task.deadline),
                                    Icons.event,
                                    color: widget.task.deadline.isBefore(DateTime.now())
                                        ? Colors.red
                                        : null,
                                  ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Ekler',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (canInteract)
                                IconButton(
                                  icon: const Icon(Icons.attach_file),
                                  onPressed: _pickFile,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (widget.task.attachments.isEmpty)
                            const Text('Henüz ek yok')
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.task.attachments.length,
                              itemBuilder: (context, index) {
                                final attachment = widget.task.attachments[index];
                                final fileName = attachment.split('/').last;
                                final isImage = ['.jpg', '.jpeg', '.png', '.gif']
                                    .any((ext) => fileName.toLowerCase().endsWith(ext));

                                return Card(
                                  child: Column(
                                    children: [
                                      if (isImage)
                                        FutureBuilder<File?>(
                                          future: context
                                              .read<LocalStorageService>()
                                              .getTaskAttachment(attachment),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData && snapshot.data != null) {
                                              return Image.file(
                                                snapshot.data!,
                                                height: 200,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ListTile(
                                        leading: Icon(
                                          isImage ? Icons.image : Icons.attachment,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        title: Text(fileName),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_red_eye),
                                              onPressed: () => _openAttachment(attachment),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.download),
                                              onPressed: () => _downloadAttachment(attachment),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Yorumlar Bölümü
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Yorumlar',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (canInteract)
                                IconButton(
                                  icon: const Icon(Icons.add_comment),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(context).viewInsets.bottom,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: _commentController,
                                                decoration: const InputDecoration(
                                                  hintText: 'Yorumunuzu yazın...',
                                                  border: OutlineInputBorder(),
                                                ),
                                                maxLines: 3,
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context),
                                                    child: const Text('İptal'),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      _addComment();
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Gönder'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<CommentModel>>(
                            stream: context
                                .read<TaskService>()
                                .getTaskComments(widget.task.id),
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
                                    future: userService.getUserById(comment.userId),
                                    builder: (context, snapshot) {
                                      final user = snapshot.data;
                                      return Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundImage: user?.avatar != null
                                                        ? NetworkImage(user!.avatar!)
                                                        : null,
                                                    child: user?.avatar == null
                                                        ? Text(
                                                            user?.name.substring(0, 1) ??
                                                                '?',
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          user?.name ?? 'Yükleniyor...',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          _formatDate(comment.createdAt),
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodySmall,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(comment.text),
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
                        ],
                      ),
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
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
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

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSendingComment = true);

    try {
      final currentUser = context.read<UserService>().currentUser;
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final comment = CommentModel(
        id: const Uuid().v4(),
        taskId: widget.task.id,
        userId: currentUser.id,
        text: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await context.read<TaskService>().addComment(comment);
      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yorum eklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() => _isSendingComment = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      setState(() => _isUploadingFile = true);

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final storageService = context.read<LocalStorageService>();
      
      // Dosyayı local storage'a kaydet
      final savedFilePath = await storageService.saveTaskAttachment(
        widget.task.id,
        fileName,
        file,
      );

      // Firestore'a dosya yolunu ekle
      await context.read<TaskService>().addAttachment(widget.task.id, savedFilePath);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya başarıyla yüklendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya yüklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _downloadAttachment(String filePath) async {
    try {
      final file = await context.read<LocalStorageService>().getTaskAttachment(filePath);
      if (file == null) throw Exception('Dosya bulunamadı');

      // Dosyayı indirme klasörüne kopyala
      final fileName = filePath.split('/').last;
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) throw Exception('İndirme klasörü bulunamadı');

      final targetPath = '${downloadsDir.path}/$fileName';
      await file.copy(targetPath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya indirildi: $targetPath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya indirilirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _openAttachment(String filePath) async {
    try {
      final localStorageService = context.read<LocalStorageService>();
      final file = await localStorageService.getTaskAttachment(filePath);
      
      if (file != null) {
        final uri = Uri.file(file.path);
        if (!await launchUrl(uri)) {
          throw Exception('Dosya açılamadı');
        }
      } else {
        throw Exception('Dosya bulunamadı');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya açılamadı: $e')),
      );
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
