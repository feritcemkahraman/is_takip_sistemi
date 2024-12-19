import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../screens/chat_detail_screen.dart';

class UserSearchDelegate extends SearchDelegate<UserModel?> {
  final UserService userService;
  final ChatService chatService;

  UserSearchDelegate({
    required this.userService,
    required this.chatService,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
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
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text('Kullanıcı aramak için yazın...'),
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: userService.searchUsers(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('Kullanıcı bulunamadı'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(user.name[0].toUpperCase()),
              ),
              title: Text(user.name),
              subtitle: Text(user.department),
              onTap: () => _startChat(context, user),
            );
          },
        );
      },
    );
  }

  Future<void> _startChat(BuildContext context, UserModel user) async {
    try {
      final currentUser = userService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Yeni sohbet oluştur
      final chat = await chatService.createChat(
        name: user.name,
        participants: [user.id],
      );

      if (context.mounted) {
        // Arama ekranını kapat ve sohbet ekranına git
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(chat: chat),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sohbet başlatılırken hata: $e')),
        );
      }
    }
  }

  @override
  String get searchFieldLabel => 'Kullanıcı ara...';

  @override
  TextStyle? get searchFieldStyle => const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      );
} 