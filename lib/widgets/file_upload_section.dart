import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../constants/app_constants.dart';

class FileUploadSection extends StatefulWidget {
  final String taskId;

  const FileUploadSection({
    super.key,
    required this.taskId,
  });

  @override
  State<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends State<FileUploadSection> {
  final _storage = FirebaseStorage.instance;
  List<File> _selectedFiles = [];
  bool _isUploading = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(
          result.paths.where((path) => path != null).map((path) => File(path!)),
        );
      });
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      for (final file in _selectedFiles) {
        final fileName = file.path.split('/').last;
        final ref = _storage.ref().child('tasks/${widget.taskId}/$fileName');
        await ref.putFile(file);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosyalar başarıyla yüklendi')),
        );
        setState(() {
          _selectedFiles.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dosyalar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedFiles.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seçilen Dosyalar:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(_selectedFiles.length, (index) {
                  final file = _selectedFiles[index];
                  return ListTile(
                    dense: true,
                    title: Text(file.path.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedFiles.removeAt(index);
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Dosya Seç'),
              onPressed: _isUploading ? null : _pickFiles,
            ),
            const SizedBox(width: 8),
            if (_selectedFiles.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.upload),
                label: Text(_isUploading ? 'Yükleniyor...' : 'Yükle'),
                onPressed: _isUploading ? null : _uploadFiles,
              ),
          ],
        ),
      ],
    );
  }
}
