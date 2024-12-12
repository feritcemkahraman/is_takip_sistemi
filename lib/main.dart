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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Toplantı kararları için arka plan görevi başlat
  final meetingService = MeetingService();
  meetingService.startOverdueDecisionsCheck();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _reminderTimer;
  final _meetingService = MeetingService();

  @override
  void initState() {
    super.initState();
    _startReminderTimer();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  void _startReminderTimer() {
    // Her 5 dakikada bir hatırlatmaları kontrol et
    _reminderTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _meetingService.checkUpcomingReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<TaskService>(
          create: (_) => TaskService(),
        ),
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<ReportService>(
          create: (_) => ReportService(),
        ),
        Provider<MeetingService>(
          create: (_) => _meetingService,
        ),
        StreamProvider(
          create: (context) => context.read<AuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'İş Takip Sistemi',
        theme: AppTheme.lightTheme,
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/admin': (context) => const AdminDashboard(),
          '/tasks': (context) => const TaskListScreen(),
          '/reports': (context) => const ReportListScreen(),
          '/meetings': (context) => const MeetingListScreen(),
          '/meetings/create': (context) => const CreateMeetingScreen(),
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
      ),
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
