import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/report_service.dart';
import 'services/meeting_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/task_list_screen.dart';
import 'screens/report_list_screen.dart';
import 'screens/meeting_list_screen.dart';
import 'screens/meeting_detail_screen.dart';
import 'screens/create_meeting_screen.dart';
import 'screens/edit_meeting_screen.dart';
import 'constants/app_theme.dart';
import 'constants/app_constants.dart';
import 'models/user_model.dart';
import 'models/meeting_model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/search_screen.dart';
import 'services/export_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Toplantı kararları için arka plan görevi başlat
  final meetingService = MeetingService();
  meetingService.startOverdueDecisionsCheck();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => TaskService()),
        Provider(create: (_) => NotificationService()),
        Provider(create: (_) => StorageService()),
        Provider(create: (_) => ReportService()),
        Provider(create: (_) => MeetingService()),
        Provider(create: (_) => MeetingReportService()),
        Provider(create: (_) => CalendarService()),
        Provider(create: (_) => SearchService()),
        Provider(create: (_) => ExportService()),
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
      locale: const Locale('tr', 'TR'),
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/create_task': (context) => const CreateTaskScreen(),
        '/task_detail': (context) => TaskDetailScreen(
          taskId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/create_meeting': (context) => const CreateMeetingScreen(),
        '/meeting_detail': (context) => MeetingDetailScreen(
          meetingId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/edit_meeting': (context) => EditMeetingScreen(
          meetingId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/create_meeting_report': (context) => const CreateMeetingReportScreen(),
        '/meeting_report_detail': (context) => MeetingReportDetailScreen(
          reportId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        '/meeting_report_list': (context) => const MeetingReportListScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/search': (context) => const SearchScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/meetings/detail') {
          final meeting = settings.arguments as MeetingModel;
          return MaterialPageRoute(
            builder: (context) => MeetingDetailScreen(meeting: meeting),
          );
        }
        if (settings.name == '/meetings/edit') {
          final meeting = settings.arguments as MeetingModel;
          return MaterialPageRoute(
            builder: (context) => EditMeetingScreen(meeting: meeting),
          );
        }
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserModel(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userModel = snapshot.data;
        if (userModel == null) {
          return const LoginScreen();
        }

        if (userModel.role == AppConstants.roleAdmin) {
          return const AdminDashboard();
        }

        return const HomeScreen();
      },
    );
  }
}
