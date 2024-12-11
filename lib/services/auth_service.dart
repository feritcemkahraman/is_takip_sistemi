import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Oturum durumunu izle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // İlk kullanıcı kontrolü
  Future<bool> isFirstUser() async {
    try {
      print('İlk kullanıcı kontrolü yapılıyor...'); // Debug log
      final collectionRef = _firestore.collection(AppConstants.usersCollection);
      final snapshot = await collectionRef.limit(1).get();
      final isEmpty = snapshot.docs.isEmpty;
      print('Koleksiyon boş mu: $isEmpty'); // Debug log
      return isEmpty;
    } catch (e) {
      print('İlk kullanıcı kontrolü hatası: $e'); // Debug log
      return true;
    }
  }

  // Kullanıcı adı kontrolü
  Future<bool> isUsernameAvailable(String username) async {
    try {
      print('Kullanıcı adı kontrolü: $username'); // Debug log
      
      final QuerySnapshot result = await _firestore
          .collection(AppConstants.usersCollection)
          .where('username', isEqualTo: username)
          .get();

      print('Bulunan döküman sayısı: ${result.docs.length}'); // Debug log
      
      return result.docs.isEmpty;
    } catch (e) {
      print('isUsernameAvailable hatası: $e'); // Debug log
      throw 'Kullanıcı adı kontrolü sırasında hata oluştu: $e';
    }
  }

  // Giriş yap
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      String message = AppConstants.errorUnknown;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            message = AppConstants.errorUserNotFound;
            break;
          case 'wrong-password':
            message = AppConstants.errorWrongPassword;
            break;
          case 'invalid-email':
            message = AppConstants.errorInvalidEmail;
            break;
        }
      }
      throw message;
    }
  }

  // Kayıt ol
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String department = '',
  }) async {
    try {
      // Kullanıcıyı Firebase Auth'a kaydet
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı bilgilerini Firestore'a kaydet
      await _firestore.collection(AppConstants.usersCollection).doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'department': department,
        'role': AppConstants.roleUser,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      String message = AppConstants.errorUnknown;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            message = AppConstants.errorEmailAlreadyInUse;
            break;
          case 'invalid-email':
            message = AppConstants.errorInvalidEmail;
            break;
          case 'weak-password':
            message = AppConstants.errorWeakPassword;
            break;
        }
      }
      throw message;
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Mevcut kullanıcıyı getir
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Kullanıcı verilerini getir
  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
    return doc.data() ?? {};
  }

  // Tüm kullanıcıları getir
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection(AppConstants.usersCollection).snapshots();
  }

  // Kullanıcı durumunu güncelle
  Future<void> updateUserStatus(String uid, bool isActive) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'isActive': isActive});
  }

  // Kullanıcı rolünü güncelle
  Future<void> updateUserRole(String uid, String role) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'role': role});
  }
}
