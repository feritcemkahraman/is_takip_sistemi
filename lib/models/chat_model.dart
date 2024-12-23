import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final String name;
  final List<String> participants;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isGroup;
  final List<String> mutedBy;
  final List<MessageModel> messages;
  final MessageModel? lastMessage;
  final int unreadCount;
  final String? avatar;
  final List<String> deletedBy;

  ChatModel({
    required this.id,
    required this.name,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.isGroup,
    required this.mutedBy,
    required this.messages,
    this.lastMessage,
    this.unreadCount = 0,
    this.avatar,
    this.deletedBy = const [],
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Debug için veri tiplerini kontrol et
    print('Chat ID: ${doc.id}');
    print('lastMessage type: ${data['lastMessage']?.runtimeType}');
    if (data['lastMessage'] != null) {
      print('lastMessage content: ${data['lastMessage']}');
    }
    
    // Timestamp dönüşümlerini güvenli hale getir
    DateTime getDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is DateTime) {
        return value;
      }
      return DateTime.now(); // Varsayılan değer
    }

    try {
      // lastMessage alanını güvenli bir şekilde dönüştür
      MessageModel? lastMessage;
      final lastMessageData = data['lastMessage'];
      if (lastMessageData != null && lastMessageData is Map<String, dynamic>) {
        try {
          lastMessage = MessageModel.fromMap(lastMessageData, doc.id);
        } catch (e) {
          print('Error parsing lastMessage: $e');
          lastMessage = null;
        }
      }

      return ChatModel(
        id: doc.id,
        name: data['name'] as String? ?? '',
        participants: List<String>.from(data['participants'] as List? ?? []),
        createdBy: data['createdBy'] as String? ?? '',
        createdAt: getDateTime(data['createdAt']),
        updatedAt: getDateTime(data['updatedAt']),
        isGroup: data['isGroup'] as bool? ?? false,
        mutedBy: List<String>.from(data['mutedBy'] as List? ?? []),
        messages: (data['messages'] as List<dynamic>? ?? [])
            .map((msg) => MessageModel.fromMap(msg as Map<String, dynamic>, doc.id))
            .toList(),
        lastMessage: lastMessage,
        unreadCount: (data['unreadCount'] is int) ? data['unreadCount'] as int : 0,
        avatar: data['avatar'] as String?,
        deletedBy: List<String>.from(data['deletedBy'] as List? ?? []),
      );
    } catch (e, stackTrace) {
      print('Error in ChatModel.fromFirestore: $e');
      print('Stack trace: $stackTrace');
      print('Raw data: $data');
      
      // Hata durumunda varsayılan bir chat modeli döndür
      return ChatModel(
        id: doc.id,
        name: '',
        participants: [],
        createdBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isGroup: false,
        mutedBy: [],
        messages: [],
        unreadCount: 0,
        deletedBy: [],
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isGroup': isGroup,
      'mutedBy': mutedBy,
      'messages': messages.map((msg) => msg.toMap()).toList(),
      'lastMessage': lastMessage?.toMap(),
      'unreadCount': unreadCount,
      'avatar': avatar,
      'deletedBy': deletedBy,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isGroup': isGroup,
      'mutedBy': mutedBy,
      'messages': messages.map((m) => m.toMap()).toList(),
      'lastMessage': lastMessage?.toMap(),
      'unreadCount': unreadCount,
      'avatar': avatar,
      'deletedBy': deletedBy,
    };
  }

  ChatModel copyWith({
    String? id,
    String? name,
    List<String>? participants,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isGroup,
    List<String>? mutedBy,
    List<MessageModel>? messages,
    MessageModel? lastMessage,
    int? unreadCount,
    String? avatar,
    List<String>? deletedBy,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      participants: participants ?? this.participants,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isGroup: isGroup ?? this.isGroup,
      mutedBy: mutedBy ?? this.mutedBy,
      messages: messages ?? this.messages,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      avatar: avatar ?? this.avatar,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }

  int getUnreadCount(String userId) {
    if (lastMessage == null) return 0;
    if (lastMessage!.senderId == userId) return 0;
    if (lastMessage!.readBy.contains(userId)) return 0;
    return unreadCount;
  }

  String getChatName(String currentUserId) {
    if (isGroup) return name;
    
    // Birebir sohbetlerde diğer kullanıcının adını göster
    final otherParticipant = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return name.isEmpty ? otherParticipant : name;
  }
} 