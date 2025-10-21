import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lmk/main.dart';
import 'package:timezone/timezone.dart' as tz;

class Screenalert extends StatefulWidget {
  final String? payload;
  const Screenalert({super.key, this.payload});

  @override
  State<Screenalert> createState() => _ScreenalertState();
}

class _ScreenalertState extends State<Screenalert> {
  String get payload =>
      widget.payload ?? 'Reminder|It\'s time for your scheduled reminder!';
  @override
  Widget build(BuildContext context) {
    final parts = payload.split('|');
    final title = parts.isNotEmpty ? parts[0] : 'Reminder';
    final body = parts.length > 1 ? parts[1] : '';

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.alarm, color: Colors.orangeAccent, size: 80),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // ElevatedButton.icon(
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.greenAccent[400],
                //     minimumSize: const Size(double.infinity, 60),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(18),
                //     ),
                //   ),
                //   icon: const Icon(Icons.snooze),
                //   label: const Text(
                //     'Snooze 5 min',
                //     style: TextStyle(color: Colors.black, fontSize: 18),
                //   ),
                //   onPressed: () async {
                //     final now = DateTime.now().add(const Duration(minutes: 5));
                //     await ;
                //     Navigator.pop(context);
                //   },
                // ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent[400],
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text(
                    'Dismiss',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> scheduleReminderTest() async {
  final now = DateTime.now();
  final scheduledTime = now.add(Duration(seconds: 15)); // Add 15 seconds delay

  print('⏰ Current time: $now');
  print('⏰ Scheduled for: $scheduledTime');

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'reminder_channel',
    'Reminders',
    channelDescription: 'Channel for reminder notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Test Reminder',
    'This is a test reminder scheduled 15 seconds ago',
    tz.TZDateTime.from(scheduledTime, tz.local),
    notificationDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );

  print('✅ Dummy reminder scheduled for $scheduledTime');
}
