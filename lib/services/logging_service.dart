import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LoggingService {
  final FirebaseCrashlytics _crashlytics;
  final FirebaseAnalytics _analytics;
  final FirebaseFirestore _firestore;

  LoggingService({
    FirebaseCrashlytics? crashlytics,
    FirebaseAnalytics? analytics,
    FirebaseFirestore? firestore,
  })  : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance,
        _analytics = analytics ?? FirebaseAnalytics.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Log seviyeleri
  static const String levelDebug = 'debug';
  static const String levelInfo = 'info';
  static const String levelWarning = 'warning';
  static const String levelError = 'error';
  static const String levelCritical = 'critical';

  // Debug log
  Future<void> debug(
    String message, {
    required String module,
    Map<String, dynamic>? data,
  }) async {
    if (kDebugMode) {
      await _log(
        level: levelDebug,
        message: message,
        module: module,
        data: data,
      );
    }
  }

  // Info log
  Future<void> info(
    String message, {
    required String module,
    Map<String, dynamic>? data,
  }) async {
    await _log(
      level: levelInfo,
      message: message,
      module: module,
      data: data,
    );
  }

  // Warning log
  Future<void> warning(
    String message, {
    required String module,
    Map<String, dynamic>? data,
  }) async {
    await _log(
      level: levelWarning,
      message: message,
      module: module,
      data: data,
    );
  }

  // Error log
  Future<void> error(
    String message, {
    required String module,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) async {
    await _log(
      level: levelError,
      message: message,
      module: module,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );

    // Crashlytics'e gönder
    if (error != null) {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: message,
        information: [
          'Module: $module',
          if (data != null) 'Data: ${data.toString()}',
        ],
      );
    }
  }

  // Critical log
  Future<void> critical(
    String message, {
    required String module,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) async {
    await _log(
      level: levelCritical,
      message: message,
      module: module,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );

    // Crashlytics'e gönder
    if (error != null) {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: true,
        information: [
          'Module: $module',
          if (data != null) 'Data: ${data.toString()}',
        ],
      );
    }
  }

  // Performans log
  Future<void> performance(
    String operation, {
    required String module,
    required int durationMs,
    Map<String, dynamic>? data,
  }) async {
    await _log(
      level: levelInfo,
      message: 'Performance measurement',
      module: module,
      data: {
        'operation': operation,
        'duration_ms': durationMs,
        ...?data,
      },
    );

    // Analytics'e gönder
    await _analytics.logEvent(
      name: 'performance_measurement',
      parameters: {
        'module': module,
        'operation': operation,
        'duration_ms': durationMs,
        if (data != null) ...data,
      },
    );
  }

  // Kullanıcı etkileşimi log
  Future<void> userAction(
    String action, {
    required String module,
    Map<String, dynamic>? data,
  }) async {
    await _log(
      level: levelInfo,
      message: 'User action',
      module: module,
      data: {
        'action': action,
        ...?data,
      },
    );

    // Analytics'e gönder
    await _analytics.logEvent(
      name: action,
      parameters: {
        'module': module,
        if (data != null) ...data,
      },
    );
  }

  // İş akışı log
  Future<void> workflow(
    String action, {
    required String workflowId,
    required String stepId,
    Map<String, dynamic>? data,
  }) async {
    await _log(
      level: levelInfo,
      message: 'Workflow action',
      module: 'workflow',
      data: {
        'action': action,
        'workflow_id': workflowId,
        'step_id': stepId,
        ...?data,
      },
    );

    // Analytics'e gönder
    await _analytics.logEvent(
      name: 'workflow_action',
      parameters: {
        'action': action,
        'workflow_id': workflowId,
        'step_id': stepId,
        if (data != null) ...data,
      },
    );
  }

  // Ana log metodu
  Future<void> _log({
    required String level,
    required String message,
    required String module,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) async {
    final now = DateTime.now();
    final logEntry = {
      'timestamp': Timestamp.fromDate(now),
      'level': level,
      'message': message,
      'module': module,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
      if (data != null) 'data': data,
      'environment': kDebugMode ? 'development' : 'production',
      'platform': defaultTargetPlatform.toString(),
    };

    try {
      // Firestore'a kaydet
      await _firestore.collection('logs').add(logEntry);

      // Debug konsola yazdır
      if (kDebugMode) {
        print('[$level] $message');
        if (error != null) print('Error: $error');
        if (stackTrace != null) print('Stack trace: $stackTrace');
        if (data != null) print('Data: $data');
      }
    } catch (e, st) {
      // Log kaydı başarısız olursa sadece konsola yazdır
      if (kDebugMode) {
        print('Log kaydı başarısız: $e');
        print(st);
      }
    }
  }

  // Log temizleme (eski logları sil)
  Future<void> cleanOldLogs({Duration? retention}) async {
    try {
      final retentionPeriod = retention ?? const Duration(days: 30);
      final cutoffDate = Timestamp.fromDate(
        DateTime.now().subtract(retentionPeriod),
      );

      final snapshot = await _firestore
          .collection('logs')
          .where('timestamp', isLessThan: cutoffDate)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      await info(
        'Eski loglar temizlendi',
        module: 'logging',
        data: {
          'deleted_count': snapshot.docs.length,
          'retention_days': retentionPeriod.inDays,
        },
      );
    } catch (e, st) {
      await error(
        'Log temizleme hatası',
        module: 'logging',
        error: e,
        stackTrace: st,
      );
    }
  }

  // Log istatistikleri
  Future<Map<String, dynamic>> getLogStats({
    Duration? period,
    String? module,
  }) async {
    try {
      final startDate = period != null
          ? Timestamp.fromDate(DateTime.now().subtract(period))
          : null;

      var query = _firestore.collection('logs').get();

      if (startDate != null) {
        query = _firestore.collection('logs')
            .where('timestamp', isGreaterThan: startDate)
            .get();
      }

      if (module != null) {
        query = _firestore.collection('logs')
            .where('module', isEqualTo: module)
            .get();
      }

      final snapshot = await query;

      // Seviye bazında sayılar
      final levelCounts = <String, int>{};
      // Modül bazında sayılar
      final moduleCounts = <String, int>{};
      // Hata sayıları
      var errorCount = 0;
      // Performans ortalamaları
      var totalPerformanceDuration = 0;
      var performanceCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final level = data['level'] as String;
        final logModule = data['module'] as String;

        // Seviye sayacı
        levelCounts[level] = (levelCounts[level] ?? 0) + 1;
        // Modül sayacı
        moduleCounts[logModule] = (moduleCounts[logModule] ?? 0) + 1;

        // Hata sayacı
        if (data['error'] != null) {
          errorCount++;
        }

        // Performans hesaplaması
        if (data['data'] != null &&
            (data['data'] as Map<String, dynamic>)['duration_ms'] != null) {
          totalPerformanceDuration +=
              (data['data'] as Map<String, dynamic>)['duration_ms'] as int;
          performanceCount++;
        }
      }

      return {
        'total_logs': snapshot.docs.length,
        'by_level': levelCounts,
        'by_module': moduleCounts,
        'error_count': errorCount,
        'average_performance': performanceCount > 0
            ? totalPerformanceDuration / performanceCount
            : null,
        'period': period?.inDays,
        'module': module,
      };
    } catch (e, st) {
      await error(
        'Log istatistikleri hesaplama hatası',
        module: 'logging',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}