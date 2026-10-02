import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/main.dart';
import 'package:lmk/presentation/alerts/notification_detail_screen.dart';
import 'package:timezone/timezone.dart' as tz;

class Screenalert extends StatefulWidget {
  final String? payload;
  const Screenalert({super.key, this.payload});

  @override
  State<Screenalert> createState() => _ScreenalertState();
}

class _ScreenalertState extends State<Screenalert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final payloadValue = widget.payload ?? 'Document|Expiring Soon';
        final parts = payloadValue.split('|');
        final documentType = parts.isNotEmpty && parts[0].isNotEmpty
            ? parts[0]
            : 'Document Reminder';
        final expiryDate =
            parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'Due Soon';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
        children: [
          // Background ambient gradient glows
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(25),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withAlpha(20),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withAlpha(25),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(90),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(40),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.alarm_on_rounded,
                        color: AppColors.primary,
                        size: 68,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'REMINDER ALERT',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    documentType,
                    style: TextStyle(
                      fontSize: 26,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Expires / Due: $expiryDate',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.snooze_rounded, size: 22),
                      label: const Text(
                        'Snooze & Manage',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                           context,
                          MaterialPageRoute(
                            builder: (context) => NotificationDetailScreen(
                              payload: widget.payload,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      label: const Text(
                        'Dismiss',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  },
);
}
}

Future<void> scheduleReminderTest({int seconds = 10}) async {
  final now = DateTime.now();
  final scheduledTime = now.add(Duration(seconds: seconds));

  print('⏰ Current time: $now');
  print('⏰ Scheduled for: $scheduledTime');

  const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
    'reminder_channel_v2',
    'Reminders',
    description: 'Channel for reminder notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(reminderChannel);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'reminder_channel_v2',
    'Reminders',
    channelDescription: 'Channel for reminder notifications',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    999999,
    'Document Expiry',
    'Your document is expiring soon',
    tz.TZDateTime.from(scheduledTime, tz.local),
    notificationDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    payload: 'Passport|2026-12-31',
  );

  print('✅ Test reminder scheduled for $scheduledTime');
}
