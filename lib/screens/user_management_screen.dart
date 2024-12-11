import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_theme.dart';
import '../services/auth_service.dart';

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
      body: StreamBuilder<QuerySnapshot>(
        stream: _authService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(
              child: Text('Henüz kullanıcı bulunmuyor.'),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text(
                    userData['name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kullanıcı Adı: ${userData['username'] ?? ''}'),
                      Text('Departman: ${userData['department'] ?? ''}'),
                      Text(
                        'Rol: ${userData['role'] == 'admin' ? 'Yönetici' : 'Çalışan'}',
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      try {
                        switch (value) {
                          case 'toggle_status':
                            await _authService.updateUserStatus(
                              userId,
                              !(userData['isActive'] ?? true),
                            );
                            break;
                          case 'make_admin':
                            await _authService.updateUserRole(
                              userId,
                              'admin',
                            );
                            break;
                          case 'make_employee':
                            await _authService.updateUserRole(
                              userId,
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
                          userData['isActive'] == true
                              ? 'Pasif Yap'
                              : 'Aktif Yap',
                        ),
                      ),
                      PopupMenuItem(
                        value: userData['role'] == 'admin'
                            ? 'make_employee'
                            : 'make_admin',
                        child: Text(
                          userData['role'] == 'admin'
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
