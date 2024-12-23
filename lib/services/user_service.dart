import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  UserService() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('current_user_id');
      
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          _currentUser = UserModel.fromMap({...userDoc.data()!, 'id': userDoc.id});
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  void setCurrentUser(UserModel? user) async {
    _currentUser = user;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      if (user != null) {
        await prefs.setString('current_user_id', user.id);
      } else {
        await prefs.remove('current_user_id');
      }
    } catch (e) {
      print('Error saving current user: $e');
    }

    notifyListeners();
  }

  Future<void> saveFcmToken(String token) async {
    if (_currentUser == null) return;

    await _firestore.collection('users').doc(_currentUser!.id).update({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc.data()['name'] as String,
              'email': doc.data()['email'] as String,
              'role': doc.data()['role'] as String,
            })
        .toList();
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return UserModel.fromMap({...data, 'id': doc.id});
  }

  Future<List<UserModel>> getAllUsers() async {
    final querySnapshot = await _firestore.collection('users').get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return UserModel.fromMap({...data, 'id': doc.id});
    }).toList();
  }

  Future<void> updateUserProfile({
    required String name,
    String? photoUrl,
  }) async {
    if (_currentUser == null) return;

    await _firestore.collection('users').doc(_currentUser!.id).update({
      'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });

    // Mevcut kullanıcı bilgilerini güncelle
    await _loadCurrentUser();
  }

  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
}
