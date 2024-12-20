import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final String name;
  final List<String> participants;
  final List<MessageModel> messages;
  final bool isGroup;
  final String? avatar;
  final String createdBy;
  final List<String> mutedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MessageModel? lastMessage;

  ChatModel({
    required this.id,
    required this.name,
    required this.participants,
    required this.messages,
    required this.isGroup,
    this.avatar,
    required this.createdBy,
    required this.mutedBy,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final messages = (data['messages'] as List<dynamic>? ?? [])
        .map((msg) => MessageModel.fromMap(msg as Map<String, dynamic>))
        .toList();

    // Son mesajı bul
    MessageModel? lastMessage;
    if (messages.isNotEmpty) {
      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      lastMessage = messages.first;
    }

    return ChatModel(
      id: doc.id,
      name: data['name'] as String,
      participants: List<String>.from(data['participants'] ?? []),
      messages: messages,
      isGroup: data['isGroup'] as bool? ?? false,
      avatar: data['avatar'] as String?,
      createdBy: data['createdBy'] as String,
      mutedBy: List<String>.from(data['mutedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastMessage: lastMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'participants': participants,
      'messages': messages.map((msg) => msg.toMap()).toList(),
      'isGroup': isGroup,
      'avatar': avatar,
      'createdBy': createdBy,
      'mutedBy': mutedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ChatModel copyWith({
    String? id,
    String? name,
    List<String>? participants,
    List<MessageModel>? messages,
    bool? isGroup,
    String? avatar,
    String? createdBy,
    List<String>? mutedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    MessageModel? lastMessage,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      participants: participants ?? this.participants,
      messages: messages ?? this.messages,
      isGroup: isGroup ?? this.isGroup,
      avatar: avatar ?? this.avatar,
      createdBy: createdBy ?? this.createdBy,
      mutedBy: mutedBy ?? this.mutedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
} 