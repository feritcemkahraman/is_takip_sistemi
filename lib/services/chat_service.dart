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
    
    // Eğer gönderen kullanıcı katılımcılar listesinde yoksa, ekle
    if (!participants.contains(currentUser.id)) {
      participants.add(currentUser.id);
      batch.update(_firestore.collection(_collection).doc(chatId), {
        'participants': participants,
      });
    }

    // Yeni mesaj referansı oluştur
    final messageRef = _firestore
        .collection(_collection)
        .doc(chatId)
        .collection(_messagesCollection)
        .doc();

    final now = DateTime.now();
    final message = MessageModel(
      id: messageRef.id,
      chatId: chatId,
      senderId: currentUser.id,
      content: content,
      createdAt: now,
      readBy: [currentUser.id],
      attachmentUrl: attachmentUrl,
      type: type,
    );

    // Mesajı batch'e ekle
    batch.set(messageRef, message.toFirestore());
    
    // Okunmamış mesaj sayısını güncelle
    final currentUnreadCount = chatData['unreadCount'] as int? ?? 0;
    final newUnreadCount = currentUnreadCount + (participants.length - 1); // Gönderen hariç

    // Sohbetin son mesajını ve okunmamış mesaj sayısını güncelle
    batch.update(_firestore.collection(_collection).doc(chatId), {
      'lastMessage': message.toMap(),
      'updatedAt': Timestamp.fromDate(now),
      'unreadCount': newUnreadCount,
    });

    // Batch'i commit et
    await batch.commit();

    // Bildirim gönderilecek kullanıcıları bul (gönderen hariç)
    final otherParticipants = participants.where((id) => id != currentUser.id);

    // Her bir kullanıcıya bildirim gönder
    for (final userId in otherParticipants) {
      final otherUser = await _userService.getUserById(userId);
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

    // Değişiklikleri bildir
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

    // Sohbete girildiğinde okunmamış mesaj sayısını sıfırla
    resetUnreadCount(chatId);

    return _firestore
        .collection(_collection)
        .doc(chatId)
        .collection(_messagesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();

          // Mesajları işaretleyelim
          final batch = _firestore.batch();
          bool needsBatchCommit = false;

          for (final doc in snapshot.docs) {
            if (!doc.data()['readBy'].contains(currentUser.id)) {
              batch.update(doc.reference, {
                'readBy': FieldValue.arrayUnion([currentUser.id])
              });
              needsBatchCommit = true;
            }
          }

          // Eğer okunmamış mesaj varsa batch'i commit edelim
          if (needsBatchCommit) {
            batch.commit().then((_) {
              // Batch işlemi tamamlandığında bildirim yap
              notifyListeners();
            });
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

      // Kullanıcıyı katılımcılardan çıkar
      participants.remove(currentUser.id);

      if (participants.isEmpty) {
        // Eğer başka katılımcı kalmadıysa sohbeti tamamen sil
        final messagesSnapshot = await _firestore
            .collection(_collection)
            .doc(chatId)
            .collection(_messagesCollection)
            .get();

        final batch = _firestore.batch();
        
        // Mesajları batch'e ekle
        for (var doc in messagesSnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Sohbeti batch'e ekle
        batch.delete(_firestore.collection(_collection).doc(chatId));

        // Batch'i commit et
        await batch.commit();
      } else {
        // Sadece kullanıcıyı katılımcılardan çıkar
        await _firestore.collection(_collection).doc(chatId).update({
          'participants': participants,
        });
      }
      
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
} 