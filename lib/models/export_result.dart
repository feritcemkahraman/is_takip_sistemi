import 'dart:io';

class ExportResult {
  final File? file;
  final String message;
  final bool isSuccess;

  const ExportResult({
    this.file,
    required this.message,
    required this.isSuccess,
  });

  factory ExportResult.success(File file) {
    return ExportResult(
      file: file,
      message: 'Dışa aktarma başarılı',
      isSuccess: true,
    );
  }

  factory ExportResult.error(String message) {
    return ExportResult(
      message: message,
      isSuccess: false,
    );
  }
}
