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

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSendingComment = true);

    try {
      final currentUser = context.read<UserService>().currentUser;
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      await context.read<TaskService>().addComment(
        taskId: widget.task.id,
        userId: currentUser.id,
        content: _commentController.text.trim(),
      );

      // Yorum bildirimini gönder
      if (currentUser.id != widget.task.assignedTo) {
        await context.read<NotificationService>().sendNotification(
          userId: widget.task.assignedTo,
          title: 'Yeni Yorum',
          body: '${currentUser.name} görevinize yorum yaptı: ${_commentController.text.trim()}',
          data: {
            'type': 'task_comment',
            'taskId': widget.task.id,
          },
        );
      }

      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorum eklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yorum eklenirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingComment = false);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result == null) return;

      setState(() => _isUploadingFile = true);

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      final storageService = context.read<LocalStorageService>();
      final currentUser = context.read<UserService>().currentUser;
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');
      
      // Dosyayı local storage'a kaydet
      final savedFilePath = await storageService.saveTaskAttachment(
        widget.task.id,
        fileName,
        file,
      );

      // Firestore'a dosya yolunu ekle
      await context.read<TaskService>().addAttachment(widget.task.id, savedFilePath);

      // Dosya ekleme bildirimini gönder
      if (currentUser.id != widget.task.assignedTo) {
        await context.read<NotificationService>().sendNotification(
          userId: widget.task.assignedTo,
          title: 'Yeni Dosya',
          body: '${currentUser.name} görevinize yeni bir dosya ekledi: $fileName',
          data: {
            'type': 'task_attachment',
            'taskId': widget.task.id,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosya başarıyla yüklendi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya yüklenirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya indirildi: $targetPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya indirilirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      if (filePath.toLowerCase().endsWith('.jpg') ||
          filePath.toLowerCase().endsWith('.jpeg') ||
          filePath.toLowerCase().endsWith('.png')) {
        
        // Local storage'dan dosyayı al
        final file = await context.read<LocalStorageService>().getTaskAttachment(filePath);
        if (file == null) throw Exception('Dosya bulunamadı');
        
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: Text(filePath.split('/').last),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Flexible(
                    child: InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.5,
                      maxScale: 4,
                      child: Image.file(
                        file,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text('Görsel yüklenemedi'),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        // Diğer dosya türleri için uyarı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu dosya türü şu anda görüntülenemiyor'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya açılamadı: $e')),
        );
      }
    }
  }

  // Görev tamamlama işlemi
  Future<void> _completeTask() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Görevi Tamamla'),
          content: const Text('Bu görevi tamamlandı olarak işaretlemek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tamamla'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await context.read<TaskService>().completeTask(widget.task.id);
        
        // Görev tamamlama bildirimini gönder
        final currentUser = context.read<UserService>().currentUser;
        if (currentUser != null) {
          final assignedUser = await context.read<UserService>().getUserById(widget.task.assignedTo);
          if (assignedUser != null) {
            await context.read<NotificationService>().sendNotification(
              userId: widget.task.createdBy,
              title: 'Görev Tamamlandı',
              body: '${assignedUser.name} görevi tamamladı: ${widget.task.title}',
              data: {
                'type': 'task_completed',
                'taskId': widget.task.id,
              },
            );
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Görev tamamlandı olarak işaretlendi')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final currentUser = userService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Detayı'),
        actions: [
          if (widget.canInteract && widget.task.status != 'completed' && 
              currentUser?.id == widget.task.assignedTo)
            Container(
              margin: const EdgeInsets.only(right: 16),
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
                                    _formatDate(widget.task.deadline ?? DateTime.now()),
                                    Icons.event,
                                    color: widget.task.deadline?.isBefore(DateTime.now()) ?? false
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
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.attach_file),
                                  label: Text(_isUploadingFile ? 'Yükleniyor...' : 'Dosya Ekle'),
                                )
                              : null,
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: StreamBuilder<TaskModel>(
                            stream: context.read<TaskService>().getTaskStream(widget.task.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text('Hata: ${snapshot.error}');
                              }

                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final task = snapshot.data!;
                              if (task.attachments.isEmpty) {
                                return const Text('Henüz ek yok');
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: task.attachments.length,
                                itemBuilder: (context, index) {
                                  final attachment = task.attachments[index];
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
                                                onPressed: () => _openFile(attachment),
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
                              );
                            },
                          ),
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
                          trailing: currentUser != null
                              ? ElevatedButton.icon(
                                  onPressed: _isSendingComment
                                      ? null
                                      : () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Yorum Ekle'),
                                              content: TextField(
                                                controller: _commentController,
                                                decoration: const InputDecoration(
                                                  hintText: 'Yorumunuzu yazın...',
                                                  border: OutlineInputBorder(),
                                                ),
                                                maxLines: 3,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('İptal'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _addComment();
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('Gönder'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                  icon: _isSendingComment
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.add_comment),
                                  label: Text(_isSendingComment ? 'Gönderiliyor...' : 'Yorum Ekle'),
                                )
                              : null,
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: StreamBuilder<List<CommentModel>>(
                            stream: context.read<TaskService>().getTaskComments(widget.task.id),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text('Hata: ${snapshot.error}');
                              }

                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final comments = snapshot.data!;
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
                                                          _formatDate(comment.createdAt),
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 12,
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
