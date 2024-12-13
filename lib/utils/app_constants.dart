import 'package:flutter/material.dart';

class AppConstants {
  // Renkler
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color accentColor = Color(0xFF1976D2);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textColor = Color(0xFF212121);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFA000);

  // Takvim renkleri
  static const String taskEventColor = '#FF4CAF50';  // Green color in hex
  static const String meetingEventColor = '#4CAF50';
  static const String deadlineEventColor = '#FFA000';

  // Metin stilleri
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textColor,
  );

  // Padding değerleri
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border radius değerleri
  static const double defaultBorderRadius = 8.0;
  static const double smallBorderRadius = 4.0;
  static const double largeBorderRadius = 12.0;

  // Animasyon süreleri
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // API endpoint'leri
  static const String baseApiUrl = 'https://api.example.com';
  static const String authEndpoint = '/auth';
  static const String userEndpoint = '/users';
  static const String taskEndpoint = '/tasks';
  static const String workflowEndpoint = '/workflows';

  // Dosya boyutu limitleri
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB

  // Tarih formatları
  static const String dateFormat = 'dd.MM.yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd.MM.yyyy HH:mm';

  // Hata mesajları
  static const String genericError = 'Bir hata oluştu. Lütfen tekrar deneyin.';
  static const String networkError = 'İnternet bağlantısı hatası.';
  static const String authError = 'Oturum açma hatası.';
  static const String validationError = 'Lütfen tüm alanları doldurun.';
  static const String permissionError = 'Bu işlem için yetkiniz yok.';
}
