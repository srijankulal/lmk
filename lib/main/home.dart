import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:lmk/auth/services/google_auth.dart';
import 'package:lmk/components/buildCard.dart';
import 'package:lmk/components/floatActionButton.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:lmk/data/repository/post_repo.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lmk/components/avatar_card.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/presentation/alerts/screenAlert.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

// ... (keep the reminders list as is)

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  static final List<Color> cardColors = [
    AppColors.cardSage,
    AppColors.cardClay,
    AppColors.cardAmber,
    AppColors.cardCoral,
  ];
  late AnimationController _controller;
  late Animation<double> _animation;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),

      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> checkNotificationPermission() async {
    final bool? granted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    return granted ?? false;
  }

  List<Reminder> reminders = [
    //... (keep the reminders list as is)
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
    Reminder(
      title: 'Passport Renewal',
      expiry_date: DateTime(2024, 11, 20),
      time: TimeOfDay(hour: 10, minute: 0),
      color: cardColors[Random().nextInt(cardColors.length)],
    ),
  ];

  void showPermissionDeniedToast() {
    final theme = ShadTheme.of(context);
    ShadToaster.of(context).show(
      ShadToast.destructive(
        title: const Text('Notifications disabled'),
        description: const Text(
          'Enable notifications in Settings to receive reminders.',
        ),
        action: ShadButton.destructive(
          decoration: ShadDecoration(
            border: ShadBorder.all(
              color: theme.colorScheme.destructiveForeground,
              width: 1,
            ),
          ),
          onPressed: () {
            ShadToaster.of(context).hide();
          },
          child: const Text('Dismiss'),
        ),
      ),
    );
  }

  Future<void> scheduleReminderTest() async {
    final hasPermission = await checkNotificationPermission();
    if (!hasPermission) {
      showPermissionDeniedToast();
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    // Simple immediate notification to verify permission flow.
    await flutterLocalNotificationsPlugin.show(
      0,
      'Notifications enabled',
      'You will receive reminders.',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String name = "User";
    String photoUrl = "";

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/signIn');
      });
      // Return a loading indicator or an empty container while navigating.
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: SpinKitFadingCube(color: AppColors.primary, size: 25.0)),
      );
    } else {
      name = user.displayName ?? "User";
      photoUrl = user.photoURL ?? "";
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ... (keep the top section as is)
            ScaleTransition(
              scale: _animation,
              child: Container(
                color: AppColors.surfaceDark,
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                    AvatarCard(
                      name: name,
                      imageUrl: photoUrl,
                      onTap: () {
                        AuthMethods().signOut();
                        Navigator.pushReplacementNamed(context, '/signIn');
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, top: 16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Your stuffs.",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // ShadButton(
                    //   backgroundColor: AppColors.primary,
                    //   child: const Text('Add New Document'),
                    //   onPressed: () async {
                    //     await scheduleReminderTest();
                    //   },
                    // ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.all(Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: BuildCard(reminders: reminders),
                ),
              ),
            ),
            const SizedBox(height: 44),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: GlassExpandableFab(
        actions: [
          FabAction(
            icon: Icons.photo_library_rounded,
            // label: 'Medicine',
            onTap: () async {
              final hasPermission = await checkNotificationPermission();
              if (!hasPermission) {
                showPermissionDeniedToast();
                return;
              }
              await picker("gallery");
            },
          ),

          FabAction(
            icon: Icons.camera_alt_rounded,
            // label: 'Stats',
            onTap: () async {
              final hasPermission = await checkNotificationPermission();
              if (!hasPermission) {
                showPermissionDeniedToast();
                return;
              }
              await picker("camera");
            },
          ),
        ],
      ),
    );
  }

  Future<void> picker(String source) async {
    // ... (keep the rest of the picker method as is)
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source == "camera" ? ImageSource.camera : ImageSource.gallery,
      );

      if (image == null) {
        buildErrorToast(context);
        return;
      }
      final img = image.path;
      PostRepository postrepo = PostRepository();
      final loading = SpinKitFadingCube(color: AppColors.primary, size: 25.0);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: Card(
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        loading,
                        const SizedBox(height: 16),
                        Text(
                          'Processing image...',
                          style: TextStyle(color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      DocData? docData = await postrepo.fetchDocData(img);

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (docData == null) {
        buildErrorToast(context);
        return;
      }
      Navigator.pushNamed(context, '/docForm', arguments: docData);
    } catch (e) {
      print("Error picking image: $e");
      buildErrorToast(context, source);
    }
  }

  void buildErrorToast(BuildContext context, [String which = '']) {
    // ... (keep as is)
    final theme = ShadTheme.of(context);
    ShadToaster.of(context).show(
      ShadToast.destructive(
        title: Text(
          which.isNotEmpty
              ? 'Failed to pick from $which'
              : 'Uh oh! Something went wrong',
        ),
        description: Text(
          which.isNotEmpty
              ? 'There was a problem accessing your $which'
              : 'No image was selected',
        ),
        action: ShadButton.destructive(
          decoration: ShadDecoration(
            border: ShadBorder.all(
              color: theme.colorScheme.destructiveForeground,
              width: 1,
            ),
          ),
          onPressed: which.isNotEmpty
              ? () async {
                  ShadToaster.of(context).hide();
                  await picker(which);
                }
              : () {
                  ShadToaster.of(context).hide();
                },
          child: Text(which.isNotEmpty ? 'Try again' : 'Dismiss'),
        ),
      ),
    );
  }
}
