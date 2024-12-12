import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import 'dart:async';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _authStateController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  AuthService() {
    print('AuthService initialized');
    print('Firestore instance: ${_firestore != null ? 'OK' : 'NULL'}');
    _authStateController.add(null);
  }

  Stream<UserModel?> get authStateChanges => _authStateController.stream;
  UserModel? get currentUser => _currentUser;

  Future<bool> isFirstUser() async {
    try {
      print('İlk kullanıcı kontrolü yapılıyor...');
      final collectionRef = _firestore.collection(AppConstants.usersCollection);
      final snapshot = await collectionRef.limit(1).get();
      final isEmpty = snapshot.docs.isEmpty;
      print('Koleksiyon boş mu: $isEmpty');
      return isEmpty;
    } catch (e) {
      print('İlk kullanıcı kontrolü hatası: $e');
      return true;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      print('Kullanıcı adı kontrolü: $username');
      
      final QuerySnapshot result = await _firestore
          .collection(AppConstants.usersCollection)
          .where('username', isEqualTo: username)
          .get();

      print('Bulunan döküman sayısı: ${result.docs.length}');
      
      return result.docs.isEmpty;
    } catch (e) {
      print('isUsernameAvailable hatası: $e');
      throw 'Kullanıcı adı kontrolü sırasında hata oluştu: $e';
    }
  }

  Future<UserModel> registerWithUsername({
    required String name,
    required String username,
    required String password,
    required String department,
  }) async {
    try {
      print('Kayıt işlemi başlıyor...');
      print('Kullanıcı adı: $username');
      print('Departman: $department');

      // Kullanıcı adı kontrolü
      final bool isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw AppConstants.errorUsernameAlreadyInUse;
      }

      // İlk kullanıcı kontrolü
      final bool isFirst = await isFirstUser();

      // Yeni kullanıcı ID'si oluştur
      final String uid = _firestore.collection(AppConstants.usersCollection).doc().id;

      // UserModel oluştur
      final user = UserModel(
        uid: uid,
        name: name,
        username: username,
        email: '$username@hanholding.com',
        department: department,
        role: isFirst ? AppConstants.roleAdmin : AppConstants.roleEmployee,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // Firestore kaydı
      try {
        print('Firestore kaydı başlıyor...');
        print('Koleksiyon: ${AppConstants.usersCollection}');
        print('Döküman ID: ${user.uid}');
        
        final userRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid);
        
        final userData = {
          ...user.toMap(),
          'password': password, // Şifreyi güvenli bir şekilde hashleyerek saklamalısınız
        };
        
        print('Kaydedilecek veri: $userData');
        
        await userRef.set(userData);
        
        print('Firestore kaydı başarılı!');
        
        // Kaydın doğru yapıldığını kontrol et
        final savedDoc = await userRef.get();
        if (!savedDoc.exists) {
          throw 'Firestore kaydı oluşturulamadı';
        }
        
        return user;
      } catch (e) {
        print('Firestore kayıt hatası: $e');
        throw 'Kullanıcı kaydı tamamlanamadı: $e';
      }
    } catch (e) {
      print('Beklenmeyen hata:');
      print('Hata tipi: ${e.runtimeType}');
      print('Hata mesajı: $e');
      throw e.toString();
    }
  }

  Future<UserModel> signInWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      print('Giriş işlemi başlıyor...');
      print('Kullanıcı adı: $username');

      final QuerySnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        throw AppConstants.errorUserNotFound;
      }

      final userData = userDoc.docs.first.data() as Map<String, dynamic>;
      
      // Şifre kontrolü
      if (userData['password'] != password) {
        throw AppConstants.errorWrongPassword;
      }

      final user = UserModel.fromMap(userData);
      _currentUser = user;
      _authStateController.add(user);

      print('Giriş başarılı: ${user.name}');
      return user;
    } catch (e) {
      print('Giriş hatası: $e');
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    print('Çıkış yapılıyor...');
    _currentUser = null;
    _authStateController.add(null);
    print('Çıkış yapıldı');
  }

  Future<UserModel?> getCurrentUserModel() async {
    return _currentUser;
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              data.remove('password'); // Şifreyi çıkar
              return UserModel.fromMap(data);
            })
            .toList());
  }

  Future<void> updateUserStatus(String uid, bool isActive) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'isActive': isActive});
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({'role': role});
  }

  void dispose() {
    _authStateController.close();
  }
}
