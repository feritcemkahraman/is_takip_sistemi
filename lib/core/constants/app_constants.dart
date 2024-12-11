class AppConstants {
  static const String appName = 'İş Takip Sistemi';
  
  // Firebase collection names
  static const String usersCollection = 'users';
  static const String tasksCollection = 'tasks';
  static const String departmentsCollection = 'departments';
  static const String notificationsCollection = 'notifications';
  static const String meetingsCollection = 'meetings';

  // Task priorities
  static const String priorityHigh = 'Acil';
  static const String priorityMedium = 'Normal';
  static const String priorityLow = 'Düşük';

  // Task statuses
  static const String statusPending = 'Beklemede';
  static const String statusInProgress = 'Devam Ediyor';
  static const String statusCompleted = 'Tamamlandı';
  static const String statusDelayed = 'Gecikmiş';

  // User roles
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'employee';
}
