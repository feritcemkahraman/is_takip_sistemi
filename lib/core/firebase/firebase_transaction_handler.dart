import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:is_takip_sistemi/core/firebase/firebase_config.dart';

class FirebaseTransactionHandler {
  final FirebaseFirestore _firestore;

  FirebaseTransactionHandler({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<T> runTransaction<T>({
    required Future<T> Function(Transaction transaction) action,
    int maxAttempts = 5,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        return await FirebaseConfig.getFirestore().runTransaction(
          action,
          timeout: timeout,
        );
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    throw Exception('Transaction failed after $maxAttempts attempts');
  }

  Future<void> runBatchOperation({
    required Future<void> Function(WriteBatch batch) action,
    int maxBatchSize = 500,
    int maxAttempts = 5,
  }) async {
    final batch = FirebaseConfig.getBatch();
    int operationCount = 0;

    void commitBatchIfNeeded() async {
      if (operationCount >= maxBatchSize) {
        int attempts = 0;
        while (attempts < maxAttempts) {
          try {
            await batch.commit();
            operationCount = 0;
            break;
          } catch (e) {
            attempts++;
            if (attempts >= maxAttempts) {
              rethrow;
            }
            await Future.delayed(Duration(seconds: attempts));
          }
        }
      }
    }

    try {
      await action(batch);
      await commitBatchIfNeeded();

      if (operationCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> atomicOperation({
    required List<Future<void> Function()> operations,
    int maxAttempts = 5,
  }) async {
    int attempts = 0;
    while (attempts < maxAttempts) {
      try {
        final batch = FirebaseConfig.getBatch();
        
        for (final operation in operations) {
          await operation();
        }
        
        await batch.commit();
        break;
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }
  }
}
