import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../models/notification_model.dart';
import '../constants/app_theme.dart';
import 'task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = false;

  Future<void> _markAllAsRead() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    setState(() => _isLoading = true);
    try {
      await notificationService.markAllAsRead(currentUser.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm bildirimler okundu olarak işaretlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
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

  void _onNotificationTap(NotificationModel notification) async {
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);

    // Bildirimi okundu olarak işaretle
    await notificationService.markAsRead(notification.id);

    // Eğer bildirim bir görevle ilgiliyse, görev detayına git
    if (notification.taskId != null && mounted) {
      // TODO: Görev detayına yönlendir
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => TaskDetailScreen(taskId: notification.taskId!),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Kullanıcı bulunamadı'));
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _isLoading ? null : _markAllAsRead,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Tümünü Okundu İşaretle'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: notificationService.getNotifications(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text('Bildirim bulunmuyor'),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final theme = Theme.of(context);
    final backgroundColor =
        notification.isRead ? Colors.white : Colors.blue.withOpacity(0.1);

    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationModel.typeTaskAssigned:
        iconData = Icons.assignment;
        iconColor = Colors.blue;
        break;
      case NotificationModel.typeTaskUpdated:
        iconData = Icons.update;
        iconColor = Colors.orange;
        break;
      case NotificationModel.typeCommentAdded:
        iconData = Icons.comment;
        iconColor = Colors.green;
        break;
      case NotificationModel.typeTaskCompleted:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationModel.typeTaskOverdue:
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      case NotificationModel.typeTaskReminder:
        iconData = Icons.alarm;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Card(
      color: backgroundColor,
      child: ListTile(
        onTap: () => _onNotificationTap(notification),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year} ${notification.createdAt.hour}:${notification.createdAt.minute}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
} 