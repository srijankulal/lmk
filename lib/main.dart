import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lmk/auth/screen/sign-in-page.dart';
import 'package:lmk/auth/screen/wrapper.dart';
import 'package:lmk/data/repository/local/isar_service.dart';
import 'package:lmk/main/home.dart';
import 'package:lmk/presentation/alerts/notification_detail_screen.dart';
import 'package:lmk/presentation/alerts/screenAlert.dart';
import 'package:lmk/presentation/dataFrom.dart';
import 'package:lmk/presentation/setReminder.dart';
import 'package:lmk/presentation/start_screen.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/services/settings_service.dart';
import 'package:lmk/services/update_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wiredash/wiredash.dart';
import 'package:lmk/services/wiredash_service.dart';
import 'launch/launch.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void handleNotificationPayload(String? payload) {
  if (payload == null || payload.isEmpty) return;
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => NotificationDetailScreen(payload: payload),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Automatic crash capture and bug reporting via Wiredash
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    WiredashService.instance.handleCrash(
      details.exception,
      details.stack,
      context: navigatorKey.currentContext,
    );
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    WiredashService.instance.handleCrash(
      error,
      stack,
      context: navigatorKey.currentContext,
    );
    return false;
  };

  await Firebase.initializeApp();
  tz.initializeTimeZones();
  await AppSettings.instance.init();
  await UpdateService.instance.init();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  const AndroidInitializationSettings initAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await androidPlugin?.requestNotificationsPermission();

  // Create primary fallback channel
  const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
    'reminder_channel_v2',
    'Reminders (Default)',
    description: 'Channel for reminder notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );
  await androidPlugin?.createNotificationChannel(reminderChannel);

  // Register dedicated notification channels for each custom sound option
  for (final sound in AppSettings.availableSounds) {
    final soundChannel = AndroidNotificationChannel(
      AppSettings.instance.getChannelIdForSound(sound.id),
      'Reminders - ${sound.name}',
      description: 'Channel with ${sound.name} alert sound',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(sound.id),
      enableVibration: true,
      showBadge: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
    await androidPlugin?.createNotificationChannel(soundChannel);
  }

  const InitializationSettings initSettings = InitializationSettings(
    android: initAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) async {
      debugPrint("Notification clicked with payload: ${response.payload}");
      if (response.payload != null) {
        await prefs.setString('payload', response.payload!);
        await prefs.setString('pendingNotificationPayload', response.payload!);
        handleNotificationPayload(response.payload);
      }
    },
  );
  await _dbSetup();
  await ThemeController.instance.init();

  runApp(MyApp(seenOnboarding: seenOnboarding));

  // If app was launched directly by tapping notification or via full-screen intent
  final launchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    final payload = launchDetails?.notificationResponse?.payload;
    if (payload != null && payload.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationPayload(payload);
      });
    }
  }
}

Future<void> _dbSetup() async {
  // Any database setup code can go here
  await IsarService().db;
}

class MyApp extends StatefulWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeController.instance,
        WiredashService.instance,
      ]),
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode;
        return Wiredash(
          projectId: WiredashService.projectId,
          secret: WiredashService.secret,
          collectMetaData: (metaData) {
            if (WiredashService.instance.lastError != null) {
              metaData.custom['last_crash_error'] =
                  WiredashService.instance.lastError!;
            }
            if (WiredashService.instance.lastStackTrace != null) {
              metaData.custom['last_crash_stack'] =
                  WiredashService.instance.lastStackTrace!;
            }
            if (WiredashService.instance.lastErrorTime != null) {
              metaData.custom['crash_timestamp'] =
                  WiredashService.instance.lastErrorTime!.toIso8601String();
            }
            return metaData;
          },
          theme: WiredashThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primaryColor: AppColors.primary,
            secondaryColor: AppColors.accent,
          ),
          child: ShadApp(
            navigatorKey: navigatorKey,
            theme: ShadThemeData(
              brightness: Brightness.light,
              colorScheme: const ShadSlateColorScheme.light(
                primary: AppColors.primary,
                background: Color(0xFFF1F2E8),
              ),
            ),
            darkTheme: ShadThemeData(
              brightness: Brightness.dark,
              colorScheme: const ShadSlateColorScheme.dark(
                primary: AppColors.primary,
                background: Color(0xFF101516),
              ),
            ),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            initialRoute: widget.seenOnboarding ? '/' : '/start',
            routes: {
              '/': (context) => AuthWrapper(),
              '/start': (context) => const StartScreen(),
              '/signIn': (context) => const SignInPage(),
              '/launch': (context) => const Launch(),
              '/home': (context) => const Home(),
              '/docForm': (context) => DocForm(),
              '/setReminder': (context) => const SetReminderScreen(),
              '/screenAlert': (context) => const Screenalert(),
              '/notificationDetail': (context) =>
                  const NotificationDetailScreen(),
            },
          ),
        );
      },
    );
  }
}
