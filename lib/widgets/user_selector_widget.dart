import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserSelectorWidget extends StatefulWidget {
  final List<String> selectedUserIds;
  final bool multiSelect;
  final Function(List<String>) onUsersSelected;

  const UserSelectorWidget({
    super.key,
    this.selectedUserIds = const [],
    this.multiSelect = false,
    required this.onUsersSelected,
  });

  @override
  State<UserSelectorWidget> createState() => _UserSelectorWidgetState();
}

class _UserSelectorWidgetState extends State<UserSelectorWidget> {
  final _authService = AuthService();
  final _searchController = TextEditingController();
  List<UserModel> _users = [];
  List<String> _selectedUserIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedUserIds = List.from(widget.selectedUserIds);
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
      final users = await _authService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kullanıcılar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleUser(String userId) {
    setState(() {
      if (widget.multiSelect) {
        if (_selectedUserIds.contains(userId)) {
          _selectedUserIds.remove(userId);
        } else {
          _selectedUserIds.add(userId);
        }
      } else {
        _selectedUserIds = [userId];
      }
      widget.onUsersSelected(_selectedUserIds);
    });
  }

  List<UserModel> _getFilteredUsers() {
    final query = _searchController.text.toLowerCase();
    return _users.where((user) {
      return user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Kullanıcı Ara',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_users.isEmpty)
          const Center(child: Text('Kullanıcı bulunamadı'))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _getFilteredUsers().length,
              itemBuilder: (context, index) {
                final user = _getFilteredUsers()[index];
                final isSelected = _selectedUserIds.contains(user.id);
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user.displayName[0]),
                  ),
                  title: Text(user.displayName),
                  subtitle: Text(user.email),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.check_circle_outline),
                  onTap: () => _toggleUser(user.id),
                );
              },
            ),
          ),
      ],
    );
  }
} 