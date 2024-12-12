import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String type;
  final List<MessageAttachment> attachments;
  final List<String> readBy;
  final DateTime createdAt;
  final bool isDeleted;
  final String? replyTo;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    List<MessageAttachment>? attachments,
    List<String>? readBy,
    required this.createdAt,
    this.isDeleted = false,
    this.replyTo,
    this.metadata,
  })  : this.attachments = attachments ?? [],
        this.readBy = readBy ?? [];

  // Mesaj tipleri
  static const String typeText = 'text';
  static const String typeImage = 'image';
  static const String typeFile = 'file';
  static const String typeVoice = 'voice';
  static const String typeVideo = 'video';
  static const String typeSystem = 'system';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'readBy': readBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDeleted': isDeleted,
      'replyTo': replyTo,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      content: map['content'] as String,
      type: map['type'] as String,
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((a) => MessageAttachment.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      readBy: List<String>.from(map['readBy'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isDeleted: map['isDeleted'] as bool? ?? false,
      replyTo: map['replyTo'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    String? type,
    List<MessageAttachment>? attachments,
    List<String>? readBy,
    DateTime? createdAt,
    bool? isDeleted,
    String? replyTo,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      attachments: attachments ?? List.from(this.attachments),
      readBy: readBy ?? List.from(this.readBy),
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      replyTo: replyTo ?? this.replyTo,
      metadata: metadata ?? (this.metadata != null ? Map.from(this.metadata!) : null),
    );
  }

  // Yardımcı metodlar
  bool get isTextMessage => type == typeText;
  bool get isImageMessage => type == typeImage;
  bool get isFileMessage => type == typeFile;
  bool get isVoiceMessage => type == typeVoice;
  bool get isVideoMessage => type == typeVideo;
  bool get isSystemMessage => type == typeSystem;

  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  bool get hasAttachments => attachments.isNotEmpty;
  bool get isReply => replyTo != null;
}

class MessageAttachment {
  final String id;
  final String type;
  final String url;
  final String name;
  final int size;
  final String? mimeType;
  final Map<String, dynamic>? metadata;

  MessageAttachment({
    required this.id,
    required this.type,
    required this.url,
    required this.name,
    required this.size,
    this.mimeType,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'name': name,
      'size': size,
      'mimeType': mimeType,
      'metadata': metadata,
    };
  }

  factory MessageAttachment.fromMap(Map<String, dynamic> map) {
    return MessageAttachment(
      id: map['id'] as String,
      type: map['type'] as String,
      url: map['url'] as String,
      name: map['name'] as String,
      size: map['size'] as int,
      mimeType: map['mimeType'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  MessageAttachment copyWith({
    String? id,
    String? type,
    String? url,
    String? name,
    int? size,
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) {
    return MessageAttachment(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      name: name ?? this.name,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      metadata: metadata ?? (this.metadata != null ? Map.from(this.metadata!) : null),
    );
  }

  // Yardımcı metodlar
  String get fileExtension => name.split('.').last;
  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isAudio => type == 'audio';
  bool get isDocument => !isImage && !isVideo && !isAudio;

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
} 