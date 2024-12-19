import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../widgets/user_list_tile.dart';
import '../widgets/user_search_delegate.dart';
import 'chat_detail_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({Key? key}) : super(key: key);

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _searchController = TextEditingController();
  late UserService _userService;
  late ChatService _chatService;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _userService = Provider.of<UserService>(context, listen: false);
    _chatService = Provider.of<ChatService>(context, listen: false);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcılar yüklenirken hata: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    try {
      setState(() => _isLoading = true);
      final users = await _userService.searchUsers(query);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama yapılırken hata: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startChat(UserModel user) async {
    try {
      setState(() => _isLoading = true);
      final currentUser = await _chatService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Mevcut sohbetleri getir
      final existingChats = await _chatService.getChats().first;
      
      // Birebir sohbetleri filtrele
      final existingChat = existingChats.where((chat) => 
        !chat.isGroup && // Grup sohbeti olmamalı
        chat.participants.length == 2 && // İki kişilik olmalı
        chat.participants.contains(currentUser.id) && // Mevcut kullanıcı olmalı
        chat.participants.contains(user.id) // Seçilen kullanıcı olmalı
      ).firstOrNull;

      if (existingChat != null) {
        // Mevcut sohbete yönlendir
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(chat: existingChat),
            ),
          );
        }
        return;
      }

      // Mevcut sohbet yoksa yeni sohbet oluştur
      final chat = await _chatService.createChat(
        name: user.name,
        participants: [user.id],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(chat: chat),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sohbet başlatılırken hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Kullanıcı ara...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[200]),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadUsers();
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            if (value.length >= 3) {
              _searchUsers(value);
            } else if (value.isEmpty) {
              _loadUsers();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Kullanıcı Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(
                        child: Text('Kullanıcı bulunamadı'),
                      )
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return UserListTile(
                            user: user,
                            showTrailing: false,
                            onTap: () => _startChat(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 