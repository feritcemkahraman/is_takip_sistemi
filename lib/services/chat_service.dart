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

      print('Creating chat with isGroup: $isGroup');

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
            return ChatModel.fromMap({...doc.data(), 'id': doc.id}, userService: _userService);
          }
        }
      }

      final now = DateTime.now();
      final chatData = {
        'name': name,
        'participants': [...participants, currentUser.id],
        'createdBy': currentUser.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTime': null,
        'isGroup': isGroup,
        'unreadCount': 0,
      };

      print('Creating chat with data: $chatData');

      final docRef = await _firestore.collection(_collection).add(chatData);
      
      return ChatModel(
        id: docRef.id,
        name: name,
        participants: [...participants, currentUser.id],
        createdBy: currentUser.id,
        createdAt: now,
        updatedAt: now,
        lastMessage: null,
        lastMessageTime: null,
        isGroup: isGroup,
        unreadCount: 0,
        userService: _userService,
      );
    } catch (e) {
      print('Sohbet oluşturma hatası: $e');
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String content,
    String? attachment,
  }) async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      final now = DateTime.now();
      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: currentUser.id,
        content: content,
        attachment: attachment,
        createdAt: now,
        type: attachment != null ? 'file' : 'text',
      );

      await _firestore
          .collection(_collection)
          .doc(chatId)
          .collection(_messagesCollection)
          .add(message.toMap());

      await _firestore.collection(_collection).doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': now,
        'updatedAt': now,
      });
    } catch (e) {
      throw Exception('Mesaj gönderilemedi: $e');
    }
  }

  Future<void> sendFileMessage({
    required String chatId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      // Dosyayı yükle ve URL'sini al
      final fileUrl = await _uploadFile(filePath, fileName);

      // Mesajı gönder
      await sendMessage(
        chatId: chatId,
        content: fileName,
        attachment: fileUrl,
      );
    } catch (e) {
      throw Exception('Dosya gönderilemedi: $e');
    }
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Mesaj silinemedi: $e');
    }
  }

  Future<String> _uploadFile(String filePath, String fileName) async {
    try {
      // Benzersiz bir dosya adı oluştur
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      
      // Storage referansını oluştur
      final ref = _storage.ref().child('chat_files').child(uniqueFileName);
      
      // Dosyayı yükle
      final file = File(filePath);
      final uploadTask = await ref.putFile(file);
      
      if (uploadTask.state == TaskState.success) {
        // Dosya URL'sini al
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('Dosya yükleme başarısız oldu');
      }
    } catch (e) {
      print('Dosya yükleme hatası: $e');
      throw Exception('Dosya yüklenemedi: $e');
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
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromMap({...doc.data(), 'id': doc.id}, userService: _userService))
            .toList());
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    try {
      return _firestore
          .collection(_collection)
          .doc(chatId)
          .collection(_messagesCollection)
          .snapshots()
          .map((snapshot) {
            final messages = snapshot.docs
                .map((doc) => MessageModel.fromFirestore(doc))
                .toList();
            
            // Mesajları createdAt'e göre sırala
            messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            
            return messages;
          });
    } catch (e) {
      print('Mesajları getirirken hata: $e');
      return Stream.value([]);
    }
  }

  Stream<List<UserModel>> getChatParticipants(String chatId) {
    try {
      if (chatId.isEmpty) {
        print('Chat ID boş olamaz');
        return Stream.value([]);
      }

      return _firestore
          .collection(_collection)
          .doc(chatId)
          .snapshots()
          .asyncMap((chatDoc) async {
            if (!chatDoc.exists) {
              print('Sohbet bulunamadı: $chatId');
              return [];
            }
            
            final data = chatDoc.data();
            if (data == null) {
              print('Sohbet verisi boş: $chatId');
              return [];
            }

            final participants = List<String>.from(data['participants'] ?? []);
            if (participants.isEmpty) {
              print('Katılımcı listesi boş: $chatId');
              return [];
            }

            try {
              final userModels = await Future.wait(
                participants.map((userId) async {
                  final user = await _userService.getUserById(userId);
                  return user;
                })
              );
              
              return userModels.whereType<UserModel>().toList();
            } catch (e) {
              print('Katılımcı bilgileri alınırken hata: $e');
              return [];
            }
          });
    } catch (e) {
      print('getChatParticipants hatası: $e');
      return Stream.value([]);
    }
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
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatModel.fromMap({
          'id': doc.id,
          ...data,
        }, userService: _userService);
      }).toList();
    });
  }

  Future<void> toggleMuteChat(String chatId) async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final chatDoc = await _firestore.collection(_collection).doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Sohbet bulunamadı');
      }

      final chatData = chatDoc.data()!;
      final mutedBy = List<String>.from(chatData['mutedBy'] ?? []);

      if (mutedBy.contains(currentUser.id)) {
        // Sessize alınmışsa, sessize almayı kaldır
        mutedBy.remove(currentUser.id);
      } else {
        // Sessize alınmamışsa, sessize al
        mutedBy.add(currentUser.id);
      }

      await _firestore.collection(_collection).doc(chatId).update({
        'mutedBy': mutedBy,
      });
    } catch (e) {
      print('Sohbet sessize alma hatası: $e');
      rethrow;
    }
  }
} 