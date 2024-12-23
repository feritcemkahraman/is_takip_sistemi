import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserSearchDelegate extends SearchDelegate<UserModel?> {
  final List<UserModel> users;
  final String currentUserId;
  final UserService userService;

  UserSearchDelegate({
    required this.users,
    required this.currentUserId,
    required this.userService,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredUsers = users.where((user) {
      if (user.id == currentUserId) return false;
      
      final queryLower = query.toLowerCase();
      final nameLower = user.name.toLowerCase();
      final departmentLower = user.department.toLowerCase();
      
      return nameLower.contains(queryLower) || 
             departmentLower.contains(queryLower);
    }).toList();

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(user.name[0].toUpperCase()),
          ),
          title: Text(user.name),
          subtitle: Text(user.department),
          onTap: () {
            close(context, user);
          },
        );
      },
    );
  }
} 