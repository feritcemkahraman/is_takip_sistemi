import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class FileListWidget extends StatelessWidget {
  final List<String> files;
  final String? uploaderId;
  final Function(String)? onDelete;

  const FileListWidget({
    super.key,
    required this.files,
    this.uploaderId,
    this.onDelete,
  });

  Future<void> _openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Dosya açılamadı';
      }
    } catch (e) {
      print('Dosya açma hatası: $e');
    }
  }

  String _getFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
      return url;
    } catch (e) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(
        child: Text('Henüz dosya eklenmemiş'),
      );
    }

    final currentUser = Provider.of<AuthService>(context).currentUser;
    final canDelete = onDelete != null &&
        (currentUser?.uid == uploaderId || currentUser?.role == 'admin');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final fileName = _getFileName(file);

        return Card(
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _openFile(file),
                ),
                if (canDelete)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onDelete!(file),
                    color: Colors.red,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
} 