import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lmk/auth/screen/sign-in-page.dart';
import 'package:lmk/auth/screen/wrapper.dart';
import 'package:lmk/auth/services/google_auth.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:lmk/main/home.dart';
import 'package:lmk/presentation/alerts/screenAlert.dart';
import 'package:lmk/presentation/dataFrom.dart';
import 'package:lmk/presentation/setReminder.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'launch/launch.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();
  tz.initializeTimeZones();
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
      if (response.payload != null) {
        // open full screen when tapped
        runApp(Screenalert(payload: response.payload));
      }
    },
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final String? payload;
  const MyApp({super.key, this.payload});

  @override
  Widget build(BuildContext context) {
    return payload != null
        ? Screenalert(payload: payload!)
        : ShadApp(
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
