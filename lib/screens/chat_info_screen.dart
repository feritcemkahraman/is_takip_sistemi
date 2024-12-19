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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String formattedDate;
    if (date == today) {
      formattedDate = 'Bugün';
    } else if (date == today.subtract(const Duration(days: 1))) {
      formattedDate = 'Dün';
    } else {
      formattedDate = '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    }

    final formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$formattedDate $formattedTime';
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
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Oluşturulma: ${_formatDateTime(widget.chat.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (widget.chat.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.chat.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
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