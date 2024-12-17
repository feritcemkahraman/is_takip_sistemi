import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<UserModel> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return UserModel.fromMap(doc.data()!..['id'] = doc.id);
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()..['id'] = doc.id))
            .toList());
  }

  Future<void> sendMessage(String chatId, String content, String type) async {
    final user = await getCurrentUser();
    final message = MessageModel(
      id: '',
      chatId: chatId,
      senderId: user.id,
      content: content,
      type: type,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': content,
      'lastMessageTime': DateTime.now().toIso8601String(),
      'lastMessageSenderId': user.id,
    });
  }

  Future<void> sendFileMessage(String chatId, String filePath, String type) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = _storage.ref().child('chat_files/$chatId/$fileName');
    await ref.putFile(File(filePath));
    final url = await ref.getDownloadURL();
    await sendMessage(chatId, url, type);
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<ChatModel> getChat(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    return ChatModel.fromMap(doc.data()!..['id'] = doc.id);
  }

  Future<List<MessageModel>> getChatMediaMessages(String chatId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('type', whereIn: ['image', 'video', 'file'])
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  Future<Map<String, dynamic>> getChatSettings(String chatId) async {
    final doc = await _firestore.collection('chat_settings').doc(chatId).get();
    return doc.data() ?? {};
  }

  Future<void> updateChat(String chatId, Map<String, dynamic> data) async {
    await _firestore.collection('chats').doc(chatId).update(data);
  }

  Future<void> updateChatSettings(
      String chatId, Map<String, dynamic> settings) async {
    await _firestore.collection('chat_settings').doc(chatId).set(
          settings,
          SetOptions(merge: true),
        );
  }

  Future<void> leaveChat(String chatId) async {
    final user = await getCurrentUser();
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayRemove([user.id]),
    });
  }

  Future<void> addParticipants(String chatId, List<String> userIds) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion(userIds),
    });
  }

  Future<void> removeParticipant(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
  }

  Future<List<MessageModel>> searchMessages(
      String chatId, String searchText) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('content', isGreaterThanOrEqualTo: searchText)
        .where('content', isLessThan: searchText + 'z')
        .get();

    return snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }

  Future<List<ChatModel>> searchChats(String searchText) async {
    final user = await getCurrentUser();
    final snapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: user.id)
        .where('name', isGreaterThanOrEqualTo: searchText)
        .where('name', isLessThan: searchText + 'z')
        .get();

    return snapshot.docs
        .map((doc) => ChatModel.fromMap(doc.data()..['id'] = doc.id))
        .toList();
  }
} 