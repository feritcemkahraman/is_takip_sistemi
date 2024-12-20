import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  static const String typeText = 'text';
  static const String typeImage = 'image';
  static const String typeFile = 'file';
  static const String typeVoice = 'voice';
  static const String typeVideo = 'video';

  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final List<String> readBy;
  final String? attachmentUrl;
  final String type;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    List<String>? readBy,
    this.attachmentUrl,
    this.type = typeText,
  }) : readBy = readBy ?? [];

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['timestamp'] ?? map['createdAt'] as Timestamp).toDate(),
      readBy: List<String>.from(map['readBy'] ?? []),
      attachmentUrl: map['attachmentUrl'],
      type: map['type'] ?? typeText,
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['timestamp'] ?? data['createdAt'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] ?? []),
      attachmentUrl: data['attachmentUrl'],
      type: data['type'] ?? typeText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(createdAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
      'attachmentUrl': attachmentUrl,
      'type': type,
    };
  }

  DateTime get timestamp => createdAt;
} 