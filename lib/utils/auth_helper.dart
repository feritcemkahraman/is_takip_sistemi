import 'package:firebase_auth/firebase_auth.dart';

class AuthHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  static Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  static Future<String?> getCurrentUserName() async {
    return _auth.currentUser?.displayName;
  }

  static Future<String?> getCurrentUserEmail() async {
    return _auth.currentUser?.email;
  }

  static Future<bool> isUserSignedIn() async {
    return _auth.currentUser != null;
  }

  static Future<bool> isUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final idTokenResult = await user.getIdTokenResult();
      return idTokenResult.claims?['admin'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
} 