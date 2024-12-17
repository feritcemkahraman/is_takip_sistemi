import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import '../exceptions/workflow_exception.dart';

class ErrorHandler {
  final FirebaseCrashlytics _crashlytics;

  ErrorHandler({FirebaseCrashlytics? crashlytics}) 
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  Future<void> handleError(dynamic error, StackTrace? stackTrace) async {
    if (kDebugMode) {
      print('Error: $error');
      if (stackTrace != null) print(stackTrace);
      return;
    }

    if (error is WorkflowException) {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: error.message,
        fatal: false,
      );
    } else {
      await _crashlytics.recordError(
        error,
        stackTrace,
        fatal: true,
      );
    }
  }

  Future<void> setUserIdentifier(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await _crashlytics.recordFlutterError(details);
  }
}
