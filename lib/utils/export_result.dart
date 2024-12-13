class ExportResult {
  final bool isSuccess;
  final String? filePath;
  final String? error;
  final bool isCancelled;
  final String? message;

  const ExportResult({
    required this.isSuccess,
    this.filePath,
    this.error,
    this.isCancelled = false,
    this.message,
  });

  factory ExportResult.success({
    required String filePath,
    String? message,
  }) {
    return ExportResult(
      isSuccess: true,
      filePath: filePath,
      message: message,
    );
  }

  factory ExportResult.error({
    required String error,
    String? message,
  }) {
    return ExportResult(
      isSuccess: false,
      error: error,
      message: message,
    );
  }

  factory ExportResult.cancelled({String? message}) {
    return ExportResult(
      isSuccess: false,
      isCancelled: true,
      message: message,
    );
  }
}
