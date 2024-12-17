import 'package:flutter/material.dart';
import '../../constants/color_constants.dart';

class UserActivityWidget extends StatelessWidget {
  const UserActivityWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildActivityItem(
                  'Kullanıcı ${index + 1}',
                  'Görev tamamlandı: Task ${index + 1}',
                  DateTime.now().subtract(Duration(hours: index)),
                );
              },
            ),
          ],
        ),
      ),
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
              user.substring(0, 1),
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
