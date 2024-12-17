import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/user_service.dart'; // Added import statement
import 'services/storage_service.dart'; // Added import statement
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/create_task_screen.dart';  // Gelişmiş görev oluşturma ekranı
// import 'screens/tasks/create_task_screen.dart';  // Eski görev oluşturma ekranı
import 'screens/tasks/active_tasks_screen.dart';
import 'screens/tasks/pending_tasks_screen.dart';
import 'screens/tasks/completed_tasks_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<UserService>(
          create: (_) => UserService(),
        ),
        ChangeNotifierProvider<TaskService>(
          create: (_) => TaskService(),
        ),
        ChangeNotifierProvider<StorageService>(
          create: (_) => StorageService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
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
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      home: const LoginScreen(),
      routes: {
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/create_task': (context) => const CreateTaskScreen(),
        '/active_tasks': (context) => const ActiveTasksScreen(),
        '/pending_tasks': (context) => const PendingTasksScreen(),
        '/completed_tasks': (context) => const CompletedTasksScreen(),
      },
    );
  }
}
