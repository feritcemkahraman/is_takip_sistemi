import 'package:cloud_firestore/cloud_firestore.dart';

class MessageAttachment {
  final String id;
  final String name;
  final String url;
  final String type;
  final int size;
  final String? mimeType;
  final String? fileExtension;
  final DateTime createdAt;

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  MessageAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
    this.mimeType,
    this.fileExtension,
    required this.createdAt,
  });

  factory MessageAttachment.fromMap(Map<String, dynamic> map) {
    return MessageAttachment(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      type: map['type'] as String,
      size: map['size'] as int,
      mimeType: map['mimeType'] as String?,
      fileExtension: map['fileExtension'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'mimeType': mimeType,
      'fileExtension': fileExtension,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class MessageModel {
  static const String typeText = 'text';
  static const String typeImage = 'image';
  static const String typeVideo = 'video';
  static const String typeVoice = 'voice';
  static const String typeFile = 'file';

  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String type;
  final String? attachmentUrl;
  final DateTime createdAt;
  final List<String> readBy;
  final List<MessageAttachment> attachments;
  final bool isDeleted;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.readBy,
    this.attachmentUrl,
    this.type = typeText,
    this.attachments = const [],
    this.isDeleted = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      content: data['content'] as String,
      type: data['type'] as String? ?? typeText,
      attachmentUrl: data['attachmentUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readBy: List<String>.from(data['readBy'] as List? ?? []),
      attachments: (data['attachments'] as List<dynamic>? ?? [])
          .map((attachment) => MessageAttachment.fromMap(attachment as Map<String, dynamic>))
          .toList(),
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String chatId) {
    return MessageModel(
      id: map['id'] as String,
      chatId: chatId,
      senderId: map['senderId'] as String,
      content: map['content'] as String,
      type: map['type'] as String? ?? typeText,
      attachmentUrl: map['attachmentUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      readBy: List<String>.from(map['readBy'] as List? ?? []),
      attachments: (map['attachments'] as List<dynamic>? ?? [])
          .map((attachment) => MessageAttachment.fromMap(attachment as Map<String, dynamic>))
          .toList(),
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'attachmentUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
      'attachments': attachments.map((attachment) => attachment.toMap()).toList(),
      'isDeleted': isDeleted,
    };
  }

  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? type,
    String? attachmentUrl,
    DateTime? createdAt,
    List<String>? readBy,
    List<MessageAttachment>? attachments,
    bool? isDeleted,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      attachments: attachments ?? this.attachments,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
} 