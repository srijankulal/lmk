import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/data/local/reminder_local.dart';
import 'package:lmk/data/models/local/local_reminder.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:lmk/data/repository/remote/create_reminder.dart';
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
  TimeOfDay? _selectedTime;
  DocData? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args ??= ModalRoute.of(context)!.settings.arguments as DocData;
  }

  @override
  Widget build(BuildContext context) {
    final args = _args!;
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Set reminder'),
        backgroundColor: AppColors.surfaceDark.withAlpha(38),
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: const SizedBox.expand(),
          ),
        ),
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
                            closeOnSelection: true,
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
                                      return theme.brightness == Brightness.dark
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
                                child: const Text('Set reminder'),
                                backgroundColor: AppColors.primary,
                                onPressed: () => _onSubmit(args),
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

    final notificationId = args.documentType.hashCode.abs();

    final androidDetails = AndroidNotificationDetails(
      'reminder_channel $notificationId',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification'),
      priority: Priority.high,
      enableVibration: true,
      category: AndroidNotificationCategory.event,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

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
      payload: '${args.documentType}|${args.expiryDate}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    try {
      final repoLocal = ReminderLocal(
        userId: uid,
        title: 'Reminder for ${args.documentType}',
        index: notificationId,
        time:
            '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
        expiryDate: args.expiryDate as DateTime,
        issuedDate: args.issueDate ?? DateTime.now(),
        reminderDate: args.reminderDate as DateTime,
      );
      // print('reminder data ${repo.reminderDate}');
      // print('Saving local reminder: $repo');
      await ReminderLocalDataSource().addReminder(repoLocal);
      final hasInternet = await InternetConnection().hasInternetAccess;
      if (hasInternet) {
        final token = await user?.getIdToken() ?? '';
        final repo = CreateReminderRepository();
        await repo.createReminder(
          token: token,
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
          issuedDate: args.issueDate ?? DateTime.now(),
        );
        await ReminderLocalDataSource().updateReminder(
          repoLocal..synced = true,
        );
      }
      // await repo.createReminder(
      //   token: token,
      //   uid: uid,
      //   title: 'Reminder for ${args.documentType}',
      //   time:
      //       '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
      //   expiryDate: args.expiryDate as DateTime,
      //   setDate: DateTime(
      //     selectedDate.year,
      //     selectedDate.month,
      //     selectedDate.day,
      //     selectedTime.hour,
      //     selectedTime.minute,
      //   ),
      //   isEnabled: true,
      //   index: notificationId,
      //   issuedDate: args.issueDate ?? DateTime.now(),
      // );

      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('Reminder set successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pushNamed(context, '/home');
    } catch (e) {
      print('Error saving reminder: $e');
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Failed to save reminder'),
          description: Text('$e'),
        ),
      );
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
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withOpacity(0.32),
                AppColors.cardMist.withOpacity(0.25),
              ],
            ),
            border: Border.all(color: AppColors.border.withOpacity(0.3)),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 24,
                offset: Offset(0, 12),
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _LiquidBackground extends StatelessWidget {
  const _LiquidBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.background,
            AppColors.cardMist,
            AppColors.cardClay.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: const [
          Positioned.fill(child: IgnorePointer(child: _AuroraField())),
          Positioned.fill(child: IgnorePointer(child: _VibrantBands())),
          Positioned.fill(child: IgnorePointer(child: _EdgeSweep())),
          _Glow(size: 260, color: AppColors.primary, top: 120, right: -80),
          _Glow(size: 220, color: AppColors.cardSage, top: -60, left: -40),
          _Glow(size: 180, color: AppColors.cardCoral, bottom: -40, right: -20),
          _Glow(size: 200, color: AppColors.cardAmber, bottom: -60, left: -50),
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
              color.withOpacity(0.22),
              color.withOpacity(0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

class _AuroraField extends StatelessWidget {
  const _AuroraField();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _AuroraPainter());
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardMist.withOpacity(0.18),
            AppColors.background.withOpacity(0.12),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    const layers = 12;
    final baseY = size.height * 0.14;
    const gap = 24.0;

    for (int i = 0; i < layers; i++) {
      final t = i / (layers - 1);
      final y = baseY + i * gap;

      Path band = Path()
        ..moveTo(-40, y)
        ..cubicTo(
          size.width * 0.25,
          y - 28 - i * 1.2,
          size.width * 0.55,
          y + 34 + i * 1.8,
          size.width + 40,
          y - 10,
        )
        ..lineTo(size.width + 40, size.height + 40)
        ..lineTo(-40, size.height + 40)
        ..close();

      final warmMix = Color.lerp(
        AppColors.cardCoral,
        AppColors.cardAmber,
        0.35 + 0.25 * t,
      )!;
      final coolMix = Color.lerp(
        AppColors.accent,
        AppColors.cardSage,
        0.35 + 0.4 * t,
      )!;
      final c1 = Color.lerp(
        coolMix,
        warmMix,
        0.25,
      )!.withOpacity(0.16 - t * 0.05);
      final c2 = Color.lerp(
        AppColors.cardClay,
        AppColors.cardMist,
        t,
      )!.withOpacity(0.12 - t * 0.04);

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2, Colors.transparent],
          stops: const [0.0, 0.7, 1.0],
        ).createShader(rect)
        ..blendMode = BlendMode.screen;

      canvas.drawPath(band, paint);
      canvas.drawPath(
        Path()
          ..moveTo(-40, y)
          ..cubicTo(
            size.width * 0.25,
            y - 28 - i * 1.2,
            size.width * 0.55,
            y + 34 + i * 1.8,
            size.width + 40,
            y - 10,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = AppColors.surfaceDark.withOpacity(0.06),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VibrantBands extends StatelessWidget {
  const _VibrantBands();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _VibrantBandsPainter());
  }
}

class _VibrantBandsPainter extends CustomPainter {
  const _VibrantBandsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    void drawRibbon(
      double offset,
      double bend,
      double thickness,
      List<Color> colors,
      double opacity,
    ) {
      final top = size.height * (0.65 - offset);
      final path = Path()
        ..moveTo(-60, top)
        ..cubicTo(
          size.width * 0.25,
          top - bend * 0.6,
          size.width * 0.65,
          top + bend,
          size.width + 60,
          top - bend * 0.8,
        )
        ..lineTo(size.width + 60, top + thickness)
        ..cubicTo(
          size.width * 0.65,
          top + bend + thickness,
          size.width * 0.25,
          top - bend * 0.6 + thickness,
          -60,
          top + thickness,
        )
        ..close();

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.map((c) => c.withOpacity(opacity)).toList(),
          stops: const [0.0, 0.6, 1.0],
        ).createShader(rect)
        ..blendMode = BlendMode.screen;

      canvas.drawPath(path, paint);

      final edge = Path()
        ..moveTo(-60, top)
        ..cubicTo(
          size.width * 0.25,
          top - bend * 0.6,
          size.width * 0.65,
          top + bend,
          size.width + 60,
          top - bend * 0.8,
        );
      canvas.drawPath(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = AppColors.cardAmber.withOpacity(opacity * 0.55),
      );
    }

    drawRibbon(0.00, 90, 26, [
      AppColors.cardCoral,
      AppColors.primary,
      Colors.transparent,
    ], 0.22);
    drawRibbon(0.12, 70, 22, [
      AppColors.cardAmber,
      AppColors.cardCoral,
      Colors.transparent,
    ], 0.18);
    drawRibbon(0.26, 60, 18, [
      AppColors.accent,
      AppColors.cardSage,
      Colors.transparent,
    ], 0.14);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EdgeSweep extends StatelessWidget {
  const _EdgeSweep();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _EdgeSweepPainter());
  }
}

class _EdgeSweepPainter extends CustomPainter {
  const _EdgeSweepPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final layers = 14;
    final startX = size.width * 0.62;

    for (int i = 0; i < layers; i++) {
      final inset = i * 14.0;
      final t = i / (layers - 1);

      Path p = Path()
        ..moveTo(startX + inset, -40)
        ..cubicTo(
          size.width * (0.80 + 0.04 * (1 - t)),
          size.height * 0.18,
          size.width * (0.76 + 0.02 * (1 - t)),
          size.height * 0.72,
          size.width + 40,
          size.height + 40,
        )
        ..lineTo(size.width + 40, -40)
        ..close();

      final a = Color.lerp(
        AppColors.primary,
        AppColors.cardAmber,
        t,
      )!.withOpacity(0.18 - t * 0.12);

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [a, Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..blendMode = BlendMode.screen;

      canvas.drawPath(p, paint);

      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = AppColors.cardClay.withOpacity(0.06 - t * 0.035),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
