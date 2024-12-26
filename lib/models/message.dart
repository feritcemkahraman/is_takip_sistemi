class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final List<String> attachments;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.attachments,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'],
      senderId: json['sender'],
      receiverId: json['receiver'],
      content: json['content'],
      attachments: List<String>.from(json['attachments'] ?? []),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'receiver': receiverId,
      'attachments': attachments,
    };
  }
} 