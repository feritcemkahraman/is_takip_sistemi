import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

extension UserExtension on User {
  Future<UserModel?> getUserModel() async {
    try {
      final authService = AuthService(
        auth: FirebaseAuth.instance,
        firestore: FirebaseFirestore.instance,
      );
      return await authService.getCurrentUserModel();
    } catch (e) {
      print('Kullanıcı modeli getirme hatası: $e');
      return null;
    }
  }

  String? get role => getUserModel().then((model) => model?.role);
}
