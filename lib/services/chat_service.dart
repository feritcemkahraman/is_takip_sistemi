import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  // Sohbet oluşturma
  Future<ChatModel> createChat({
    required String type,
    required List<String> participants,
    String? name,
    String? description,
    String? avatar,
    required String createdBy,
  }) async {
    try {
      final chatId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Katılımcı isimlerini al
      final participantNames = <String, String>{};
      for (final userId in participants) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final user = UserModel.fromMap(userDoc.data()!);
          participantNames[userId] = user.name;
        }
      }

      final chat = ChatModel(
        id: chatId,
        type: type,
        participants: participants,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: name,
        description: description,
        avatar: avatar,
        createdBy: createdBy,
        participantNames: participantNames,
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toMap());

      // Sistem mesajı oluştur
      if (type == ChatModel.typeGroup) {
        await sendMessage(
          chatId: chatId,
          content: '${participantNames[createdBy]} grubu oluşturdu',
          type: MessageModel.typeSystem,
          senderId: createdBy,
        );
      }

      return chat;
    } catch (e) {
      print('Sohbet oluşturma hatası: $e');
      rethrow;
    }
  }

  // Özel sohbet oluşturma veya getirme
  Future<ChatModel> createOrGetPrivateChat({
    required String userId1,
    required String userId2,
  }) async {
    try {
      // Mevcut özel sohbeti ara
      final querySnapshot = await _firestore
          .collection('chats')
          .where('type', isEqualTo: ChatModel.typePrivate)
          .where('participants', arrayContainsAny: [userId1, userId2])
          .get();

      for (final doc in querySnapshot.docs) {
        final chat = ChatModel.fromMap(doc.data());
        if (chat.participants.contains(userId1) &&
            chat.participants.contains(userId2)) {
          return chat;
        }
      }

      // Mevcut sohbet yoksa yeni oluştur
      return createChat(
        type: ChatModel.typePrivate,
        participants: [userId1, userId2],
        createdBy: userId1,
      );
    } catch (e) {
      print('Özel sohbet oluşturma/getirme hatası: $e');
      rethrow;
    }
  }

  // Mesaj gönderme
  Future<MessageModel> sendMessage({
    required String chatId,
    required String content,
    required String type,
    required String senderId,
    List<MessageAttachment>? attachments,
    String? replyTo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: type,
        attachments: attachments,
        createdAt: DateTime.now(),
        replyTo: replyTo,
        metadata: metadata,
      );

      final batch = _firestore.batch();

      // Mesajı kaydet
      batch.set(
        _firestore.collection('chats/$chatId/messages').doc(messageId),
        message.toMap(),
      );

      // Son mesajı güncelle
      batch.update(
        _firestore.collection('chats').doc(chatId),
        {
          'lastMessage': message.toMap(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      await batch.commit();

      // Sohbet katılımcılarına bildirim gönder
      final chat = await getChat(chatId);
      if (chat != null) {
        for (final userId in chat.getOtherParticipants(senderId)) {
          await _notificationService.createNotification(
            title: chat.getChatName(userId),
            body: _getMessagePreview(message),
            userId: userId,
            type: 'chat_message',
            data: {
              'chatId': chatId,
              'messageId': messageId,
            },
          );
        }
      }

      return message;
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      rethrow;
    }
  }

  // Dosya mesajı gönderme
  Future<MessageModel> sendFileMessage({
    required String chatId,
    required String senderId,
    required String filePath,
    required String fileName,
    required String type,
    String? replyTo,
  }) async {
    try {
      // Dosyayı yükle
      final url = await _storageService.uploadFile(
        filePath,
        'chats/$chatId/files/$fileName',
      );

      final attachment = MessageAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        url: url,
        name: fileName,
        size: await File(filePath).length(),
      );

      return sendMessage(
        chatId: chatId,
        content: fileName,
        type: type,
        senderId: senderId,
        attachments: [attachment],
        replyTo: replyTo,
      );
    } catch (e) {
      print('Dosya mesajı gönderme hatası: $e');
      rethrow;
    }
  }

  // Mesaj okundu olarak işaretleme
  Future<void> markMessageAsRead(String chatId, String messageId, String userId) async {
    try {
      await _firestore
          .collection('chats/$chatId/messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Mesaj okundu işaretleme hatası: $e');
      rethrow;
    }
  }

  // Mesaj silme
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats/$chatId/messages')
          .doc(messageId)
          .update({
        'isDeleted': true,
      });
    } catch (e) {
      print('Mesaj silme hatası: $e');
      rethrow;
    }
  }

  // Sohbet getirme
  Future<ChatModel?> getChat(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;
      return ChatModel.fromMap(doc.data()!);
    } catch (e) {
      print('Sohbet getirme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcının sohbetlerini getirme
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatModel.fromMap(doc.data())).toList());
  }

  // Sohbet mesajlarını getirme
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats/$chatId/messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList());
  }

  // Sohbetten çıkma
  Future<void> leaveChat(String chatId, String userId) async {
    try {
      final chat = await getChat(chatId);
      if (chat == null) return;

      if (chat.isPrivateChat) {
        throw Exception('Özel sohbetten çıkamazsınız');
      }

      final batch = _firestore.batch();

      // Katılımcılardan çıkar
      batch.update(
        _firestore.collection('chats').doc(chatId),
        {
          'participants': FieldValue.arrayRemove([userId]),
        },
      );

      // Sistem mesajı ekle
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      batch.set(
        _firestore.collection('chats/$chatId/messages').doc(messageId),
        MessageModel(
          id: messageId,
          chatId: chatId,
          senderId: userId,
          content: '${chat.participantNames[userId]} gruptan ayrıldı',
          type: MessageModel.typeSystem,
          createdAt: DateTime.now(),
        ).toMap(),
      );

      await batch.commit();
    } catch (e) {
      print('Sohbetten çıkma hatası: $e');
      rethrow;
    }
  }

  // Sohbete katılımcı ekleme
  Future<void> addParticipants(
    String chatId,
    List<String> userIds,
    String addedBy,
  ) async {
    try {
      final chat = await getChat(chatId);
      if (chat == null) return;

      if (chat.isPrivateChat) {
        throw Exception('Özel sohbete katılımcı ekleyemezsiniz');
      }

      // Yeni katılımcıların isimlerini al
      final newParticipantNames = <String, String>{};
      for (final userId in userIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final user = UserModel.fromMap(userDoc.data()!);
          newParticipantNames[userId] = user.name;
        }
      }

      final batch = _firestore.batch();

      // Katılımcıları ekle
      batch.update(
        _firestore.collection('chats').doc(chatId),
        {
          'participants': FieldValue.arrayUnion(userIds),
          'participantNames': {...chat.participantNames, ...newParticipantNames},
        },
      );

      // Sistem mesajı ekle
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final addedNames = userIds.map((id) => newParticipantNames[id]).join(', ');
      batch.set(
        _firestore.collection('chats/$chatId/messages').doc(messageId),
        MessageModel(
          id: messageId,
          chatId: chatId,
          senderId: addedBy,
          content:
              '${chat.participantNames[addedBy]} şu kişileri ekledi: $addedNames',
          type: MessageModel.typeSystem,
          createdAt: DateTime.now(),
        ).toMap(),
      );

      await batch.commit();
    } catch (e) {
      print('Katılımcı ekleme hatası: $e');
      rethrow;
    }
  }

  // Sohbetten katılımcı çıkarma
  Future<void> removeParticipant(
    String chatId,
    String userId,
    String removedBy,
  ) async {
    try {
      final chat = await getChat(chatId);
      if (chat == null) return;

      if (chat.isPrivateChat) {
        throw Exception('Özel sohbetten katılımcı çıkaramazsınız');
      }

      final batch = _firestore.batch();

      // Katılımcıyı çıkar
      batch.update(
        _firestore.collection('chats').doc(chatId),
        {
          'participants': FieldValue.arrayRemove([userId]),
        },
      );

      // Sistem mesajı ekle
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      batch.set(
        _firestore.collection('chats/$chatId/messages').doc(messageId),
        MessageModel(
          id: messageId,
          chatId: chatId,
          senderId: removedBy,
          content:
              '${chat.participantNames[removedBy]} şu kişiyi çıkardı: ${chat.participantNames[userId]}',
          type: MessageModel.typeSystem,
          createdAt: DateTime.now(),
        ).toMap(),
      );

      await batch.commit();
    } catch (e) {
      print('Katılımcı çıkarma hatası: $e');
      rethrow;
    }
  }

  // Yardımcı metodlar
  String _getMessagePreview(MessageModel message) {
    if (message.isDeleted) return 'Bu mesaj silindi';
    if (message.isSystemMessage) return message.content;

    switch (message.type) {
      case MessageModel.typeText:
        return message.content;
      case MessageModel.typeImage:
        return '📷 Fotoğraf';
      case MessageModel.typeFile:
        return '📎 Dosya: ${message.content}';
      case MessageModel.typeVoice:
        return '🎤 Sesli mesaj';
      case MessageModel.typeVideo:
        return '🎥 Video';
      default:
        return message.content;
    }
  }
} 