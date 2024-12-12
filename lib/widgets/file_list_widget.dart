import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../constants/app_theme.dart';

class FileListWidget extends StatefulWidget {
  final String taskId;

  const FileListWidget({
    super.key,
    required this.taskId,
  });

  @override
  State<FileListWidget> createState() => _FileListWidgetState();
}

class _FileListWidgetState extends State<FileListWidget> {
  bool _isLoading = false;

  Future<void> _deleteFile(String fileUrl) async {
    setState(() => _isLoading = true);

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final taskService = Provider.of<TaskService>(context, listen: false);

      await storageService.deleteFile(fileUrl);
      await taskService.removeAttachment(widget.taskId, fileUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya silinirken hata: $e'),
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

  Future<void> _openFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Dosya açılamadı';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya açılırken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: storageService.getTaskFiles(widget.taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }

        final files = snapshot.data ?? [];

        if (files.isEmpty) {
          return const Center(
            child: Text('Henüz dosya eklenmemiş'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            final fileType = file['fileType'] as String;
            final fileName = file['fileName'] as String;
            final fileSize = file['size'] as int;
            final uploadedAt = DateTime.parse(file['uploadedAt']);
            final fileUrl = file['url'] as String;
            final uploaderId = file['userId'] as String;

            return Card(
              child: ListTile(
                leading: Icon(
                  storageService.getFileIcon(fileType),
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
                title: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(storageService.formatFileSize(fileSize)),
                    Text(
                      '${uploadedAt.day}/${uploadedAt.month}/${uploadedAt.year} ${uploadedAt.hour}:${uploadedAt.minute}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _openFile(fileUrl),
                      color: AppTheme.primaryColor,
                    ),
                    if (currentUser?.uid == uploaderId || currentUser?.role == 'admin')
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _isLoading ? null : () => _deleteFile(fileUrl),
                        color: Colors.red,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
} 