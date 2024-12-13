import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class UserManagementScreen extends StatelessWidget {
  final _authService = AuthService();

  UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: _authService.getAllUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text('Henüz kullanıcı bulunmuyor.'),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kullanıcı Adı: ${user.username}'),
                      Text('Departman: ${user.department}'),
                      Text(
                        'Rol: ${user.role == 'admin' ? 'Yönetici' : 'Çalışan'}',
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      try {
                        switch (value) {
                          case 'toggle_status':
                            await _authService.updateUserStatus(
                              user.uid,
                              !user.isActive,
                            );
                            break;
                          case 'make_admin':
                            await _authService.updateUserRole(
                              user.uid,
                              'admin',
                            );
                            break;
                          case 'make_employee':
                            await _authService.updateUserRole(
                              user.uid,
                              'employee',
                            );
                            break;
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('İşlem başarısız: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_status',
                        child: Text(
                          user.isActive ? 'Pasif Yap' : 'Aktif Yap',
                        ),
                      ),
                      PopupMenuItem(
                        value: user.role == 'admin'
                            ? 'make_employee'
                            : 'make_admin',
                        child: Text(
                          user.role == 'admin'
                              ? 'Çalışan Yap'
                              : 'Yönetici Yap',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
