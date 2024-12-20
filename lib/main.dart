import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/user_service.dart';
import 'services/local_storage_service.dart';
import 'services/chat_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/create_task_screen.dart';
import 'screens/tasks/active_tasks_screen.dart';
import 'screens/tasks/completed_tasks_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/new_chat_screen.dart';
import 'screens/tasks/employee_dashboard_screen.dart';
import 'services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // timeago Türkçe dil desteği
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr');

  final userService = UserService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => userService),
        ChangeNotifierProvider(create: (_) => TaskService()),
        Provider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => LocalStorageService()),
        ChangeNotifierProvider(
          create: (_) => ChatService(userService: userService),
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
      navigatorKey: navigatorKey,
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
      initialRoute: '/login-screen',
      routes: {
        '/login-screen': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin-dashboard-screen': (context) => const AdminDashboardScreen(),
        '/create-task-screen': (context) => const CreateTaskScreen(),
        '/active-tasks-screen': (context) => const ActiveTasksScreen(),
        '/completed-tasks-screen': (context) => const CompletedTasksScreen(),
        '/chat-list-screen': (context) => const ChatListScreen(),
        '/new-chat-screen': (context) => const NewChatScreen(),
        '/tasks-screen': (context) => const EmployeeDashboardScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/tasks-screen':
            return MaterialPageRoute(
              builder: (context) => const ActiveTasksScreen(),
              settings: settings,
            );
          default:
            return null;
        }
      },
    );
  }
}
