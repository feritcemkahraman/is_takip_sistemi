import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/user_list_tile.dart';

class ChatInfoScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatInfoScreen({
    Key? key,
    required this.chat,
  }) : super(key: key);

  @override
  State<ChatInfoScreen> createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> {
  late ChatService _chatService;
  late UserService _userService;
  List<UserModel> _participants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatService = Provider.of<ChatService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      setState(() => _isLoading = true);
      final participants = await Future.wait(
        widget.chat.participants.map((userId) => _userService.getUserById(userId)),
      );
      setState(() {
        _participants = participants.whereType<UserModel>().toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Katılımcılar yüklenirken hata: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbet Bilgileri'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Sohbet Bilgileri
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.chat.avatar != null)
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(widget.chat.avatar!),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          widget.chat.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (widget.chat.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.chat.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Oluşturulma: ${widget.chat.createdAt.toLocal()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                // Katılımcılar
                Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Katılımcılar (${_participants.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _participants.length,
                        itemBuilder: (context, index) {
                          final user = _participants[index];
                          return UserListTile(
                            user: user,
                            isCreator: user.id == widget.chat.createdBy,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 