import 'package:flutter/material.dart';

class AppConstants {
  // App
  static const String appName = 'İş Takip Sistemi';
  static const String titleRegister = 'Kayıt Ol';

  // Collections
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';
  static const String reportsCollection = 'reports';
  static const String commentsCollection = 'comments';
  static const String projectsCollection = 'projects';

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
  static const String labelPriority = 'Öncelik';
  static const String labelProgress = 'İlerleme';
  static const String labelTags = 'Etiketler';
  static const String labelAttachments = 'Ekler';
  static const String labelComments = 'Yorumlar';

  // Buttons
  static const String buttonLogin = 'Giriş Yap';
  static const String buttonRegister = 'Kayıt Ol';
  static const String buttonSave = 'Kaydet';
  static const String buttonUpdate = 'Güncelle';
  static const String buttonDelete = 'Sil';
  static const String buttonCancel = 'İptal';
  static const String buttonClose = 'Kapat';
  static const String buttonAdd = 'Ekle';
  static const String buttonRemove = 'Kaldır';
  static const String buttonSearch = 'Ara';
  static const String buttonFilter = 'Filtrele';
  static const String buttonClear = 'Temizle';
  static const String buttonNext = 'İleri';
  static const String buttonBack = 'Geri';
  static const String buttonFinish = 'Bitir';

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
  static const String errorRequired = 'Bu alan zorunludur';
  static const String errorInvalidPassword = 'Geçersiz şifre';
  static const String errorPasswordMismatch = 'Şifreler eşleşmiyor';
  static const String errorInvalidDate = 'Geçersiz tarih';
  static const String errorInvalidNumber = 'Geçersiz sayı';
  static const String errorInvalidPhone = 'Geçersiz telefon numarası';
  static const String errorUnexpected = 'Beklenmeyen bir hata oluştu';
  static const String errorNoInternet = 'İnternet bağlantısı yok';
  static const String errorTimeout = 'İstek zaman aşımına uğradı';
  static const String errorServer = 'Sunucu hatası';
  static const String errorPermission = 'Yetkiniz yok';
  static const String errorNotFound = 'Bulunamadı';
  static const String errorAlreadyExists = 'Zaten mevcut';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleEmployee = 'employee';
  static const String roleUser = 'user';

  // Role Names
  static const Map<String, String> roleNames = {
    roleAdmin: 'Yönetici',
    roleManager: 'Müdür',
    roleEmployee: 'Çalışan',
    roleUser: 'Kullanıcı',
  };

  // Role List
  static const List<String> roles = [
    roleAdmin,
    roleManager,
    roleEmployee,
    roleUser,
  ];

  // Departments
  static const List<String> departments = [
    'Muhasebe',
    'Mühendislik Departmanı',
    'Teknik Ekip',
    'Yazılım / PR',
    'İnsan Kaynakları',
    'Satış / Pazarlama',
  ];

  // Task Status
  static const String statusNew = 'new';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusOnHold = 'on_hold';
  static const String statusDelayed = 'delayed';
  static const String statusPending = 'pending';

  static const Map<String, String> taskStatusLabels = {
    statusNew: 'Yeni',
    statusInProgress: 'Devam Ediyor',
    statusCompleted: 'Tamamlandı',
    statusCancelled: 'İptal Edildi',
    statusOnHold: 'Askıda',
    statusDelayed: 'Gecikmiş',
    statusPending: 'Beklemede',
  };

  static const Map<String, int> taskStatusColors = {
    statusNew: 0xFF2196F3, // Blue
    statusInProgress: 0xFFFFA726, // Orange
    statusCompleted: 0xFF4CAF50, // Green
    statusCancelled: 0xFFF44336, // Red
    statusOnHold: 0xFF9E9E9E, // Grey
    statusDelayed: 0xFFE91E63, // Pink
    statusPending: 0xFFFF9800, // Orange
  };

  // Task Priority
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';
  static const String priorityNormal = 'normal';

  static const Map<String, String> taskPriorityLabels = {
    priorityLow: 'Düşük',
    priorityMedium: 'Orta',
    priorityHigh: 'Yüksek',
    priorityUrgent: 'Acil',
    priorityNormal: 'Normal',
  };

  static const Map<String, int> taskPriorityColors = {
    priorityLow: 0xFF4CAF50, // Green
    priorityMedium: 0xFFFFA726, // Orange
    priorityHigh: 0xFFF44336, // Red
    priorityUrgent: 0xFF9C27B0, // Purple
    priorityNormal: 0xFF2196F3, // Blue
  };

  // Report Types
  static const String reportTypeTask = 'task';
  static const String reportTypeDepartment = 'department';
  static const String reportTypeUser = 'user';

  static const Map<String, String> reportTypeLabels = {
    reportTypeTask: 'Görev Raporu',
    reportTypeDepartment: 'Departman Raporu',
    reportTypeUser: 'Kullanıcı Raporu',
  };

  // File Types
  static const String fileTypeImage = 'image';
  static const String fileTypeDocument = 'document';
  static const String fileTypeSpreadsheet = 'spreadsheet';
  static const String fileTypePresentation = 'presentation';
  static const String fileTypePDF = 'pdf';
  static const String fileTypeOther = 'other';

  static const Map<String, String> fileTypeLabels = {
    fileTypeImage: 'Resim',
    fileTypeDocument: 'Belge',
    fileTypeSpreadsheet: 'Hesap Tablosu',
    fileTypePresentation: 'Sunum',
    fileTypePDF: 'PDF',
    fileTypeOther: 'Diğer',
  };

  // Date Formats
  static const String dateFormatFull = 'dd/MM/yyyy HH:mm';
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String dateFormatTime = 'HH:mm';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Search
  static const int minSearchLength = 3;
  static const int maxSearchLength = 50;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = [
    'jpg', 'jpeg', 'png', 'gif',
    'doc', 'docx', 'xls', 'xlsx',
    'ppt', 'pptx', 'pdf', 'txt',
  ];

  // Success Messages
  static const String successTaskCreated = 'Görev başarıyla oluşturuldu';
  static const String successTaskUpdated = 'Görev başarıyla güncellendi';
  static const String successTaskDeleted = 'Görev başarıyla silindi';
  static const String successCommentAdded = 'Yorum başarıyla eklendi';
  static const String successFileUploaded = 'Dosya başarıyla yüklendi';

  // Google Calendar API
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );
  static const String googleClientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: '',
  );

  // Calendar Settings
  static const List<String> calendarViews = [
    'month',
    'week',
    'day',
  ];

  static const List<String> calendarViewTitles = [
    'Aylık',
    'Haftalık',
    'Günlük',
  ];

  static const List<String> eventDurations = [
    '30m',
    '1h',
    '2h',
    '3h',
    '4h',
    'all_day',
  ];

  static const List<String> eventDurationTitles = [
    '30 Dakika',
    '1 Saat',
    '2 Saat',
    '3 Saat',
    '4 Saat',
    'Tüm Gün',
  ];

  // Colors
  static const Color taskEventColor = Colors.blue;
  static const Color meetingEventColor = Colors.green;
  static const Color holidayEventColor = Colors.red;
  static const Color taskEventOverdueColor = Colors.red;
  static const Color taskEventCompletedColor = Colors.green;
}
