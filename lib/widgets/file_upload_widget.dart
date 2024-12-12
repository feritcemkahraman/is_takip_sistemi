import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../constants/app_theme.dart';

class FileUploadWidget extends StatefulWidget {
  final String taskId;

  const FileUploadWidget({
    super.key,
    required this.taskId,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  bool _isLoading = false;
  File? _selectedFile;
  final _maxFileSize = 10 * 1024 * 1024; // 10MB

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        if (fileSize > _maxFileSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dosya boyutu 10MB\'dan büyük olamaz'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() => _selectedFile = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya seçilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final taskService = Provider.of<TaskService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null) throw 'Kullanıcı bulunamadı';

      final downloadUrl = await storageService.uploadFile(
        file: _selectedFile!,
        taskId: widget.taskId,
        userId: currentUser.uid,
      );

      await taskService.addAttachment(widget.taskId, downloadUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya başarıyla yüklendi'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _selectedFile = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya yüklenirken hata: $e'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dosya Ekle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedFile == null)
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _pickFile,
            icon: const Icon(Icons.attach_file),
            label: const Text('Dosya Seç'),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFile!.path.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.upload),
                      onPressed: _uploadFile,
                      color: AppTheme.primaryColor,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedFile = null),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
} 