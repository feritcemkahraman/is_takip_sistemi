import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
        appId: String.fromEnvironment('FIREBASE_APP_ID'),
        messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
        authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
        storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      ),
    );

    // Enable offline persistence
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );

    // Set cache size to 100MB
    FirebaseFirestore.instance.settings = const Settings(
      cacheSizeBytes: 100 * 1024 * 1024,
      persistenceEnabled: true,
      sslEnabled: true,
    );
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
