class AppConstants {
  // App
  static const String appName = 'İş Takip Sistemi';
  static const String titleRegister = 'Kayıt Ol';

  // Collections
  static const String usersCollection = 'users';
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

  // Task Status Colors
  static const Map<String, int> taskStatusColors = {
    'pending': 0xFFFF9800,   // Orange
    'inProgress': 0xFF2196F3, // Blue
    'completed': 0xFF4CAF50,  // Green
    'cancelled': 0xFFF44336,  // Red
  };

  // Task Status Labels
  static const Map<String, String> taskStatusLabels = {
    'pending': 'Beklemede',
    'inProgress': 'Devam Ediyor',
    'completed': 'Tamamlandı',
    'cancelled': 'İptal Edildi',
  };

  // Task Priority Colors
  static const Map<String, int> taskPriorityColors = {
    'low': 0xFF8BC34A,     // Light Green
    'medium': 0xFFFFC107,  // Amber
    'high': 0xFFE91E63,    // Pink
  };

  // Task Priority Labels
  static const Map<String, String> taskPriorityLabels = {
    'low': 'Düşük',
    'medium': 'Orta',
    'high': 'Yüksek',
  };

  // Başarı mesajları
  static const String successRegister = 'Kayıt başarılı!';
  static const String successLogin = 'Giriş başarılı!';
}
