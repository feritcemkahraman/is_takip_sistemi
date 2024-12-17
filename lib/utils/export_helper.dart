import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/storage_service.dart';
import 'file_helper.dart';
import 'export_result.dart';

class ExportHelper {
  // Dosyayı paylaş
  static Future<ExportResult> shareFile(
    File file, {
    String subject = '',
    String text = '',
    Function(double)? onProgress,
  }) async {
    ExportResult? result;
    var retryCount = 0;

    do {
      try {
        // Büyük dosyalar için parçalı transfer
        final tempFile = await FileHelper.createTempFile('temp', file.path.split('.').last);
        if (tempFile == null) {
          throw Exception('Geçici dosya oluşturulamadı');
        }

        final success = await FileHelper.chunkedTransfer(
          file,
          tempFile,
          onProgress: onProgress,
        );

        if (!success) {
          throw Exception('Dosya transferi başarısız');
        }

        // Dosyayı paylaş
        final shareResult = await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: subject,
          text: text,
        );

        if (shareResult.status == ShareResultStatus.success) {
          result = ExportResult(
            isSuccess: true,
            filePath: tempFile.path,
            message: 'Dosya başarıyla paylaşıldı',
          );
        } else {
          throw Exception('Dosya paylaşma iptal edildi');
        }
      } catch (e) {
        retryCount++;
        if (retryCount < 3) {
          result = ExportResult(
            isSuccess: false,
            message: 'Yeniden deneniyor (${retryCount}/3)',
          );
          // Yeniden denemeden önce kısa bir bekleme
          await Future.delayed(Duration(seconds: retryCount));
        } else {
          result = ExportResult(
            isSuccess: false,
            message: 'Dosya paylaşma hatası: $e',
          );
        }
      }
    } while (result?.isSuccess == false && retryCount < 3);

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

  // Hata dialog'unu göster
  static Future<void> showErrorDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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

  // Yükleniyor dialog
  static Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Dışa aktarılıyor...'),
            ],
          ),
        );
      },
    );
  }

  // Yükleniyor dialogunu gizle
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Dışa aktarma sonucu dialog
  static Future<void> showExportResultDialog(
    BuildContext context,
    ExportResult result,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(result.isSuccess ? 'Başarılı' : 'Hata'),
          content: Text(result.message ?? 'İşlem tamamlandı.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}