import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final UserService _userService;
  final String _collection = 'chats';
  final String _messagesCollection = 'messages';

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
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) {
        throw Exception('Oturum açmış kullanıcı bulunamadı');
      }

      // Eğer birebir sohbet ise ve zaten varsa, mevcut sohbeti döndür
      if (!isGroup && participants.length == 1) {
        final existingChat = await _firestore
            .collection(_collection)
            .where('participants', arrayContains: currentUser.id)
            .where('isGroup', isEqualTo: false)
            .get();

        for (var doc in existingChat.docs) {
          final chatParticipants = List<String>.from(doc.data()['participants']);
          if (chatParticipants.length == 2 &&
              chatParticipants.contains(participants[0])) {
            return ChatModel.fromMap({...doc.data(), 'id': doc.id});
          }
        }
      }

      final chatData = {
        'name': name,
        'participants': [...participants, currentUser.id],
        'createdBy': currentUser.id,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTime': null,
        'isGroup': isGroup,
        'unreadCount': 0,
      };

      final docRef = await _firestore.collection(_collection).add(chatData);
      
      return ChatModel(
        id: docRef.id,
        name: name,
        participants: [...participants, currentUser.id],
        createdBy: currentUser.id,
        createdAt: DateTime.now(),
        lastMessage: null,
        lastMessageTime: null,
        isGroup: isGroup,
        unreadCount: 0,
      );
    } catch (e) {
      print('Sohbet oluşturma hatası: $e');
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String content,
    File? attachment,
  }) async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) {
        throw Exception('Oturum açmış kullanıcı bulunamadı');
      }

      String? attachmentUrl;
      if (attachment != null) {
        final ref = _storage.ref().child('chat_attachments/${DateTime.now().millisecondsSinceEpoch}_${attachment.path.split('/').last}');
        await ref.putFile(attachment);
        attachmentUrl = await ref.getDownloadURL();
      }

      final messageData = {
        'content': content,
        'senderId': currentUser.id,
        'timestamp': FieldValue.serverTimestamp(),
        'attachment': attachmentUrl,
        'isRead': false,
        'type': attachment != null ? 'file' : 'text',
      };

      await _firestore
          .collection(_collection)
          .doc(chatId)
          .collection(_messagesCollection)
          .add(messageData);

      await _firestore.collection(_collection).doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      rethrow;
    }
  }

  Stream<List<ChatModel>> getUserChats() {
    final currentUser = _userService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('participants', arrayContains: currentUser.id)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection(_collection)
        .doc(chatId)
        .collection(_messagesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> deleteChat(String chatId) async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) {
        throw Exception('Oturum açmış kullanıcı bulunamadı');
      }

      // Sohbetin var olduğunu ve kullanıcının yetkisi olduğunu kontrol et
      final chatDoc = await _firestore.collection(_collection).doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Sohbet bulunamadı');
      }

      final chatData = chatDoc.data()!;
      if (!chatData['participants'].contains(currentUser.id)) {
        throw Exception('Bu sohbeti silme yetkiniz yok');
      }

      // Önce tüm mesajları sil
      final messagesSnapshot = await _firestore
          .collection(_collection)
          .doc(chatId)
          .collection(_messagesCollection)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection(_collection).doc(chatId));
      
      await batch.commit();
    } catch (e) {
      print('Sohbet silme hatası: $e');
      rethrow;
    }
  }

  Future<void> leaveChat(String chatId) async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) {
        throw Exception('Oturum açmış kullanıcı bulunamadı');
      }

      final chatDoc = await _firestore.collection(_collection).doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Sohbet bulunamadı');
      }

      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants']);
      
      if (!participants.contains(currentUser.id)) {
        throw Exception('Bu sohbette zaten bulunmuyorsunuz');
      }

      participants.remove(currentUser.id);
      
      if (participants.isEmpty) {
        await deleteChat(chatId);
      } else {
        await _firestore.collection(_collection).doc(chatId).update({
          'participants': participants,
        });
      }
    } catch (e) {
      print('Sohbetten ayrılma hatası: $e');
      rethrow;
    }
  }

  Stream<int> getUnreadMessagesCount() {
    final currentUser = _userService.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_collection)
        .where('participants', arrayContains: currentUser.id)
        .snapshots()
        .asyncMap((chatSnapshot) async {
      int totalUnread = 0;

      for (var chatDoc in chatSnapshot.docs) {
        final unreadCount = await _firestore
            .collection(_collection)
            .doc(chatDoc.id)
            .collection(_messagesCollection)
            .where('isRead', isEqualTo: false)
            .where('senderId', isNotEqualTo: currentUser.id)
            .count()
            .get();

        totalUnread += unreadCount.count ?? 0;
      }

      return totalUnread;
    });
  }

  Future<void> markAllMessagesAsRead(String chatId) async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) return;

      final batch = _firestore.batch();
      final messages = await _firestore
          .collection(_collection)
          .doc(chatId)
          .collection(_messagesCollection)
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUser.id)
          .get();

      for (var message in messages.docs) {
        batch.update(message.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Tüm mesajlar okundu olarak işaretlenirken hata: $e');
      rethrow;
    }
  }

  Stream<List<ChatModel>> getChats() {
    final currentUser = _userService.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_collection)
        .where('participants', arrayContains: currentUser.id)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ChatModel> chats = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final otherParticipants = List<String>.from(data['participants'])
            .where((id) => id != currentUser.id)
            .toList();

        final unreadCount = await _firestore
            .collection(_collection)
            .doc(doc.id)
            .collection(_messagesCollection)
            .where('isRead', isEqualTo: false)
            .where('senderId', isNotEqualTo: currentUser.id)
            .count()
            .get();

        chats.add(ChatModel(
          id: doc.id,
          name: data['name'] ?? '',
          participants: List<String>.from(data['participants']),
          lastMessage: data['lastMessage'],
          lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
          unreadCount: unreadCount.count ?? 0,
          isGroup: data['isGroup'] ?? false,
          createdBy: data['createdBy'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }

      return chats;
    });
  }
} 