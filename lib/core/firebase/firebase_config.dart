import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('FirebaseConfig zaten başlatılmış durumda');
      return;
    }

    try {
      // Firestore ayarlarını yap
      FirebaseFirestore.instance.settings = const Settings(
        cacheSizeBytes: 100 * 1024 * 1024,
        persistenceEnabled: true,
        sslEnabled: true,
      );

      // Web dışı platformlarda persistence'ı etkinleştir
      if (!kIsWeb) {
        try {
          await FirebaseFirestore.instance.enablePersistence(
            const PersistenceSettings(synchronizeTabs: true),
          );
          debugPrint('Firestore persistence başarıyla etkinleştirildi');
        } catch (e) {
          debugPrint('Persistence etkinleştirme hatası (kritik değil): $e');
        }
      }

      _initialized = true;
      debugPrint('FirebaseConfig başarıyla başlatıldı');
    } catch (e) {
      debugPrint('FirebaseConfig başlatma hatası: $e');
      rethrow;
    }
  }

  static FirebaseFirestore getFirestore() {
    return FirebaseFirestore.instance;
  }

  static CollectionReference<Map<String, dynamic>> getWorkflowsRef() {
    return getFirestore().collection('workflows');
  }

  static CollectionReference<Map<String, dynamic>> getStepsRef(String workflowId) {
    return getWorkflowsRef().doc(workflowId).collection('steps');
  }

  static CollectionReference<Map<String, dynamic>> getUsersRef() {
    return getFirestore().collection('users');
  }

  static CollectionReference<Map<String, dynamic>> getFCMTokensRef() {
    return getFirestore().collection('fcmTokens');
  }

  static DocumentReference<Map<String, dynamic>> getWorkflowRef(String workflowId) {
    return getWorkflowsRef().doc(workflowId);
  }

  static DocumentReference<Map<String, dynamic>> getStepRef(
    String workflowId,
    String stepId,
  ) {
    return getStepsRef(workflowId).doc(stepId);
  }

  static DocumentReference<Map<String, dynamic>> getUserRef(String userId) {
    return getUsersRef().doc(userId);
  }

  static Query<Map<String, dynamic>> getAssignedWorkflowsQuery(String userId) {
    return getWorkflowsRef().where('assignedTo', arrayContains: userId);
  }

  static Query<Map<String, dynamic>> getCreatedWorkflowsQuery(String userId) {
    return getWorkflowsRef().where('createdBy', isEqualTo: userId);
  }

  static Query<Map<String, dynamic>> getOverdueStepsQuery() {
    return getWorkflowsRef()
        .where('status', whereIn: [
          'active',
          'in_progress',
        ])
        .where('steps', arrayContains: {
          'status': {'!=': 'completed'},
          'dueDate': {'<': Timestamp.now()},
        });
  }

  static WriteBatch getBatch() {
    return getFirestore().batch();
  }
}
