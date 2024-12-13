import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _collection = 'users';

  User? get currentUser => _auth.currentUser;

  AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  // Kullanıcı girişi
  Future<UserModel> signInWithUsername(String username, String password) async {
    try {
      // Kullanıcı adına göre e-posta adresini bul
      final userDoc = await _firestore
          .collection(_collection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        throw 'Kullanıcı bulunamadı';
      }

      final email = userDoc.docs.first.data()['email'] as String;

      // Firebase Auth ile giriş yap
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı modelini döndür
      return await getCurrentUserModel();
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı kaydı
  Future<UserModel> registerWithUsername(
    String username,
    String email,
    String password,
    String name,
    String department,
  ) async {
    try {
      // Kullanıcı adının benzersiz olduğunu kontrol et
      final existingUser = await _firestore
          .collection(_collection)
          .where('username', isEqualTo: username)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw 'Bu kullanıcı adı zaten kullanılıyor';
      }

      // Firebase Auth ile kayıt ol
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'a kullanıcı bilgilerini kaydet
      final user = UserModel(
        id: userCredential.user!.uid,
        username: username,
        email: email,
        name: name,
        department: department,
        role: 'user',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(userCredential.user!.uid)
          .set(user.toMap());

      return user;
    } catch (e) {
      print('Kayıt hatası: $e');
      rethrow;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Çıkış hatası: $e');
      rethrow;
    }
  }

  // Mevcut kullanıcı modelini getir
  Future<UserModel> getCurrentUserModel() async {
    try {
      if (_auth.currentUser == null) {
        throw 'Oturum açılmamış';
      }

      final doc = await _firestore
          .collection(_collection)
          .doc(_auth.currentUser!.uid)
          .get();

      if (!doc.exists) {
        throw 'Kullanıcı bulunamadı';
      }

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Kullanıcı modeli getirme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı profilini güncelle
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(userId).update(data);
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      rethrow;
    }
  }

  // Şifre değiştir
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_auth.currentUser == null) {
        throw 'Oturum açılmamış';
      }

      // Mevcut şifreyi doğrula
      final email = _auth.currentUser!.email!;
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: currentPassword,
      );

      // Yeni şifreyi güncelle
      await _auth.currentUser!.updatePassword(newPassword);
    } catch (e) {
      print('Şifre değiştirme hatası: $e');
      rethrow;
    }
  }

  // Şifremi unuttum
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Şifre sıfırlama hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı sil
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).delete();
      if (_auth.currentUser?.uid == userId) {
        await _auth.currentUser?.delete();
      }
    } catch (e) {
      print('Kullanıcı silme hatası: $e');
      rethrow;
    }
  }

  // Tüm kullanıcıları getir
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Kullanıcıları getirme hatası: $e');
      rethrow;
    }
  }

  // Departmana göre kullanıcıları getir
  Future<List<UserModel>> getUsersByDepartment(String department) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('department', isEqualTo: department)
          .get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Departman kullanıcılarını getirme hatası: $e');
      rethrow;
    }
  }
}
