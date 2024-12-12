import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserListItem extends StatelessWidget {
  final UserModel user;

  const UserListItem({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.name[0].toUpperCase()),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.business,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  user.department,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.badge,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  user.role,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: user.isActive
            ? const Icon(
                Icons.check_circle,
                color: Colors.green,
              )
            : const Icon(
                Icons.cancel,
                color: Colors.red,
              ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/user_detail',
            arguments: user,
          );
        },
      ),
    );
  }
} 