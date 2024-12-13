import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class UserSelectorWidget extends StatefulWidget {
  final String? selectedUserId;
  final Function(String) onUserSelected;
  final String? excludeUserId;
  final String? department;

  const UserSelectorWidget({
    super.key,
    this.selectedUserId,
    required this.onUserSelected,
    this.excludeUserId,
    this.department,
  });

  @override
  State<UserSelectorWidget> createState() => _UserSelectorWidgetState();
}

class _UserSelectorWidgetState extends State<UserSelectorWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı Ara',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        FutureBuilder<List<UserModel>>(
          future: widget.department != null
              ? authService.getUsersByDepartment(widget.department!)
              : authService.getAllUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Hata: ${snapshot.error}'));
            }

            final users = snapshot.data ?? [];
            final filteredUsers = users.where((user) {
              if (widget.excludeUserId != null &&
                  user.id == widget.excludeUserId) {
                return false;
              }
              if (_searchQuery.isEmpty) return true;
              return user.name.toLowerCase().contains(_searchQuery) ||
                  user.username.toLowerCase().contains(_searchQuery) ||
                  user.department.toLowerCase().contains(_searchQuery);
            }).toList();

            if (filteredUsers.isEmpty) {
              return const Center(child: Text('Kullanıcı bulunamadı'));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final isSelected = user.id == widget.selectedUserId;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isSelected ? Colors.blue : Colors.grey.shade200,
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.department),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () => widget.onUserSelected(user.id),
                );
              },
            );
          },
        ),
      ],
    );
  }
} 