import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserSelectorWidget extends StatefulWidget {
  final Function(String) onUserSelected;
  final String? excludeUserId;
  final String? selectedUserId;

  const UserSelectorWidget({
    Key? key,
    required this.onUserSelected,
    this.excludeUserId,
    this.selectedUserId,
  }) : super(key: key);

  @override
  _UserSelectorWidgetState createState() => _UserSelectorWidgetState();
}

class _UserSelectorWidgetState extends State<UserSelectorWidget> {
  final UserService _userService = UserService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcılar yüklenirken hata: $e')),
        );
      }
    }
  }

  List<UserModel> get _filteredUsers {
    return _users.where((user) {
      if (widget.excludeUserId != null &&
          user.id == widget.excludeUserId) {
        return false;
      }

      if (_searchQuery.isEmpty) {
        return true;
      }

      return user.name.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Kullanıcı Ara',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 8),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredUsers.isEmpty)
          const Center(
            child: Text(
              'Kullanıcı bulunamadı',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              final isSelected = user.id == widget.selectedUserId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () => widget.onUserSelected(user.id),
                selected: isSelected,
              );
            },
          ),
      ],
    );
  }
} 