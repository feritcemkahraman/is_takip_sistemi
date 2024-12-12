import 'package:flutter/material.dart';

class AppConstants {
  // App
  static const String appName = 'İş Takip Sistemi';
  static const String titleRegister = 'Kayıt Ol';

  // Collections
  static const String usersCollection = 'han_users';
  static const String tasksCollection = 'tasks';

  // Labels
  static const String labelName = 'Ad Soyad';
  static const String labelEmail = 'E-posta';
  static const String labelPassword = 'Şifre';
  static const String labelConfirmPassword = 'Şifre (Tekrar)';
  static const String labelDepartment = 'Departman';
  static const String labelFullName = 'Ad Soyad';
  static const String labelRole = 'Rol';
  static const String labelTitle = 'Başlık';
  static const String labelDescription = 'Açıklama';
  static const String labelStatus = 'Durum';
  static const String labelDueDate = 'Bitiş Tarihi';
  static const String labelAssignedTo = 'Atanan Kişi';

  // Buttons
  static const String buttonLogin = 'Giriş Yap';
  static const String buttonRegister = 'Kayıt Ol';
  static const String buttonSave = 'Kaydet';
  static const String buttonUpdate = 'Güncelle';
  static const String buttonDelete = 'Sil';
  static const String buttonCancel = 'İptal';

  // Error Messages
  static const String errorRequiredField = 'Bu alan zorunludur';
  static const String errorInvalidEmail = 'Geçerli bir e-posta adresi giriniz';
  static const String errorPasswordTooShort = 'Şifre en az 6 karakter olmalıdır';
  static const String errorPasswordsDoNotMatch = 'Şifreler eşleşmiyor';
  static const String errorUnknown = 'Bir hata oluştu';
  static const String errorUserNotFound = 'Kullanıcı bulunamadı';
  static const String errorWrongPassword = 'Hatalı şifre';
  static const String errorEmailAlreadyInUse = 'Bu e-posta adresi zaten kullanımda';
  static const String errorWeakPassword = 'Şifre çok zayıf';
  static const String errorUsernameAlreadyInUse = 'Bu kullanıcı adı zaten kullanımda';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'employee';
  static const String roleUser = 'user';

  // Departments
  static const List<String> departments = [
    'Satış / Pazarlama',
    'Mühendislik Departmanı',
    'Teknik Ekip',
    'Muhasebe',
    'İnsan Kaynakları',
    'Yazılım / PR',
  ];

  // Task Priorities
  static const String priorityHigh = 'high';
  static const String priorityNormal = 'normal';
  static const String priorityLow = 'low';

  static const Map<String, String> priorityLabels = {
    priorityHigh: 'Acil',
    priorityNormal: 'Normal',
    priorityLow: 'Düşük',
  };

  static const Map<String, Color> priorityColors = {
    priorityHigh: Colors.red,
    priorityNormal: Colors.orange,
    priorityLow: Colors.green,
  };

  // Task Statuses
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusDelayed = 'delayed';
  static const String statusCancelled = 'cancelled';

  static const Map<String, String> statusLabels = {
    statusPending: 'Beklemede',
    statusInProgress: 'Devam Ediyor',
    statusCompleted: 'Tamamlandı',
    statusDelayed: 'Gecikmiş',
    statusCancelled: 'İptal Edildi',
  };

  static const Map<String, Color> statusColors = {
    statusPending: Colors.orange,
    statusInProgress: Colors.blue,
    statusCompleted: Colors.green,
    statusDelayed: Colors.red,
    statusCancelled: Colors.grey,
  };

  // Task Recurrence Types
  static const String recurrenceDaily = 'daily';
  static const String recurrenceWeekly = 'weekly';
  static const String recurrenceMonthly = 'monthly';

  static const Map<String, String> recurrenceLabels = {
    recurrenceDaily: 'Günlük',
    recurrenceWeekly: 'Haftalık',
    recurrenceMonthly: 'Aylık',
  };

  // Success Messages
  static const String successTaskCreated = 'Görev başarıyla oluşturuldu';
  static const String successTaskUpdated = 'Görev başarıyla güncellendi';
  static const String successTaskDeleted = 'Görev başarıyla silindi';
  static const String successCommentAdded = 'Yorum başarıyla eklendi';
  static const String successFileUploaded = 'Dosya başarıyla yüklendi';
}