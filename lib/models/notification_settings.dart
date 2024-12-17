import 'package:cloud_firestore/cloud_firestore.dart';

class ChatNotificationSettings {
  final bool isMuted;
  final DateTime? updatedAt;

  ChatNotificationSettings({
    required this.isMuted,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'isMuted': isMuted,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory ChatNotificationSettings.fromMap(Map<String, dynamic> map) {
    return ChatNotificationSettings(
      isMuted: map['isMuted'] ?? false,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
} 