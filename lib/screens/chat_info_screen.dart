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
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Text(user.name[0].toUpperCase()),
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.department),
                            trailing: user.id == widget.chat.createdBy
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Oluşturan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Sohbetten Ayrıl
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              await _chatService.leaveChat(widget.chat.id);
                              if (mounted) {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Hata: $e')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Sohbetten Ayrıl'),
                  ),
                ),
              ],
            ),
    );
  }
} 