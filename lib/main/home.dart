import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lmk/auth/services/google_auth.dart';
import 'package:lmk/components/buildCard.dart';
import 'package:lmk/components/floatActionButton.dart';
import 'package:lmk/data/local/reminder_local.dart';
import 'package:lmk/data/local/user_local.dart';
import 'package:lmk/data/models/local/local_user.dart';
import 'package:lmk/data/models/local/local_user.dart' as model;
import 'package:lmk/data/models/post/post.dart';
import 'package:lmk/data/repository/remote/get_reminders.dart';
import 'package:lmk/data/repository/remote/post_repo.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lmk/components/avatar_card.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

// ... (keep the reminders list as is)

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<Reminder> reminders = [];
  String? token;
  StreamSubscription<InternetStatus>? _connectionSubscription;
  bool _isOnline = true;
  model.UserLocal? _user;
  String name = 'User';
  String photoUrl =
      "https://img.icons8.com/?size=100&id=85120&format=png&color=000000";

  @override
  void initState() {
    super.initState();
    _initToken();
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
    _load();
    //start listening to connectivity changes
    _subscribeToConnection();
  }

  Future<void> _load() async {
    _user = await UserLocalDataSource().getUser();
    if (!mounted) return;
    setState(() {
      name = _user?.name ?? "User";
      photoUrl =
          _user?.photoUrl ??
          "https://img.icons8.com/?size=100&id=85120&format=png&color=000000";
    });
  }

  void _subscribeToConnection() {
    // set initial state
    InternetConnection().hasInternetAccess.then((online) {
      if (mounted) setState(() => _isOnline = online);
    });

    _connectionSubscription = InternetConnection().onStatusChange.listen((
      InternetStatus status,
    ) {
      final online = status == InternetStatus.connected;
      if (!mounted) return;

      if (online != _isOnline) {
        setState(() => _isOnline = online);
        // Optional: toast on change
        if (!online) {
          ShadToaster.of(context).show(
            ShadToast.destructive(
              title: const Text('You are offline'),
              description: const Text('Some actions will be unavailable.'),
            ),
          );
        }
      }
    });
  }

  Future<void> _initToken() async {
    token = await FirebaseAuth.instance.currentUser?.getIdToken();
    await _loadReminders();
  }

  Future<void> _loadReminders() async {
    print("Fetching reminders with token: $token");
    ReminderLocalDataSource localDataSource = ReminderLocalDataSource();
    final localReminders = await localDataSource.getReminders(
      FirebaseAuth.instance.currentUser!.uid,
    );
    setState(() {
      reminders = localReminders
          .map(
            (localReminder) => Reminder(
              userId: localReminder.userId,
              id: localReminder.id,
              title: localReminder.title,
              expiry_date: localReminder.expiryDate as DateTime,
              reminderDate: localReminder.reminderDate as DateTime,
              time: _parseTimeOfDay(localReminder.time as String),
              index: localReminder.index as int,
              isEnabled: localReminder.isEnabled as bool,
              issue_date: localReminder.issuedDate,
            ),
          )
          .toList();
    });
    // print("Loaded ${reminders.length} reminders from local storage.");
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  @override
  void dispose() {
    _controller.dispose();
    _connectionSubscription?.cancel();
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

  void showOfflineToast() {
    final theme = ShadTheme.of(context);
    ShadToaster.of(context).show(
      ShadToast.destructive(
        title: const Text('You are offline'),
        description: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(LucideIcons.squarePen, size: 16),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Some actions will be unavailable. Use Manual entry.',
              ),
            ),
          ],
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

  // Helper: combine reminderDate and time for comparisons/formatting
  DateTime _combineReminderDateTime(Reminder r) {
    final date = r.reminderDate ?? r.expiry_date;
    return DateTime(
      date.year,
      date.month,
      date.day,
      r.time.hour,
      r.time.minute,
    );
  }

  // Helper: find the next upcoming reminder (enabled and in the future)
  MapEntry<Reminder, DateTime>? _upcomingReminder() {
    final now = DateTime.now();
    final entries = reminders
        .where((r) => r.isEnabled)
        .map((r) => MapEntry(r, _combineReminderDateTime(r)))
        .where((e) => e.value.isAfter(now))
        .toList();
    if (entries.isEmpty) return null;
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries.first;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcomingReminder();

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        !_isOnline
                            ? IconButton(
                                tooltip: _isOnline ? 'Online' : 'Offline',
                                onPressed: () {},
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  transitionBuilder: (child, anim) =>
                                      FadeTransition(
                                        opacity: anim,
                                        child: ScaleTransition(
                                          scale: anim,
                                          child: child,
                                        ),
                                      ),
                                  child: Icon(
                                    Icons.link_off,
                                    key: ValueKey<bool>(_isOnline),
                                    color: AppColors.error,
                                  ),
                                ),
                              )
                            : const SizedBox(height: 48),
                      ],
                    ),

                    // const SizedBox(height: 22),
                    Transform.translate(
                      offset: const Offset(0, -26),
                      child: Column(
                        children: [
                          AvatarCard(
                            name: name,
                            imageUrl: photoUrl,
                            onTap: () {
                              AuthMethods().signOut();
                              Navigator.pushReplacementNamed(
                                context,
                                '/signIn',
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              top: 16.0,
                            ),
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
                          if (upcoming != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 20.0,
                                top: 6.0,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.alarm, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Next reminder: ${_formatDate(upcoming.value)} at ${upcoming.key.time.format(context)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // const SizedBox(height: 22),
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
                offset: const Offset(0, -16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Soft ambient glows
                    IgnorePointer(
                      ignoring: true,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 100,
                            right: -60,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.18),
                                    AppColors.primary.withOpacity(0.06),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -40,
                            left: -30,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.cardSage.withOpacity(0.18),
                                    AppColors.cardSage.withOpacity(0.06),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -30,
                            right: -10,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.cardCoral.withOpacity(0.18),
                                    AppColors.cardCoral.withOpacity(0.06),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -50,
                            left: -40,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.cardAmber.withOpacity(0.18),
                                    AppColors.cardAmber.withOpacity(0.06),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Glassy container for cards (matches GlassCard style)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.surface.withOpacity(0.32),
                                AppColors.cardMist.withOpacity(0.25),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.border.withOpacity(0.3),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 24,
                                offset: Offset(0, 12),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: BuildCard(
                            reminders: reminders,
                            onDelete: (int id) {
                              setState(() {
                                reminders.removeWhere((r) => r.id == id);
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: GlassExpandableFab(
        actions: [
          FabAction(
            icon: LucideIcons.images,
            // label: 'Medicine',
            onTap: () async {
              final hasPermission = await checkNotificationPermission();
              if (!hasPermission) {
                showPermissionDeniedToast();
                return;
              }
              if (!_isOnline) {
                showOfflineToast();
                return;
              }
              await picker("gallery");
            },
          ),

          FabAction(
            icon: LucideIcons.camera,
            // label: 'Stats',
            onTap: () async {
              final hasPermission = await checkNotificationPermission();
              if (!hasPermission) {
                showPermissionDeniedToast();
                return;
              }
              if (!_isOnline) {
                showOfflineToast();
                return;
              }
              await picker("camera");
            },
          ),
          FabAction(
            icon: LucideIcons.squarePen,
            onTap: () async {
              final hasPermission = await checkNotificationPermission();
              if (!hasPermission) {
                showPermissionDeniedToast();
                return;
              }
              DocData docData = DocData();
              Navigator.pushNamed(context, '/docForm', arguments: docData);
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
        imageQuality: 60, // 0-100 (lower = smaller)
      );

      if (!mounted) return;

      if (image == null) {
        buildErrorToast(context);
        return;
      }
      final img = image.path;
      // final byteSize = await image.length();
      // print(
      //   'Picked image size: $byteSize bytes (${(byteSize / 1024).toStringAsFixed(2)} KB)',
      // );

      PostRepository postRepo = PostRepository();
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

      DocData? docData = await postRepo.fetchDocData(img);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (docData == null) {
        if (!mounted) return;
        buildErrorToast(context);
        return;
      }
      Navigator.pushNamed(context, '/docForm', arguments: docData);
    } catch (e) {
      print("Error picking image: $e");
      if (!mounted) return;
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
