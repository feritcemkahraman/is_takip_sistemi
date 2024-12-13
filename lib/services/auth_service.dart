import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/logging_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final LoggingService _loggingService;

  User? get currentUser => _auth.currentUser;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    LoggingService? loggingService,
  }) : 
    _auth = auth ?? FirebaseAuth.instance,
    _firestore = firestore ?? FirebaseFirestore.instance,
    _loggingService = loggingService ?? LoggingService();

  // Kullanıcı girişi
  Future<UserModel> signInWithUsername(String username, String password) async {
    try {
      // Kullanıcı adına göre e-posta adresini bul
      final userDoc = await _firestore
          .collection('users')
          .where('name', isEqualTo: username)
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
          .collection('users')
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
          .collection('users')
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
          .collection('users')
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

  // Mevcut kullanıcıyı getir
  Future<UserModel> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'Oturum açık değil';
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw 'Kullanıcı bulunamadı';
      }

      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      print('Kullanıcı getirme hatası: $e');
      rethrow;
    }
  }

  // Kullanıcı profilini güncelle
  Future<void> updateUserProfile({
    required String displayName,
    required String photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturum açmamış');

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);

      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
        'photoUrl': photoUrl,
      });

      await _loggingService.info(
        'Kullanıcı profili güncellendi',
        module: 'auth',
        data: {
          'userId': user.uid,
          'displayName': displayName,
        },
      );
    } catch (e) {
      await _loggingService.error(
        'Profil güncelleme hatası',
        module: 'auth',
        error: e,
      );
      rethrow;
    }
  }

  // Şifre değiştir
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı oturum açmamış');

      // Mevcut şifreyi doğrula
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Yeni şifreyi ayarla
      await user.updatePassword(newPassword);

      await _loggingService.info(
        'Kullanıcı şifresi değiştirildi',
        module: 'auth',
        data: {'userId': user.uid},
      );
    } catch (e) {
      await _loggingService.error(
        'Şifre değiştirme hatası',
        module: 'auth',
        error: e,
      );
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
      await _firestore.collection('users').doc(userId).delete();
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
      final querySnapshot = await _firestore.collection('users').get();
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
          .collection('users')
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

  // Kullanıcı rolünü güncelle
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
      });
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  // Kullanıcı durumunu güncelle
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });
    } catch (e) {
      print('Error updating user status: $e');
      rethrow;
    }
  }

  // Tüm kullanıcıları getir (stream)
  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Kullanıcı şifresini güncelle
  Future<void> updateUserPassword(String newPassword) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Şifre güncellenirken hata oluştu: $e');
    }
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      await _loggingService.info(
        'Kullanıcı bilgileri güncellendi',
        module: 'auth',
        data: {'userId': userId, 'updatedFields': data.keys.toList()},
      );
    } catch (e) {
      await _loggingService.error(
        'Kullanıcı güncelleme hatası',
        module: 'auth',
        error: e,
      );
      rethrow;
    }
  }
}
