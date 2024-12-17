import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart'; // ChangeNotifier için gerekli

class UserService extends ChangeNotifier {
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
      print('UserService.getAllUsers başladı');
      final QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      print('Firestore sorgusu tamamlandı. Döküman sayısı: ${querySnapshot.docs.length}');

      final users = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Kullanıcı verisi: $data');

        // Timestamp dönüşümlerini güvenli şekilde yap
        DateTime? createdAt;
        if (data['createdAt'] != null) {
          createdAt = data['createdAt'] is Timestamp 
            ? (data['createdAt'] as Timestamp).toDate()
            : data['createdAt'] is String 
              ? DateTime.parse(data['createdAt'])
              : DateTime.now();
        }

        DateTime? lastLoginAt;
        if (data['lastLoginAt'] != null) {
          lastLoginAt = data['lastLoginAt'] is Timestamp 
            ? (data['lastLoginAt'] as Timestamp).toDate()
            : data['lastLoginAt'] is String 
              ? DateTime.parse(data['lastLoginAt'])
              : null;
        }
        
        final user = UserModel(
          id: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          username: data['username'] ?? data['email'] ?? '',
          role: data['role'] ?? '',
          department: data['department'] ?? '',
          createdAt: createdAt ?? DateTime.now(),
          avatar: data['avatar'],
          phoneNumber: data['phoneNumber'],
          title: data['title'],
          lastLoginAt: lastLoginAt,
        );
        print('Oluşturulan UserModel: ${user.toString()}');
        return user;
      }).toList();

      // Departmanlara göre kullanıcıları logla
      final departmentUsers = <String, int>{};
      for (var user in users) {
        departmentUsers[user.department] = (departmentUsers[user.department] ?? 0) + 1;
      }
      print('Departmanlara göre kullanıcı sayıları: $departmentUsers');

      print('Toplam ${users.length} kullanıcı yüklendi');
      return users;
    } catch (e, stackTrace) {
      print('getAllUsers hatası: $e');
      print('Stack trace: $stackTrace');
      rethrow;
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
