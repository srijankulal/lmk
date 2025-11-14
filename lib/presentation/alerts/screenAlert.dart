// ignore: file_names
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
  String get payload => widget.payload ?? 'Document|No expiry date set';

  @override
  Widget build(BuildContext context) {
    final payloadValue = payload;
    final parts = payloadValue.split('|');
    final documentType = parts.isNotEmpty ? parts[0] : 'Document';
    final expiryDate = parts.length > 1 ? parts[1] : 'No expiry date';

    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description, color: Colors.orangeAccent, size: 80),
                const SizedBox(height: 20),
                Text(
                  documentType,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Expires on: $expiryDate',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
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
  final scheduledTime = now.add(Duration(seconds: 15));

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
    'Document Expiry',
    'Your document is expiring soon',
    tz.TZDateTime.from(scheduledTime, tz.local),
    notificationDetails,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    payload: 'Passport|2024-12-31', // Example payload
  );

  print('✅ Reminder scheduled for $scheduledTime');
}
