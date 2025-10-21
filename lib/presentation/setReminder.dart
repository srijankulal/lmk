import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:lmk/data/repository/create_reminder.dart';
import 'package:lmk/main.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:timezone/timezone.dart' as tz;

class SetReminderScreen extends StatefulWidget {
  const SetReminderScreen({super.key});

  @override
  State<SetReminderScreen> createState() => _SetReminderScreenState();
}

class _SetReminderScreenState extends State<SetReminderScreen> {
  TimeOfDay? _selectedTime;
  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<ShadFormState>();
    final args = ModalRoute.of(context)!.settings.arguments as DocData;
    return Scaffold(
      appBar: AppBar(title: const Text('Set Reminder')),
      body: Center(
        child: ShadForm(
          key: formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShadDatePickerFormField(
                    id: 'Reminder Date',
                    label: const Text('Reminder Date'),
                    closeOnSelection: true,
                    placeholder: const Text('Select Reminder Date'),
                    initialValue: SetDate(args.expiryDate),
                    validator: (value) {
                      if (value == null) {
                        return 'Reminder Date is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Select Time'),
                  ShadButton(
                    leading: const Icon(Icons.access_time),
                    backgroundColor: AppColors.primary,
                    child: const Text('Pick Time'),
                    onPressed: () async {
                      final TimeOfDay? selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: AppColors.background,
                                surface: AppColors.surface,
                                onSurface: AppColors.primary,
                              ),
                              timePickerTheme: TimePickerThemeData(
                                backgroundColor: AppColors.background,
                                dialBackgroundColor: AppColors.primary
                                    .withAlpha(10),
                                dialHandColor: AppColors.primary,
                                hourMinuteTextColor: AppColors.textSecondary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      print('Selected time: $selectedTime');
                      if (selectedTime != null) {
                        setState(() {
                          _selectedTime = selectedTime;
                        });
                      }
                    },
                  ),
                  // ShadTimePickerFormField.period(
                  //   label: const Text('Pick a time'),
                  //   onChanged: print,
                  //   description: const Text(
                  //     'The time of the day you want to be reminded',
                  //   ),
                  //   validator: (v) => v == null ? 'A time is required' : null,
                  // ),
                  const SizedBox(height: 16),
                  ShadButton(
                    child: const Text('Set Reminder'),
                    onPressed: () async {
                      print(
                        'selected date: ${formKey.currentState!.fields['Reminder Date']!.value}',
                      );
                      print('selected time: $_selectedTime');
                      if (formKey.currentState!.saveAndValidate() &&
                          _selectedTime != null) {
                        final selectedTime = _selectedTime!;
                        final selectedDate = formKey
                            .currentState!
                            .fields['Reminder Date']!
                            .value;
                        const androidDetails = AndroidNotificationDetails(
                          'reminder_channel',
                          'Reminders',
                          channelDescription: 'Reminder notifications',
                          importance: Importance.defaultImportance,
                          priority: Priority.defaultPriority,
                        );
                        const notificationDetails = NotificationDetails(
                          android: androidDetails,
                        );

                        // Simple immediate notification to verify permission flow.
                        final notificationId = args.documentType.hashCode.abs();
                        await flutterLocalNotificationsPlugin.zonedSchedule(
                          notificationId,
                          'Reminder for ${args.documentType}',
                          'This is your reminder!',
                          tz.TZDateTime.from(
                            DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            ),
                            tz.local,
                          ),
                          notificationDetails,
                          androidScheduleMode:
                              AndroidScheduleMode.exactAllowWhileIdle,
                        );
                        print(
                          'validation succeeded with ${formKey.currentState!.value}',
                        );
                        if (mounted) {
                          final user = FirebaseAuth.instance.currentUser;
                          final uid = user != null ? user.uid : '';
                          final String? idTokenFirebase = await user
                              ?.getIdToken();
                          // Call API to create reminder
                          final reminderRepository = CreateReminderRepository();
                          try {
                            await reminderRepository.createReminder(
                              token: idTokenFirebase ?? '',
                              uid: uid,
                              title: 'Reminder for ${args.documentType}',
                              time:
                                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              expiryDate: args.expiryDate as DateTime,
                              setDate: DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              ),
                              isEnabled: true,
                              index: notificationId,
                            );
                          } catch (e) {
                            print('Failed to save reminder to API: $e');
                            if (mounted) {
                              ShadToaster.of(context).show(
                                ShadToast(
                                  title: Text('Failed to save reminder: $e'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 2),
                                  action: ShadButton(
                                    child: Text('OK'),
                                    onPressed: () =>
                                        ShadToaster.of(context).hide(),
                                  ),
                                ),
                              );
                            }
                          }
                          ShadToaster.of(context).show(
                            ShadToast(
                              title: const Text('Reminder set successfully!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.pushNamed(context, '/home');
                        }
                      } else {
                        print('validation failed');
                        if (_selectedTime == null && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select a time.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  DateTime? SetDate(DateTime? expiryDate) {
    DateTime expiry = DateTime.parse('${expiryDate}Z');
    DateTime reminderDate = expiry.subtract(const Duration(days: 2));
    return reminderDate;
  }
}
