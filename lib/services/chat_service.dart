import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final UserService _userService;
  final String _collection = 'chats';
  final String _messagesCollection = 'messages';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChatService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required UserService userService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _userService = userService;

  Future<UserModel?> getCurrentUser() async {
    return _userService.currentUser;
  }

  Future<ChatModel> createChat({
    required String name,
    required List<String> participants,
    bool isGroup = false,
  }) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    // Grup sohbeti değilse ve sadece bir katılımcı varsa, mevcut sohbeti kontrol et
    if (!isGroup && participants.length == 1) {
      final existingChat = await findExistingChat(participants.first);
      if (existingChat != null) {
        return existingChat;
      }
    }

    // Yeni sohbet oluştur
    final chatRef = _firestore.collection(_collection).doc();
    final now = DateTime.now();
    
    final chatData = {
      'id': chatRef.id,
      'name': name,
      'participants': [...participants, currentUser.id],
      'createdBy': currentUser.id,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'isGroup': isGroup,
      'mutedBy': [],
      'messages': [],
      'lastMessage': null,
      'unreadCount': 0,
      'avatar': null,
      'deletedBy': [],
    };

    // Sohbeti kaydet
    await chatRef.set(chatData);

    // ChatModel oluştur ve döndür
    return ChatModel(
      id: chatRef.id,
      name: name,
      participants: [...participants, currentUser.id],
      createdBy: currentUser.id,
      createdAt: now,
      updatedAt: now,
      isGroup: isGroup,
      mutedBy: [],
      messages: [],
      lastMessage: null,
      unreadCount: 0,
      avatar: null,
      deletedBy: const [],
    );
  }

  Future<ChatModel?> findExistingChat(String participantId) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return null;

    final querySnapshot = await _firestore
        .collection(_collection)
        .where('participants', arrayContains: currentUser.id)
        .where('isGroup', isEqualTo: false)
        .get();

    for (final doc in querySnapshot.docs) {
      final chat = ChatModel.fromFirestore(doc);
      if (chat.participants.contains(participantId)) {
        return chat;
      }
    }

    return null;
  }

  Future<void> sendMessage({
    required String chatId,
    required String content,
    String? attachmentUrl,
    String type = MessageModel.typeText,
  }) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    final batch = _firestore.batch();

    // Sohbeti al ve katılımcıları kontrol et
    final chatDoc = await _firestore.collection(_collection).doc(chatId).get();
    if (!chatDoc.exists) return;

    final chatData = chatDoc.data() as Map<String, dynamic>;
    List<String> participants = List<String>.from(chatData['participants'] as List);
    List<String> deletedBy = List<String>.from(chatData['deletedBy'] ?? []);
    
    // Eğer gönderen kullanıcı katılımcılar listesinde yoksa veya daha önce sohbeti silmişse
    if (!participants.contains(currentUser.id) || deletedBy.contains(currentUser.id)) {
      participants.add(currentUser.id);
      deletedBy.remove(currentUser.id);
      batch.update(_firestore.collection(_collection).doc(chatId), {
        'participants': participants,
        'deletedBy': deletedBy,
      });
    }

    final now = DateTime.now();
    final messageRef = _firestore
        .collection(_collection)
        .doc(chatId)
        .collection(_messagesCollection)
        .doc();
    
    // Yeni mesaj oluştur
    final message = MessageModel(
      id: messageRef.id,
      chatId: chatId,
      senderId: currentUser.id,
      content: type == MessageModel.typeImage ? 'Fotoğraf' : content,
      createdAt: now,
      readBy: [currentUser.id],
      type: type,
      attachmentUrl: attachmentUrl,
    );

    // Mesajı kaydet
    batch.set(messageRef, message.toFirestore());

    // Chat belgesini güncelle
    final lastMessageMap = {
      'id': message.id,
      'chatId': chatId,
      'senderId': message.senderId,
      'content': message.content,
      'type': message.type,
      'attachmentUrl': message.attachmentUrl,
      'createdAt': Timestamp.fromDate(message.createdAt),
      'readBy': message.readBy,
      'attachments': message.attachments.map((a) => a.toMap()).toList(),
      'isDeleted': message.isDeleted,
    };

    batch.update(_firestore.collection(_collection).doc(chatId), {
      'lastMessage': lastMessageMap,
      'updatedAt': Timestamp.fromDate(now),
      'unreadCount': FieldValue.increment(participants.length - 1),
    });

    // Batch'i commit et
    await batch.commit();

    // Bildirim gönder
    for (final participantId in participants) {
      if (participantId != currentUser.id) {
        final otherUser = await _userService.getUserById(participantId);
        if (otherUser?.fcmToken != null) {
          final notificationService = NotificationService();
          await notificationService.sendNotification(
            token: otherUser!.fcmToken!,
            title: chatData['isGroup'] == true 
                ? '${chatData['name']}: ${currentUser.name}\'den yeni mesaj'
                : '${currentUser.name}\'den yeni mesaj',
            body: type == MessageModel.typeText ? content : 'Dosya gönderildi',
            data: {
              'type': 'message',
              'chatId': chatId,
              'senderId': currentUser.id,
            },
          );
        }
      }
    }

    notifyListeners();
  }

  Future<void> updateUnreadCount(String chatId) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    // Okunmamış mesajları say
    final messagesSnapshot = await _firestore
        .collection(_collection)
        .doc(chatId)
        .collection(_messagesCollection)
        .where('readBy', arrayContains: currentUser.id, isEqualTo: false)
        .get();

    // Sohbetin okunmamış mesaj sayısını güncelle
    await _firestore.collection(_collection).doc(chatId).update({
      'unreadCount': messagesSnapshot.docs.length,
    });
  }

  Future<void> resetUnreadCount(String chatId) async {
    await _firestore.collection(_collection).doc(chatId).update({
      'unreadCount': 0,
    });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return Stream.value([]);

    // Mesajları dinle
    final messagesStream = _firestore
        .collection(_collection)
        .doc(chatId)
        .collection(_messagesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();

    // Chat belgesini dinle
    final chatStream = _firestore
        .collection(_collection)
        .doc(chatId)
        .snapshots();

    // İki stream'i birleştir
    return messagesStream.asyncMap((messagesSnapshot) async {
      // Chat belgesini al
      final chatDoc = await chatStream.first;
      if (!chatDoc.exists) return [];

      final messages = messagesSnapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();

      if (messages.isNotEmpty) {
        final batch = _firestore.batch();
        bool needsBatchCommit = false;

        for (final doc in messagesSnapshot.docs) {
          final data = doc.data();
          final List<dynamic> readBy = List<dynamic>.from(data['readBy'] ?? []);
          final String senderId = data['senderId'] as String;
          
          // Sadece başkasının gönderdiği ve henüz okunmamış mesajları işaretle
          if (senderId != currentUser.id && !readBy.contains(currentUser.id)) {
            batch.update(doc.reference, {
              'readBy': FieldValue.arrayUnion([currentUser.id])
            });
            needsBatchCommit = true;
          }
        }

        if (needsBatchCommit) {
          await batch.commit();
          // Chat belgesini güncelle
          await _firestore.collection(_collection).doc(chatId).update({
            'unreadCount': 0
          });
        }
      }

      return messages;
    });
  }

  Stream<List<ChatModel>> getChatList() {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('participants', arrayContains: currentUser.id)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<ChatModel>> getUserChats() {
    return getChatList();
  }

  Future<void> deleteChat(String chatId) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    try {
      // Sohbeti al
      final chatDoc = await _firestore.collection(_collection).doc(chatId).get();
      if (!chatDoc.exists) throw Exception('Sohbet bulunamadı');

      final chatData = chatDoc.data() as Map<String, dynamic>;
      List<String> participants = List<String>.from(chatData['participants'] as List);
      List<String> deletedBy = List<String>.from(chatData['deletedBy'] ?? []);

      // Kullanıcıyı katılımcılardan çıkar ve deletedBy listesine ekle
      participants.remove(currentUser.id);
      if (!deletedBy.contains(currentUser.id)) {
        deletedBy.add(currentUser.id);
      }

      // Sohbeti güncelle
      await _firestore.collection(_collection).doc(chatId).update({
        'participants': participants,
        'deletedBy': deletedBy,
      });
      
      notifyListeners();
    } catch (e) {
      print('Error deleting chat: $e');
      throw Exception('Sohbet silinirken bir hata oluştu');
    }
  }

  Future<void> markAllMessagesAsRead(String chatId) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    final messagesSnapshot = await _firestore
        .collection(_collection)
        .doc(chatId)
        .collection(_messagesCollection)
        .where('readBy', arrayContains: currentUser.id)
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {
        'readBy': FieldValue.arrayUnion([currentUser.id])
      });
    }
    await batch.commit();
  }

  Future<void> toggleMuteChat(String chatId) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    final chatDoc = await _firestore.collection(_collection).doc(chatId).get();
    final chatData = chatDoc.data() as Map<String, dynamic>;
    final mutedBy = List<String>.from(chatData['mutedBy'] ?? []);

    if (mutedBy.contains(currentUser.id)) {
      mutedBy.remove(currentUser.id);
    } else {
      mutedBy.add(currentUser.id);
    }

    await _firestore.collection(_collection).doc(chatId).update({
      'mutedBy': mutedBy
    });
    notifyListeners();
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return getMessages(chatId);
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection(_collection)
        .doc(chatId)
        .collection(_messagesCollection)
        .doc(messageId)
        .delete();
    notifyListeners();
  }

  Future<void> muteChatNotifications(String chatId) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    final chatRef = _firestore.collection(_collection).doc(chatId);
    
    await chatRef.update({
      'mutedBy': FieldValue.arrayUnion([currentUser.id])
    });
    
    notifyListeners();
  }

  Future<void> unmuteChatNotifications(String chatId) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    final chatRef = _firestore.collection(_collection).doc(chatId);
    
    await chatRef.update({
      'mutedBy': FieldValue.arrayRemove([currentUser.id])
    });
    
    notifyListeners();
  }

  Future<List<DocumentSnapshot>> getUnreadMessages(String chatId, String userId) async {
    final messagesSnapshot = await _firestore
        .collection(_collection)
        .doc(chatId)
        .collection(_messagesCollection)
        .where('readBy', arrayContains: userId, isEqualTo: false)
        .get();

    return messagesSnapshot.docs;
  }
} 