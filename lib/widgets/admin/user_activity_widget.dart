import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/color_constants.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';

class UserActivityWidget extends StatelessWidget {
  const UserActivityWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context);
    final userService = Provider.of<UserService>(context);

    return FutureBuilder<List<TaskModel>>(
      future: taskService.getAllTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? [];
        // Son 5 aktiviteyi al ve tarihe göre sırala
        final recentTasks = tasks
          .where((task) => task.status == 'completed')
          .toList()
          ..sort((a, b) => b.completedAt?.compareTo(a.completedAt ?? DateTime.now()) ?? 0);
        final recentActivities = recentTasks.take(5).toList();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kullanıcı Aktiviteleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (recentActivities.isEmpty)
                  const Center(
                    child: Text('Henüz aktivite bulunmamaktadır'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentActivities.length,
                    itemBuilder: (context, index) {
                      final task = recentActivities[index];
                      return FutureBuilder<UserModel?>(
                        future: userService.getUserById(task.assignedTo),
                        builder: (context, userSnapshot) {
                          final user = userSnapshot.data;
                          if (!userSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }
                          return _buildActivityItem(
                            user?.name ?? 'Bilinmeyen Kullanıcı',
                            'Görev tamamlandı: ${task.title}',
                            task.completedAt ?? DateTime.now(),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(String user, String activity, DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: ColorConstants.primaryColor.withOpacity(0.2),
            child: Text(
              user.isNotEmpty ? user[0].toUpperCase() : '?',
              style: TextStyle(
                color: ColorConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  activity,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(time),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}d önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s önce';
    } else {
      return '${difference.inDays}g önce';
    }
  }
}
