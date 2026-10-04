import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lmk/components/app_loader.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/data/local/reminder_local.dart';
import 'package:lmk/data/local/user_local.dart';
import 'package:lmk/data/models/local/local_reminder.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:lmk/data/repository/remote/create_reminder.dart';
import 'package:lmk/services/settings_service.dart';
import 'package:lmk/main.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:timezone/timezone.dart' as tz;

class SetReminderScreen extends StatefulWidget {
  const SetReminderScreen({super.key});

  @override
  State<SetReminderScreen> createState() => _SetReminderScreenState();
}

class _SetReminderScreenState extends State<SetReminderScreen> {
  final _formKey = GlobalKey<ShadFormState>();
  final _datePopoverController = ShadPopoverController();
  TimeOfDay? _selectedTime;
  DocData? _args;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= ModalRoute.of(context)!.settings.arguments as DocData;
  }

  @override
  void dispose() {
    _datePopoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = _args!;
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Set reminder',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const _LiquidBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ShadForm(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.bell,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reminder details',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ShadInputFormField(
                            id: 'Document',
                            label: const Text('Document'),
                            initialValue: args.documentType,
                            enabled: false,
                            leading: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                LucideIcons.file,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ShadDatePickerFormField(
                            id: 'Reminder Date',
                            label: const Text('Reminder date'),
                            popoverController: _datePopoverController,
                            closeOnSelection: true,
                            onChanged: (_) {
                              _datePopoverController.hide();
                            },
                            placeholder: const Text('Select reminder date'),
                            // Clamp initial value so it is never in the past
                            initialValue:
                                // () {
                                // final d =
                                _computeReminderDate(args.expiryDate),
                            //   final now = DateTime.now();
                            //   final startOfToday = DateTime(
                            //     now.year,
                            //     now.month,
                            //     now.day,
                            //   );
                            //   if (d == null) return null;
                            //   return d.isBefore(startOfToday)
                            //       ? startOfToday
                            //       : d;
                            // }(),
                            // If supported, prevent picking past dates in the UI
                            selectableDayPredicate: (day) {
                              final now = DateTime.now();
                              final startOfToday = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              return !day.isBefore(startOfToday);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Reminder date is required';
                              }
                              final now = DateTime.now();
                              final startOfToday = DateTime(
                                now.year,
                                now.month,
                                now.day,
                              );
                              if (value.isBefore(startOfToday)) {
                                return 'Reminder date cannot be in the past';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Time',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.border.withOpacity(0.35),
                                    ),
                                    color: AppColors.surface.withOpacity(0.35),
                                  ),
                                  child: Text(
                                    _selectedTime != null
                                        ? 'Selected: ${(_selectedTime!.hour % 12 == 0 ? 12 : _selectedTime!.hour % 12).toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')} ${_selectedTime!.hour >= 12 ? 'PM' : 'AM'}'
                                        : 'No time selected',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: _selectedTime != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ShadButton(
                                leading: const Icon(LucideIcons.clock),
                                child: const Text('Pick time'),
                                backgroundColor: AppColors.primary,
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                    builder: (context, child) {
                                      return ThemeController.instance.isDarkMode
                                          ? Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.dark(
                                                  primary: AppColors.primary,
                                                  onPrimary:
                                                      AppColors.background,
                                                  surface: AppColors.surface,
                                                  onSurface: AppColors.primary,
                                                ),
                                              ),
                                              child: child!,
                                            )
                                          : Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: AppColors.primary,
                                                  onPrimary:
                                                      AppColors.background,
                                                  surface: AppColors.surface,
                                                  onSurface: AppColors.primary,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedTime = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                ),
                                onPressed: () => Navigator.maybePop(context),
                                child: const Text('Back'),
                              ),
                              const Spacer(),
                              ShadButton(
                                backgroundColor: AppColors.primary,
                                onPressed: _isSubmitting ? null : () => _onSubmit(args),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: AppLoader(
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Set reminder'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
    );
      },
    );
  }

  Future<void> _onSubmit(DocData args) async {
    final isValid = _formKey.currentState!.saveAndValidate();
    if (!isValid || _selectedTime == null) {
      if (_selectedTime == null) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Time not selected'),
            description: const Text('Pick a reminder time.'),
          ),
        );
      } else {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Validation failed'),
            description: const Text('Please correct the errors.'),
          ),
        );
      }
      return;
    }

    final selectedDate =
        _formKey.currentState!.fields['Reminder Date']!.value as DateTime;
    args.reminderDate = selectedDate;
    final selectedTime = _selectedTime!;

    // If selected date is today, ensure the time is not in the past.
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final nowTime = TimeOfDay.fromDateTime(now);
    bool isBefore(TimeOfDay a, TimeOfDay b) {
      return a.hour < b.hour ||
          (a.hour == b.hour && a.minute < b.minute || a.minute == b.minute);
    }

    if (isToday && isBefore(selectedTime, nowTime)) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Invalid time'),
          description: const Text('Selected time is in the past.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final notificationId = args.documentType.hashCode.abs();

    final settings = AppSettings.instance;
    final soundId = settings.selectedSound;
    final channelId = settings.getChannelIdForSound(soundId);
    final fullScreenIntent = settings.fullScreenIntent;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Reminders (${settings.currentSoundOption.name})',
      channelDescription: 'Reminder notifications',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundId),
      priority: Priority.max,
      enableVibration: true,
      fullScreenIntent: fullScreenIntent,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    unawaited(
      flutterLocalNotificationsPlugin.zonedSchedule(
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
        payload: jsonEncode({
          'index': notificationId,
          'title': 'Reminder for ${args.documentType}',
          'documentType': args.documentType,
          'expiryDate': (args.expiryDate ?? selectedDate).toIso8601String(),
          'reminderDate': selectedDate.toIso8601String(),
          'time':
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
        }),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      ),
    );

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    String uid = user?.uid ?? '';
    if (uid.isEmpty) {
      final userLocal = await UserLocalDataSource().getUser();
      uid = userLocal?.uid ?? 'guest';
    }

    try {
      final repoLocal = ReminderLocal(
        userId: uid,
        title: 'Reminder for ${args.documentType}',
        index: notificationId,
        time:
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
        expiryDate: args.expiryDate ?? selectedDate,
        issuedDate: args.issueDate ?? DateTime.now(),
        reminderDate: args.reminderDate ?? selectedDate,
        isEnabled: true,
      );
      // 1. Immediately persist to local database for 0ms lag
      await ReminderLocalDataSource().addReminder(repoLocal);

      // 2. Instantly pop back to Home and show success feedback
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Reminder set successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).popUntil(
          (route) => route.settings.name == '/home' || route.isFirst,
        );
      }

      // 3. Asynchronously sync to cloud backend in background (never blocks UI)
      unawaited(
        _syncReminderInBackground(
          repoLocal: repoLocal,
          user: user,
          notificationId: notificationId,
          args: args,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Failed to save reminder'),
            description: Text('$e'),
          ),
        );
      }
    }
  }

  Future<void> _syncReminderInBackground({
    required ReminderLocal repoLocal,
    required User? user,
    required int notificationId,
    required DocData args,
    required DateTime selectedDate,
    required TimeOfDay selectedTime,
  }) async {
    try {
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (hasInternet && user != null) {
        final token = await user.getIdToken();
        if (token != null && token.isNotEmpty) {
          final repo = CreateReminderRepository();
          await repo.createReminder(
            token: token,
            uid: repoLocal.userId,
            title: 'Reminder for ${args.documentType}',
            time:
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
            expiryDate: args.expiryDate ?? selectedDate,
            setDate: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            ),
            isEnabled: true,
            index: notificationId,
            issuedDate: args.issueDate ?? DateTime.now(),
          );
          await ReminderLocalDataSource().updateReminder(
            repoLocal..synced = true,
          );
        }
      }
    } catch (_) {
      // Background sync fail is safe: local copy exists and SyncService will retry.
    }
  }

  DateTime? _computeReminderDate(DateTime? expiryDate) {
    if (expiryDate == null) return null;
    final expiry = DateTime.parse(
      '$expiryDate'
      'Z',
    );
    final now = DateTime.now();
    if (expiry.subtract(const Duration(days: 2)).isAfter(now)) {
      return expiry.subtract(const Duration(days: 2));
    } else if (expiry.subtract(const Duration(days: 1)).isAfter(now)) {
      return expiry.subtract(const Duration(days: 1));
    } else {
      return null;
    }
  }
}

// Glass card + background (copied style from form screen)

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: AppColors.surfaceGlass,
            border: Border.all(color: AppColors.borderSubtle, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _LiquidBackground extends StatelessWidget {
  const _LiquidBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Stack(
        children: const [
          _Glow(size: 320, color: AppColors.primary, top: -60, right: -80),
          _Glow(size: 280, color: AppColors.accent, bottom: 80, left: -60),
          _Glow(size: 200, color: Color(0xFFFF5B2E), bottom: -40, right: -40),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  final double? top, left, right, bottom;

  const _Glow({
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withAlpha(45),
              color.withAlpha(12),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}
