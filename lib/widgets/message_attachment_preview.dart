import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageAttachmentPreview extends StatelessWidget {
  final String url;
  final String type;

  const MessageAttachmentPreview({
    Key? key,
    required this.url,
    required this.type,
  }) : super(key: key);

  Future<void> _openUrl() async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'URL açılamadı: $url';
      }
    } catch (e) {
      print('URL açılırken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'image':
        return GestureDetector(
          onTap: _openUrl,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  width: 200,
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error),
                  ),
                );
              },
            ),
          ),
        );

      case 'voice':
        return GestureDetector(
          onTap: _openUrl,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.mic),
                SizedBox(width: 8),
                Text('Sesli Mesaj'),
              ],
            ),
          ),
        );

      case 'file':
        return GestureDetector(
          onTap: _openUrl,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.attach_file),
                SizedBox(width: 8),
                Text('Dosya'),
              ],
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }
} 