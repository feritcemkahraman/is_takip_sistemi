import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserListTile extends StatelessWidget {
  final UserModel user;
  final bool isCreator;
  final VoidCallback? onTap;
  final bool showTrailing;

  const UserListTile({
    Key? key,
    required this.user,
    this.isCreator = false,
    this.onTap,
    this.showTrailing = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.1),
        child: Text(
          user.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(user.name),
      subtitle: Text(user.role == 'admin' ? 'Yönetici' : 'Çalışan'),
      trailing: showTrailing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCreator)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Oluşturan',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            )
          : null,
      onTap: onTap,
    );
  }
} 