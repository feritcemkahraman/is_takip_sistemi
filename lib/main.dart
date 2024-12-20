import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/task_service.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => TaskService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProxyProvider<AuthService, UserService>(
          create: (_) => UserService(),
          update: (_, auth, __) => UserService(),
        ),
        ChangeNotifierProxyProvider<UserService, TaskService>(
          create: (_) => TaskService(),
          update: (_, userService, __) => TaskService(),
        ),
        ProxyProvider<UserService, ChatService>(
          update: (_, userService, __) => ChatService(userService: userService),
        ),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: MaterialApp(
        title: 'İş Takip Sistemi',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/login',
        onGenerateRoute: (settings) {
          if (settings.name == '/task-detail') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: args['task']),
            );
          }
          return null;
        },
        routes: {
          '/login': (context) => const LoginScreen(),
          '/admin-dashboard': (context) => const AdminDashboardScreen(),
          '/employee-dashboard': (context) => const EmployeeDashboardScreen(),
          '/active-tasks': (context) => const ActiveTasksScreen(),
          '/completed-tasks': (context) => const CompletedTasksScreen(),
          '/create-task': (context) => const CreateTaskScreen(),
          '/chat-list': (context) => const ChatListScreen(),
        },
      ),
    );
  }
}
