import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'file_helper.dart';

class ExportHelper {
  // Dışa aktarma durumu
  static const int statusSuccess = 0;
  static const int statusError = 1;
  static const int statusCancelled = 2;
  static const int statusRetry = 3;

  // Maksimum yeniden deneme sayısı
  static const int maxRetries = 3;

  // Dışa aktarma sonucu
  static class ExportResult {
    final int status;
    final String? message;
    final File? file;
    final int retryCount;

    ExportResult({
      required this.status,
      this.message,
      this.file,
      this.retryCount = 0,
    });

    bool get isSuccess => status == statusSuccess;
    bool get isError => status == statusError;
    bool get isCancelled => status == statusCancelled;
    bool get shouldRetry => status == statusRetry && retryCount < maxRetries;
  }

  // Dosyayı paylaş
  static Future<ExportResult> shareFile(
    File file, {
    String? subject,
    String? text,
    Function(double)? onProgress,
  }) async {
    int retryCount = 0;
    ExportResult? result;

    do {
      try {
        // Dosya kontrolü
        if (!await FileHelper.checkFilePermissions(file)) {
          return ExportResult(
            status: statusError,
            message: 'Dosya erişim izni yok',
            retryCount: retryCount,
          );
        }

        if (!await FileHelper.checkFileSize(file)) {
          return ExportResult(
            status: statusError,
            message: 'Dosya boyutu çok büyük',
            retryCount: retryCount,
          );
        }

        if (!FileHelper.isValidMimeType(file.path)) {
          return ExportResult(
            status: statusError,
            message: 'Geçersiz dosya türü',
            retryCount: retryCount,
          );
        }

        // Büyük dosyalar için parçalı transfer
        final tempFile = await FileHelper.createTempFile('temp', file.path.split('.').last);
        final success = await FileHelper.chunkedTransfer(
          file,
          tempFile,
          onProgress: onProgress,
        );

        if (!success) {
          throw Exception('Dosya transferi başarısız');
        }

        // Dosyayı paylaş
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: subject,
          text: text,
        );

        result = ExportResult(
          status: statusSuccess,
          file: tempFile,
          retryCount: retryCount,
        );
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          result = ExportResult(
            status: statusRetry,
            message: 'Yeniden deneniyor (${retryCount}/${maxRetries})',
            retryCount: retryCount,
          );
          // Yeniden denemeden önce kısa bir bekleme
          await Future.delayed(Duration(seconds: retryCount));
        } else {
          result = ExportResult(
            status: statusError,
            message: e.toString(),
            retryCount: retryCount,
          );
        }
      }
    } while (result?.shouldRetry ?? false);

    return result!;
  }

  // İlerleme göstergesi dialog
  static Future<void> showProgressDialog(
    BuildContext context,
    Stream<double> progressStream,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: StreamBuilder<double>(
          stream: progressStream,
          builder: (context, snapshot) {
            final progress = snapshot.data ?? 0.0;
            return Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(value: progress),
                      const SizedBox(height: 16),
                      Text('Dışa aktarılıyor: ${(progress * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Hata mesajı
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Başarı mesajı
  static void showSuccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dışa aktarma başarılı'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // İptal mesajı
  static void showCancelledSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dışa aktarma iptal edildi'),
        backgroundColor: Colors.orange,
      ),
    );
  }
} 