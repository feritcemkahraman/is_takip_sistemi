import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService(
    firestore: FirebaseFirestore.instance,
  );
  final AuthService _authService = AuthService();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      await _notificationService.requestPermissions();
      await _notificationService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          StreamBuilder<int>(
            stream: _notificationService.getUnreadCount(_userId!),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount > 0) {
                return TextButton.icon(
                  onPressed: () => _notificationService.markAllAsRead(_userId!),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Tümünü Okundu İşaretle'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showDeleteAllDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotifications(_userId!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Bir hata oluştu: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const Center(
              child: Text('Henüz bildirim bulunmuyor'),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirim silindi')),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(notification.color),
          child: Icon(
            Icons.notifications,
            color: Colors.white,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.done),
                onPressed: () =>
                    _notificationService.markAsRead(notification.id),
              ),
        onTap: () {
          if (!notification.isRead) {
            _notificationService.markAsRead(notification.id);
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Bildirim tipine göre yönlendirme
    if (notification.data == null) return;
    
    switch (notification.type) {
      case NotificationModel.typeTask:
        if (notification.data!['taskId'] != null) {
          Navigator.pushNamed(
            context,
            '/task_detail',
            arguments: notification.data!['taskId'],
          );
        }
        break;
      case NotificationModel.typeMeeting:
        if (notification.data!['meetingId'] != null) {
          Navigator.pushNamed(
            context,
            '/meeting_detail',
            arguments: notification.data!['meetingId'],
          );
        }
        break;
      case NotificationModel.typeWorkflow:
        if (notification.data!['workflowId'] != null) {
          Navigator.pushNamed(
            context,
            '/workflow_detail',
            arguments: notification.data!['workflowId'],
          );
        }
        break;
      case NotificationModel.typeMessage:
        if (notification.data!['messageId'] != null) {
          Navigator.pushNamed(
            context,
            '/message_detail',
            arguments: notification.data!['messageId'],
          );
        }
        break;
    }
  }

  Future<void> _showDeleteAllDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Bildirimleri Sil'),
        content: const Text('Tüm bildirimler silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await _notificationService.deleteAllNotifications(_userId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm bildirimler silindi')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Az önce';
        }
        return '${difference.inMinutes} dakika önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
} 