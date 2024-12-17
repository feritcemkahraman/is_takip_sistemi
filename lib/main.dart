import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/tasks/create_task_screen.dart';
import 'screens/tasks/active_tasks_screen.dart';
import 'screens/tasks/pending_tasks_screen.dart';
import 'screens/tasks/completed_tasks_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<TaskService>(create: (_) => TaskService()),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
