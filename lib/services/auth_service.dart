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

  // Kullanıcı adı ile giriş yap
  Future<void> signInWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      // Kullanıcı adına göre kullanıcıyı bul
      final QuerySnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        throw AppConstants.errorUserNotFound;
      }

      // Kullanıcının email'ini al
      final String email = userDoc.docs.first.get('email') as String;

      // Firebase Auth ile giriş yap
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
        }
      } else if (e is String) {
        message = e;
      }
      throw message;
    }
  }

  // Kayıt ol (kullanıcı adı ile)
  Future<void> registerWithUsername({
    required String name,
    required String username,
    required String password,
    required String department,
  }) async {
    try {
      // Kullanıcı adının kullanılabilir olduğunu kontrol et
      final bool isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw AppConstants.errorUsernameAlreadyInUse;
      }

      // İlk kullanıcı kontrolü
      final bool isFirst = await isFirstUser();
      print('İlk kullanıcı mı: $isFirst'); // Debug log

      // Benzersiz bir email oluştur
      final String email = '$username@hanholding.com';
      print('Oluşturulan email: $email'); // Debug log

      // Kullanıcıyı Firebase Auth'a kaydet
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw 'Kullanıcı oluşturulamadı';
      }

      print('Firebase Auth kaydı başarılı. UID: ${userCredential.user?.uid}'); // Debug log

      // Firestore'a kayıt
      try {
        print('Firestore kayıt işlemi başlıyor...'); // Debug log
        
        final userData = {
          'name': name,
          'username': username,
          'email': email,
          'department': department,
          'role': isFirst ? AppConstants.roleAdmin : AppConstants.roleUser,
          'createdAt': Timestamp.now(),
          'isActive': true,
        };
        
        print('Kaydedilecek kullanıcı verisi: $userData'); // Debug log
        
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(userData);
            
        print('Firestore kaydı başarılı'); // Debug log
        return;
      } catch (firestoreError) {
        print('Firestore hatası: $firestoreError');
        // Firestore kaydı başarısız olursa kullanıcıyı sil
        await userCredential.user?.delete();
        throw 'Firestore kayıt hatası: $firestoreError';
      }
    } catch (e) {
      print('Genel kayıt hatası: $e');
      throw e.toString();
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
