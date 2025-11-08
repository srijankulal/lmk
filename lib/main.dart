import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lmk/auth/screen/sign-in-page.dart';
import 'package:lmk/auth/screen/wrapper.dart';
import 'package:lmk/auth/services/google_auth.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:lmk/data/repository/local/isar_service.dart';
import 'package:lmk/main/home.dart';
import 'package:lmk/presentation/alerts/screenAlert.dart';
import 'package:lmk/presentation/dataFrom.dart';
import 'package:lmk/presentation/setReminder.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'launch/launch.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
// ...existing code...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  const AndroidInitializationSettings initAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  const InitializationSettings initSettings = InitializationSettings(
    android: initAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) async {
      print("Notification clicked with payload: ${response.payload}");
      if (response.payload != null) {
        print('Notification payload: ${response.payload}');
        await prefs.setString('payload', response.payload!);
        // Store the payload for the app to handle
        await prefs.setString('pendingNotificationPayload', response.payload!);
      }
    },
  );
  await _dbSetup();

  runApp(const MyApp());
}

Future<void> _dbSetup() async {
  // Any database setup code can go here
  await IsarService().db;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/signIn': (context) => const SignInPage(),
        '/launch': (context) => const Launch(),
        '/home': (context) => const Home(),
        '/docForm': (context) => DocForm(),
        '/setReminder': (context) => const SetReminderScreen(),
      },
    );
  }
}
