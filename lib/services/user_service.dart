import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore;

  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserModel> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
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
      print('getAllUsers: Firestore sorgusu yapılıyor...');
      final snapshot = await _firestore.collection('users').get();
      print('getAllUsers: ${snapshot.docs.length} kullanıcı bulundu');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('getAllUsers: Kullanıcı verisi: $data');
        return UserModel.fromMap({
          ...data,
          'id': doc.id,
          'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
        });
      }).toList();
    } catch (e) {
      print('getAllUsers hatası: $e');
      throw Exception('Kullanıcı listesi alınamadı: $e');
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      throw Exception('Kullanıcı araması yapılamadı: $e');
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Kullanıcı güncellenemedi: $e');
    }
  }

  Future<void> updateUserAvatar(String userId, String avatarUrl) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'avatar': avatarUrl,
      });
    } catch (e) {
      throw Exception('Profil resmi güncellenemedi: $e');
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role,
      });
    } catch (e) {
      throw Exception('Kullanıcı rolü güncellenemedi: $e');
    }
  }

  Future<void> updateUserDepartment(String userId, String departmentId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'departmentId': departmentId,
      });
    } catch (e) {
      throw Exception('Kullanıcı departmanı güncellenemedi: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Kullanıcı silinemedi: $e');
    }
  }
}
