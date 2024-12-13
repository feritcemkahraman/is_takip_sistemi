import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileUploadWidget extends StatelessWidget {
  final Function(String, String) onFileSelected;
  final String? acceptedFileTypes;
  final bool allowMultiple;
  final double? maxFileSize;

  const FileUploadWidget({
    super.key,
    required this.onFileSelected,
    this.acceptedFileTypes,
    this.allowMultiple = false,
    this.maxFileSize,
  });

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: acceptedFileTypes?.split(','),
        allowMultiple: allowMultiple,
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.path != null) {
            if (maxFileSize != null &&
                file.size > (maxFileSize! * 1024 * 1024)) {
              throw 'Dosya boyutu çok büyük';
            }
            onFileSelected(file.path!, file.name);
          }
        }
      }
    } catch (e) {
      print('Dosya seçme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _pickFile,
      icon: const Icon(Icons.upload_file),
      label: const Text('Dosya Seç'),
    );
  }
} 