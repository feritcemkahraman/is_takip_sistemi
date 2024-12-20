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
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Katılımcılara mevcut kullanıcıyı ekle
      final allParticipants = [...participants, currentUser.id];

      final now = DateTime.now();
      final chatRef = _firestore.collection(_collection).doc();

      final chat = ChatModel(
        id: chatRef.id,
        name: name,
        participants: allParticipants,
        messages: [], // Boş mesaj listesi
        isGroup: isGroup,
        createdBy: currentUser.id,
        mutedBy: [], // Başlangıçta kimse sessize almamış
        createdAt: now,
        updatedAt: now,
      );

      await chatRef.set(chat.toMap());
      return chat;
    } catch (e) {
      print('Sohbet oluşturma hatası: $e');
      throw Exception('Sohbet oluşturulamadı: $e');
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String content,
    String? attachmentUrl,
    String type = MessageModel.typeText,
  }) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    final chatRef = _firestore.collection(_collection).doc(chatId);
    final now = DateTime.now();

    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUser.id,
      content: content,
      createdAt: now,
      attachmentUrl: attachmentUrl,
      type: type,
      readBy: [currentUser.id],
    );

    await chatRef.update({
      'messages': FieldValue.arrayUnion([message.toMap()]),
      'updatedAt': now,
    });
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
        attachmentUrl: fileUrl,
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
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(_collection)
        .where('participants', arrayContains: currentUser.id)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    try {
      return _firestore
          .collection(_collection)
          .doc(chatId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return [];
            
            final chat = ChatModel.fromFirestore(doc);
            final messages = List<MessageModel>.from(chat.messages);
            
            // Mesajları tarihe göre sırala (en yeni en altta)
            messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            
            // Mesajları okundu olarak işaretle
            _markMessagesAsRead(chatId, messages);
            
            return messages;
          });
    } catch (e) {
      print('Mesajları getirirken hata: $e');
      return Stream.value([]);
    }
  }

  Future<void> _markMessagesAsRead(String chatId, List<MessageModel> messages) async {
    try {
      final currentUser = _userService.currentUser;
      if (currentUser == null) return;

      final batch = _firestore.batch();
      final unreadMessages = messages.where((msg) => 
        !msg.readBy.contains(currentUser.id) && 
        msg.senderId != currentUser.id
      );

      if (unreadMessages.isEmpty) return;

      final chatRef = _firestore.collection(_collection).doc(chatId);
      final chatDoc = await chatRef.get();
      
      if (!chatDoc.exists) return;

      final updatedMessages = messages.map((msg) {
        if (!msg.readBy.contains(currentUser.id) && msg.senderId != currentUser.id) {
          return {
            ...msg.toMap(),
            'readBy': [...msg.readBy, currentUser.id],
          };
        }
        return msg.toMap();
      }).toList();

      await chatRef.update({'messages': updatedMessages});
    } catch (e) {
      print('Mesajlar okundu olarak işaretlenirken hata: $e');
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
        .map((snapshot) {
          int totalUnread = 0;
          
          for (var doc in snapshot.docs) {
            final chat = ChatModel.fromFirestore(doc);
            final unreadMessages = chat.messages.where((msg) => 
              !msg.readBy.contains(currentUser.id) && 
              msg.senderId != currentUser.id
            );
            totalUnread += unreadMessages.length;
          }
          
          return totalUnread;
        });
  }

  Stream<int> getChatUnreadCount(String chatId) {
    final currentUser = _userService.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection(_collection)
        .doc(chatId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return 0;
          
          final chat = ChatModel.fromFirestore(doc);
          final unreadMessages = chat.messages.where((msg) => 
            !msg.readBy.contains(currentUser.id) && 
            msg.senderId != currentUser.id
          );
          
          return unreadMessages.length;
        });
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
    await _firestore.collection(_collection).doc(chatId).delete();
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
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatModel.fromFirestore(doc))
            .toList());
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

  Future<void> markMessageAsRead(String chatId, String messageId) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) return;

    final chatRef = _firestore.collection(_collection).doc(chatId);
    final chatDoc = await chatRef.get();
    
    if (!chatDoc.exists) return;
    
    final chat = ChatModel.fromFirestore(chatDoc);
    final messages = List<MessageModel>.from(chat.messages);
    
    final messageIndex = messages.indexWhere((m) => m.id == messageId);
    if (messageIndex == -1) return;
    
    final message = messages[messageIndex];
    if (message.readBy.contains(currentUser.id)) return;
    
    messages[messageIndex] = MessageModel(
      id: message.id,
      senderId: message.senderId,
      content: message.content,
      createdAt: message.createdAt,
      readBy: [...message.readBy, currentUser.id],
      attachmentUrl: message.attachmentUrl,
      type: message.type,
    );

    await chatRef.update({
      'messages': messages.map((m) => m.toMap()).toList(),
    });
  }
} 