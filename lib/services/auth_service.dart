import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';
import '../services/user_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _collection = AppConstants.usersCollection;

  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getCurrentUserModel() async {
    try {
      // Aktif oturum bilgisini SharedPreferences'dan al
      final activeUsername = await _getActiveUsername();
      if (activeUsername == null) return null;

      // Kullanıcıyı Firestore'dan bul
      final userSnapshot = await _firestore
          .collection(_collection)
          .where('username', isEqualTo: activeUsername)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) return null;

      final userDoc = userSnapshot.docs.first;
      final userData = Map<String, dynamic>.from(userDoc.data());

      return UserModel.fromMap({...userData, 'id': userDoc.id});
    } catch (e) {
      print('getCurrentUserModel hatası: $e');
      return null;
    }
  }

  Future<String?> _getActiveUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('active_username');
    } catch (e) {
      print('_getActiveUsername hatası: $e');
      return null;
    }
  }

  Future<void> _setActiveUsername(String? username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (username == null) {
        await prefs.remove('active_username');
      } else {
        await prefs.setString('active_username', username);
      }
      notifyListeners();
    } catch (e) {
      print('_setActiveUsername hatası: $e');
    }
  }

  Future<List<UserModel>> getEmployees() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('name')
        .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap({...doc.data()!, 'id': doc.id});
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection(_collection).doc(user.id).update(user.toMap());
    notifyListeners();
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _firestore.collection(_collection).doc(userId).update({
      'isActive': isActive,
    });
    notifyListeners();
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _firestore.collection(_collection).doc(userId).update({
      'role': role,
    });
    notifyListeners();
  }

  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap({...doc.data(), 'id': doc.id}))
            .toList());
  }

  Future<void> updateUserPassword(String currentPassword, String newPassword) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    final credential = EmailAuthProvider.credential(
      email: currentUser!.email!,
      password: currentPassword,
    );

    try {
      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw Exception('Mevcut şifre yanlış');
        case 'weak-password':
          throw Exception('Yeni şifre çok zayıf');
        default:
          throw Exception('Şifre güncellenirken hata oluştu: ${e.message}');
      }
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await updateUserPassword(currentPassword, newPassword);
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Giriş denemesi - Kullanıcı adı: $email');
      
      final userSnapshot = await _firestore
          .collection(_collection)
          .where('username', isEqualTo: email)
          .limit(1)
          .get();

      print('Bulunan kullanıcı sayısı: ${userSnapshot.docs.length}');

      if (userSnapshot.docs.isEmpty) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final userDoc = userSnapshot.docs.first;
      final userData = Map<String, dynamic>.from(userDoc.data());

      print('Kullanıcı verileri: ${userData.toString()}');
      print('Girilen şifre: $password');
      print('Kayıtlı şifre: ${userData['password']}');

      if (password != userData['password'].toString()) {
        throw Exception('Yanlış şifre');
      }

      // Aktif kullanıcı adını kaydet
      await _setActiveUsername(email);

      // Son giriş zamanını güncelle
      await _firestore.collection(_collection).doc(userDoc.id).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true, // Kullanıcıyı aktif olarak işaretle
      });

      // Eksik alanları varsayılan değerlerle doldur
      final completeUserData = {
        ...userData,
        'id': userDoc.id,
        'isActive': true,
        'createdAt': userData['createdAt'] ?? Timestamp.now(),
        'permissions': List<String>.from(userData['permissions'] ?? []),
        'preferences': Map<String, dynamic>.from(userData['preferences'] ?? {}),
      };

      print('Tamamlanmış kullanıcı verileri: $completeUserData');

      final userModel = UserModel.fromMap(completeUserData);
      print('Giriş başarılı - Kullanıcı: ${userModel.name}, Rol: ${userModel.role}');
      return userModel;
    } catch (e) {
      print('Giriş hatası: $e');
      throw Exception('Giriş yapılırken hata oluştu: $e');
    }
  }

  Future<UserModel> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String username,
    required String department,
    String role = AppConstants.roleEmployee,
  }) async {
    try {
      print('Kayıt başlıyor - Kullanıcı adı: $username');
      
      // Önce kullanıcı adının benzersiz olduğunu kontrol et
      final usernameSnapshot = await _firestore
          .collection(_collection)
          .where('username', isEqualTo: username)
          .get();
      
      if (usernameSnapshot.docs.isNotEmpty) {
        throw Exception('Bu kullanıcı adı zaten kullanımda');
      }

      // Yeni kullanıcı ID'si oluştur
      final docRef = _firestore.collection(_collection).doc();

      final userModel = UserModel(
        id: docRef.id,
        name: name,
        email: email,
        username: username,
        role: role,
        department: department,
        createdAt: DateTime.now(),
      );

      final userData = <String, dynamic>{
        ...userModel.toMap(),
        'password': password, // Gerçek uygulamada güvenli hash kullanılmalı
      };

      print('Kaydedilecek kullanıcı verileri: ${userData.toString()}');

      // Kullanıcı verilerini ve şifreyi kaydet
      await docRef.set(userData).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('İşlem zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.'),
      );

      print('Kullanıcı başarıyla oluşturuldu: ${userModel.id}');
      
      // Sadece kullanıcı modelini döndür, otomatik giriş yapma
      return userModel;
    } catch (e) {
      print('Kayıt hatası: $e');
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception('Yetki hatası: Firebase kurallarını kontrol edin');
      } else if (e.toString().contains('network')) {
        throw Exception('İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.');
      }
      throw Exception('Kayıt olurken hata oluştu: $e');
    }
  }

  Future<void> signOut() async {
    await _setActiveUsername(null);
    await _auth.signOut();
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Bu e-posta adresiyle kayıtlı kullanıcı bulunamadı');
        case 'invalid-email':
          throw Exception('Geçersiz e-posta adresi');
        default:
          throw Exception('Şifre sıfırlama e-postası gönderilirken hata oluştu: ${e.message}');
      }
    }
  }

  Future<void> deleteAccount(String password) async {
    if (currentUser == null) {
      throw Exception('Kullanıcı oturum açmamış');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: password,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await _firestore.collection(_collection).doc(currentUser!.uid).delete();
      await currentUser!.delete();
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw Exception('Yanlış şifre');
        case 'requires-recent-login':
          throw Exception('Bu işlem için yeniden giriş yapmanız gerekiyor');
        default:
          throw Exception('Hesap silinirken hata oluştu: ${e.message}');
      }
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Kullanıcıları getirme hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
      notifyListeners();
    } catch (e) {
      print('Kullanıcı silme hatası: $e');
      rethrow;
    }
  }

  Future<UserModel> signInWithUsername(String username, String password) async {
    try {
      print('Giriş denemesi - Kullanıcı adı: $username');
      
      final userSnapshot = await _firestore
          .collection(_collection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final userDoc = userSnapshot.docs.first;
      final userData = Map<String, dynamic>.from(userDoc.data());

      if (password != userData['password'].toString()) {
        throw Exception('Yanlış şifre');
      }

      // Aktif kullanıcı adını kaydet
      await _setActiveUsername(username);

      // Son giriş zamanını güncelle
      await _firestore.collection(_collection).doc(userDoc.id).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      final completeUserData = {
        ...userData,
        'id': userDoc.id,
        'isActive': true,
        'createdAt': userData['createdAt'] ?? Timestamp.now(),
        'permissions': List<String>.from(userData['permissions'] ?? []),
        'preferences': Map<String, dynamic>.from(userData['preferences'] ?? {}),
      };

      final userModel = UserModel.fromMap(completeUserData);
      print('Giriş başarılı - Kullanıcı: ${userModel.name}, Rol: ${userModel.role}');
      return userModel;
    } catch (e) {
      print('Giriş hatası: $e');
      throw Exception('Giriş yapılırken hata oluştu: $e');
    }
  }

  Future<UserModel> registerUser({
    required String username,
    required String password,
    required String name,
    required String email,
    required String department,
    String role = AppConstants.roleEmployee,
  }) async {
    try {
      print('Kayıt başlıyor - Kullanıcı adı: $username');
      
      // Kullanıcı adının benzersiz olduğunu kontrol et
      final usernameSnapshot = await _firestore
          .collection(_collection)
          .where('username', isEqualTo: username)
          .get();
      
      if (usernameSnapshot.docs.isNotEmpty) {
        throw Exception('Bu kullanıcı adı zaten kullanımda');
      }

      // Yeni kullanıcı ID'si oluştur
      final docRef = _firestore.collection(_collection).doc();

      final userModel = UserModel(
        id: docRef.id,
        name: name,
        email: email,
        username: username,
        role: role,
        department: department,
        createdAt: DateTime.now(),
      );

      final userData = {
        ...userModel.toMap(),
        'password': password,
      };

      await docRef.set(userData);

      return userModel;
    } catch (e) {
      print('Kayıt hatası: $e');
      throw Exception('Kayıt olurken hata oluştu: $e');
    }
  }

  // Mevcut kullanıcıyı UserService'e kaydet
  Future<void> _updateUserService(UserModel user, BuildContext context) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      userService.setCurrentUser(user);
    } catch (e) {
      print('UserService güncellenirken hata: $e');
    }
  }

  // Login metodunu güncelle
  Future<UserModel> login(String username, String password, BuildContext context) async {
    try {
      print('Giriş denemesi - Kullanıcı adı: $username');
      
      final userDoc = await _firestore
          .collection(_collection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        throw Exception('Kullanıcı bulunamadı');
      }

      final user = UserModel.fromMap({...userDoc.docs.first.data(), 'id': userDoc.docs.first.id});
      
      // Şifre kontrolü
      if (password != user.metadata['password']) {
        throw Exception('Hatalı şifre');
      }

      // Son giriş zamanını güncelle
      await _firestore.collection(_collection).doc(user.id).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      // Aktif kullanıcıyı kaydet
      await _setActiveUsername(username);

      // UserService'i güncelle
      await _updateUserService(user, context);

      return user;
    } catch (e) {
      print('Login hatası: $e');
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> logout(BuildContext context) async {
    try {
      await _setActiveUsername(null);
      
      // UserService'den kullanıcıyı temizle
      final userService = Provider.of<UserService>(context, listen: false);
      userService.setCurrentUser(null);
    } catch (e) {
      print('Logout hatası: $e');
      rethrow;
    }
  }
}
