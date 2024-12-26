class ChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final int unreadCount;
  final List<String> mutedBy;

  ChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.mutedBy = const [],
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['_id'],
      user1Id: json['user1Id'],
      user2Id: json['user2Id'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastMessage: json['lastMessage'],
      unreadCount: json['unreadCount'] ?? 0,
      mutedBy: List<String>.from(json['mutedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'mutedBy': mutedBy,
    };
  }

  ChatModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    int? unreadCount,
    List<String>? mutedBy,
  }) {
    return ChatModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      mutedBy: mutedBy ?? this.mutedBy,
    );
  }
} 