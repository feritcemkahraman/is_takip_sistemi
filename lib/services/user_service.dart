import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart'; // ChangeNotifier için gerekli

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final String _collection = 'users';

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> loadCurrentUser(String userId) async {
    try {
      final userDoc = await _firestore.collection(_collection).doc(userId).get();
      if (userDoc.exists) {
        _currentUser = UserModel.fromMap(userDoc.data()!..['id'] = userDoc.id);
        notifyListeners();
      }
    } catch (e) {
      print('Mevcut kullanıcı yüklenemedi: $e');
      rethrow;
    }
  }

  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) {
        throw Exception('Kullanıcı bulunamadı');
      }
      return UserModel.fromMap(doc.data()!..['id'] = doc.id);
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınamadı: $e');
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcılar alınırken hata oluştu: $e');
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcı araması yapılırken hata oluştu: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      throw Exception('Kullanıcı silinemedi: $e');
    }
  }
}
