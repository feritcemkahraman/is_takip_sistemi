import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/task_service.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';
import 'services/local_storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/tasks/employee_dashboard_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/tasks/active_tasks_screen.dart';
import 'screens/tasks/completed_tasks_screen.dart';
import 'screens/create_task_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Firebase başlatılıyor...');
    
    // Firebase başlatma denemesi
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase başlatıldı');
    } catch (e) {
      debugPrint('Firebase başlatma hatası: $e');
      // Eğer uygulama zaten başlatılmışsa, mevcut instance'ı kullan
      if (e.toString().contains('already exists')) {
        Firebase.app();
        debugPrint('Mevcut Firebase instance kullanılıyor');
      } else {
        // Başka bir hata varsa yeniden fırlat
        rethrow;
      }
    }

    final userService = UserService();
    final notificationService = NotificationService();
    final localStorageService = LocalStorageService();
    debugPrint('Servisler oluşturuldu');

    // FCM token işlemleri
    try {
      debugPrint('FCM token alınıyor...');
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM token alındı: $token');
      
      if (token != null) {
        await userService.saveFcmToken(token);
        debugPrint('FCM token kaydedildi');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) async {
          try {
            await userService.saveFcmToken(newToken);
            debugPrint('Yeni FCM token kaydedildi');
          } catch (e) {
            debugPrint('Token yenileme hatası: $e');
          }
        },
        onError: (e) {
          debugPrint('Token dinleme hatası: $e');
        },
      );
    } catch (e) {
      debugPrint('FCM token hatası: $e');
      // FCM token hatası uygulamanın çalışmasını engellemeyecek
    }

    debugPrint('Uygulama başlatılıyor...');
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider.value(value: userService),
          ChangeNotifierProxyProvider<UserService, TaskService>(
            create: (context) => TaskService(context.read<UserService>()),
            update: (context, userService, previous) => TaskService(userService),
          ),
          ChangeNotifierProvider<ChatService>(
            create: (_) => ChatService(userService: userService),
          ),
          Provider<NotificationService>.value(value: notificationService),
          Provider<LocalStorageService>(
            create: (_) => LocalStorageService(),
            lazy: false,
          ),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Uygulama başlatma hatası: $e');
    debugPrint('Hata detayı: $stackTrace');
    
    // Hata ekranını göster
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Uygulama başlatılırken bir hata oluştu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Firebase'i temizlemeyi dene
                      try {
                        final apps = Firebase.apps;
                        for (final app in apps) {
                          await app.delete();
                        }
                        debugPrint('Firebase apps temizlendi');
                      } catch (e) {
                        debugPrint('Firebase temizleme hatası: $e');
                      }
                      main();
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İş Takip Sistemi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login-screen':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/admin-dashboard-screen':
            return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
          case '/employee-dashboard-screen':
            return MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen());
          case '/active-tasks-screen':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(builder: (_) => ActiveTasksScreen(arguments: args));
          case '/completed-tasks-screen':
            return MaterialPageRoute(builder: (_) => const CompletedTasksScreen());
          case '/create-task-screen':
            return MaterialPageRoute(builder: (_) => const CreateTaskScreen());
          case '/chat-list-screen':
            return MaterialPageRoute(builder: (_) => const ChatListScreen());
          case '/task-detail-screen':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: args['taskId']),
            );
          default:
            debugPrint('Bulunamayan rota: ${settings.name}');
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: const Text('Hata'),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sayfa bulunamadı',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'İstenen sayfa: ${settings.name}',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(_).pushReplacementNamed('/login-screen');
                        },
                        child: const Text('Giriş Sayfasına Dön'),
                      ),
                    ],
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}
