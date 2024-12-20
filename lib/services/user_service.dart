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

  Future<UserModel?> getUserById(String userId) async {
    try {
      if (userId.isEmpty) {
        print('Kullanıcı ID boş olamaz');
        return null;
      }

      final doc = await _firestore.collection(_collection).doc(userId).get();
      
      if (!doc.exists) {
        print('Kullanıcı bulunamadı: $userId');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        print('Kullanıcı verisi boş: $userId');
        return null;
      }

      return UserModel.fromMap({...data, 'id': doc.id});
    } catch (e) {
      print('Kullanıcı bilgileri alınamadı: $e');
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Kullanıcılar alınırken hata oluştu: $e');
      return [];
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap({...data, 'id': doc.id});
      }).toList();
    } catch (e) {
      print('Kullanıcı araması yapılırken hata oluştu: $e');
      return [];
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      throw Exception('Kullanıcı silinemedi: $e');
    }
  }

  // Birden fazla kullanıcıyı stream olarak getir
  Stream<List<UserModel>> getMultipleUsers(List<String> userIds) {
    if (userIds.isEmpty) return Stream.value([]);
    
    return _firestore
        .collection(_collection)
        .where(FieldPath.documentId, whereIn: userIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }
}
