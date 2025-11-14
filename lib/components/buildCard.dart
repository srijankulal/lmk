// filepath: c:\Codes\Projects\lmk\lib\components\buildCard.dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lmk/components/colours/colours.dart';
import 'package:lmk/data/local/reminder_local.dart';
import 'package:lmk/data/models/local/local_reminder.dart';
import 'package:lmk/data/repository/local/isar_service.dart';
import 'package:lmk/main.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:timezone/timezone.dart' as tz;
// Reuse the GlassCard theme from SetReminderScreen
import 'package:lmk/presentation/setReminder.dart' show GlassCard;

class Reminder {
  final String userId;
  final int id;
  final String title;
  final TimeOfDay time;
  final DateTime expiry_date;
  final DateTime? reminderDate;
  final int index;
  final bool isEnabled;
  final DateTime issue_date;

  Reminder({
    required this.userId,
    required this.id,
    required this.title,
    required this.time,
    required this.expiry_date,
    this.reminderDate,
    required this.index,
    required this.isEnabled,
    DateTime? issue_date,
  }) : issue_date = issue_date ?? DateTime(0, 0, 0);
}

class BuildCard extends StatefulWidget {
  final List<Reminder> reminders;
  final Function(int id)? onDelete;

  const BuildCard({super.key, required this.reminders, this.onDelete});

  @override
  State<BuildCard> createState() => _BuildCardState();
}

class _BuildCardState extends State<BuildCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController(); // ADDED

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ADDED
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28.00),
      child: widget.reminders.isEmpty
          ? Center(
              child: Text(
                "No reminders 😌",
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
              ),
            )
          : ScrollConfiguration(
              // ADDED
              behavior: const _SmoothScrollBehavior(),
              child: RawScrollbar(
                // ADDED
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 5,
                radius: const Radius.circular(12),
                minThumbLength: 48,
                thumbColor: Colors.white.withOpacity(0.25),
                child: ListView.builder(
                  controller: _scrollController, // ADDED
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ), // ADDED
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag, // ADDED
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  itemCount: widget.reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = widget.reminders[index];
                    final fadeAnim = CurvedAnimation(
                      parent: _controller,
                      curve: Interval(
                        (index * 0.1).clamp(0.0, 1.0),
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    );

                    return AnimatedBuilder(
                      animation: fadeAnim,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - fadeAnim.value)),
                          child: Opacity(
                            opacity: fadeAnim.value,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _GlossyReminderCard(
                                reminder: reminder,
                                onDelete: widget.onDelete,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _GlossyReminderCard extends StatefulWidget {
  final Reminder reminder;
  final Function(int id)? onDelete;

  const _GlossyReminderCard({required this.reminder, this.onDelete});

  @override
  State<_GlossyReminderCard> createState() => _GlossyReminderCardState();
}

class _GlossyReminderCardState extends State<_GlossyReminderCard> {
  static final List<Color> cardColors = [
    AppColors.cardSage,
    AppColors.cardClay,
    AppColors.cardAmber,
    AppColors.cardCoral,
  ];

  bool _isPressed = false;
  late Color _cardColor;
  late bool _isEnabled;

  // Local editable state
  late String _title;
  late TimeOfDay _time;
  late DateTime _expiryDate;
  DateTime? _reminderDate;

  @override
  void initState() {
    super.initState();
    _cardColor = cardColors[Random().nextInt(cardColors.length)];
    _isEnabled = widget.reminder.isEnabled;

    _title = widget.reminder.title;
    _time = widget.reminder.time;
    _expiryDate = widget.reminder.expiry_date;
    _reminderDate = widget.reminder.reminderDate;
    print('reminder data $widget.reminder');
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(widget.reminder.title),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25,
        children: [
          Builder(
            builder: (context) {
              bool _isPressed = false;
              return StatefulBuilder(
                builder: (context, setInnerState) {
                  return GestureDetector(
                    onTapDown: (_) => setInnerState(() => _isPressed = true),
                    onTapUp: (_) async {
                      await Future.delayed(const Duration(milliseconds: 120));
                      setInnerState(() => _isPressed = false);
                      _showDeleteDialog(context);
                    },
                    onTapCancel: () => setInnerState(() => _isPressed = false),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: _isPressed ? 0.93 : 1.0,
                      curve: Curves.easeOutBack,
                      child: Container(
                        height: double.infinity,
                        width: (MediaQuery.of(context).size.width * 0.22).clamp(
                          70.0,
                          120.0,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF3B3B), Color(0xFFFF5E3A)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(color: Colors.transparent),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: _isPressed
                                          ? [
                                              const Color(
                                                0xFFFF4C4C,
                                              ).withOpacity(0.85),
                                              const Color(
                                                0xFFFF1E1E,
                                              ).withOpacity(0.6),
                                            ]
                                          : [
                                              const Color(
                                                0xFFFF5B5B,
                                              ).withOpacity(0.75),
                                              const Color(
                                                0xFFFF7C5C,
                                              ).withOpacity(0.55),
                                            ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: 50,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withOpacity(0.25),
                                          Colors.white.withOpacity(0.05),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF3B3B,
                                        ).withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: -5,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.1),
                                        blurRadius: 12,
                                        spreadRadius: -3,
                                        offset: const Offset(0, -3),
                                      ),
                                    ],
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        LucideIcons.trash2,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        "Delete",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
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
            },
          ),
        ],
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          setState(() => _isPressed = false);
        },
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => _showEditDialog(context),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _cardColor.withOpacity(_isEnabled ? 0.9 : 0.5),
                  _cardColor.withOpacity(_isEnabled ? 0.8 : 0.4),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: _cardColor.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: -4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: _buildCardContent(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _title,
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(
                    _isEnabled ? 1.0 : 0.5,
                  ),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  decoration: _isEnabled ? null : TextDecoration.lineThrough,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.textPrimary.withOpacity(
                      _isEnabled ? 1.0 : 0.5,
                    ),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _time.format(context),
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(
                        _isEnabled ? 1.0 : 0.5,
                      ),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if ((_reminderDate ?? _expiryDate) != null)
                    _dateChip(
                      icon: Icons.notifications_active_rounded,
                      label: 'Reminds',
                      date: (_reminderDate ?? _expiryDate),
                    ),
                  _dateChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Expires',
                    date: _expiryDate,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (_isEnabled) {
                  await flutterLocalNotificationsPlugin.cancel(
                    widget.reminder.index,
                  );
                  await _upDateDB(
                    widget.reminder.copyWith(
                      isEnabled: false,
                      time: _time,
                      expiry_date: _expiryDate,
                      title: _title,
                      reminderDate: _reminderDate,
                    ),
                  );
                  setState(() {
                    _isEnabled = _isEnabled;
                  });
                  HapticFeedback.lightImpact();
                } else if (!_isEnabled) {
                  await _upDateDB(
                    widget.reminder.copyWith(
                      isEnabled: true,
                      time: _time,
                      expiry_date: _expiryDate,
                      title: _title,
                      reminderDate: _reminderDate,
                    ),
                  );
                  setState(() {
                    _isEnabled = _isEnabled;
                  });
                  HapticFeedback.lightImpact();
                  // Show a loading bar while scheduling
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.surface.withOpacity(0.9),
                      content: Row(
                        children: [
                          const Expanded(child: Text('Scheduling reminder...')),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                  await flutterLocalNotificationsPlugin.zonedSchedule(
                    widget.reminder.index,
                    'Reminder: $_title',
                    'It\'s time for your reminder scheduled at ${_time.format(context)}',
                    tz.TZDateTime.from(
                      DateTime(
                        _expiryDate.year,
                        _expiryDate.month,
                        _expiryDate.day,
                        _time.hour,
                        _time.minute,
                      ),
                      tz.local,
                    ),
                    const NotificationDetails(
                      android: AndroidNotificationDetails(
                        'reminder_channel',
                        'Reminders',
                        channelDescription:
                            'Channel for reminder notifications',
                        importance: Importance.max,
                        priority: Priority.high,
                      ),
                    ),
                    androidScheduleMode:
                        AndroidScheduleMode.exactAllowWhileIdle,
                  );
                }

                setState(() {
                  _isEnabled = !_isEnabled;
                });
                _upDateDB(
                  widget.reminder.copyWith(
                    isEnabled: _isEnabled,
                    time: _time,
                    expiry_date: _expiryDate,
                    title: _title,
                    reminderDate: _reminderDate,
                  ),
                );
                HapticFeedback.lightImpact();
              },
              child: Container(
                width: 52,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _isEnabled
                      ? AppColors.success.withOpacity(0.8)
                      : Colors.white.withOpacity(0.3),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: _isEnabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateChip({
    required IconData icon,
    required String label,
    required DateTime date,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary.withOpacity(_isEnabled ? 1.0 : 0.5),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$label ${date.toLocal().toString().split(' ')[0]}',
            style: TextStyle(
              color: AppColors.textPrimary.withOpacity(_isEnabled ? 0.9 : 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final _editFormKey = GlobalKey<ShadFormState>();
    TimeOfDay selectedTime = _time;
    DateTime selectedDate = DateTime(
      _expiryDate.year,
      _expiryDate.month,
      _expiryDate.day,
    );
    String title = _title;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, __) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: ShadForm(
                    key: _editFormKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.pen,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Edit reminder',
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
                            id: 'Title',
                            label: const Text('Title'),
                            initialValue: title,
                            onChanged: (v) => title = v ?? '',
                            leading: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                LucideIcons.bell,
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
                            initialValue: selectedDate,
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
                              if (value == null)
                                return 'Reminder date is required';
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
                            onChanged: (v) {
                              if (v != null) selectedDate = v;
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
                                  child: StatefulBuilder(
                                    builder: (context, setSB) {
                                      return Text(
                                        'Selected: ${((selectedTime.hour % 12 == 0 ? 12 : selectedTime.hour % 12)).toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.hour >= 12 ? 'PM' : 'AM'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ShadButton(
                                leading: const Icon(LucideIcons.clock),

                                backgroundColor: AppColors.primary,
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: AppColors.primary,
                                            onPrimary: AppColors.background,
                                            surface: AppColors.surface,
                                            onSurface: AppColors.primary,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    selectedTime = picked;
                                    (context as Element).markNeedsBuild();
                                  }
                                },
                                child: const Text('Pick time'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              const Spacer(),
                              ShadButton(
                                backgroundColor: AppColors.primary,
                                child: const Text('Save'),
                                onPressed: () async {
                                  final ok = _editFormKey.currentState!
                                      .saveAndValidate();
                                  if (!ok) {
                                    ShadToaster.of(context).show(
                                      ShadToast.destructive(
                                        title: const Text('Validation failed'),
                                        description: const Text(
                                          'Please correct the errors.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  if (title.trim().isEmpty) {
                                    ShadToaster.of(context).show(
                                      ShadToast.destructive(
                                        title: const Text('Title required'),
                                        description: const Text(
                                          'Enter a title.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  // time in the past on same day?
                                  final now = DateTime.now();
                                  final isToday =
                                      selectedDate.year == now.year &&
                                      selectedDate.month == now.month &&
                                      selectedDate.day == now.day;
                                  final nowTime = TimeOfDay.fromDateTime(now);
                                  bool isBefore(TimeOfDay a, TimeOfDay b) {
                                    return a.hour < b.hour ||
                                        (a.hour == b.hour &&
                                            a.minute < b.minute);
                                  }

                                  if (isToday &&
                                      isBefore(selectedTime, nowTime)) {
                                    ShadToaster.of(context).show(
                                      ShadToast.destructive(
                                        title: const Text('Invalid time'),
                                        description: const Text(
                                          'Selected time is in the past.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  print(
                                    'Updating reminder to: $title at $selectedTime on $selectedDate',
                                  );

                                  // Update DB first
                                  await ReminderLocalDataSource().updateReminder(
                                    ReminderLocal(
                                      userId: widget.reminder.userId,
                                      id: widget.reminder.id,
                                      title: title,
                                      index: widget.reminder.index,
                                      issuedDate: widget.reminder.issue_date,
                                      time:
                                          "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                                      expiryDate: widget.reminder.expiry_date,
                                      reminderDate: selectedDate,

                                      isEnabled: _isEnabled,
                                    ),
                                  );

                                  // Re-schedule/cancel based on enabled
                                  await flutterLocalNotificationsPlugin.cancel(
                                    widget.reminder.index,
                                  );
                                  if (_isEnabled) {
                                    await flutterLocalNotificationsPlugin.zonedSchedule(
                                      widget.reminder.index,
                                      'Reminder: $title',
                                      'It\'s time for your reminder scheduled at ${selectedTime.format(context)}',
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
                                      const NotificationDetails(
                                        android: AndroidNotificationDetails(
                                          'reminder_channel',
                                          'Reminders',
                                          channelDescription:
                                              'Channel for reminder notifications',
                                          importance: Importance.max,
                                          priority: Priority.high,
                                        ),
                                      ),
                                      androidScheduleMode: AndroidScheduleMode
                                          .exactAllowWhileIdle,
                                    );
                                  }

                                  if (mounted) {
                                    setState(() {
                                      _title = title;
                                      _time = selectedTime;
                                      _expiryDate = selectedDate;
                                      _reminderDate =
                                          selectedDate; // display reminder date too
                                    });
                                    Navigator.of(context).pop();
                                    ShadToaster.of(context).show(
                                      const ShadToast(
                                        duration: Duration(milliseconds: 1500),
                                        backgroundColor: AppColors.success,
                                        title: Text(
                                          'Reminder updated',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
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
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, _, __) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background.withAlpha(95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(30),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Delete Reminder?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'This action cannot be undone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ShadButton.outline(
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                              ShadButton(
                                backgroundColor: Colors.redAccent,
                                child: const Text('Delete'),
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  bool deleted = await ReminderLocalDataSource()
                                      .deleteReminder(widget.reminder.id);

                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();

                                  if (deleted) {
                                    await flutterLocalNotificationsPlugin
                                        .cancel(widget.reminder.index);
                                    widget.onDelete?.call(widget.reminder.id);
                                    Navigator.of(context).pop(true);
                                    ShadToaster.of(context).show(
                                      const ShadToast(
                                        duration: Duration(milliseconds: 1500),
                                        backgroundColor: AppColors.success,
                                        title: Text(
                                          'Reminder Deleted',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.of(context).pop(false);
                                    ShadToaster.of(context).show(
                                      ShadToast.destructive(
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
                                        title: const Text(
                                          'Failed to Delete Reminder',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
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
        );
      },
    );
  }

  Future<void> _upDateDB(Reminder reminder) async {
    await ReminderLocalDataSource().updateReminder(
      ReminderLocal(
        userId: reminder.userId,
        id: reminder.id,
        title: reminder.title,
        index: reminder.index,
        time:
            "${reminder.time.hour.toString().padLeft(2, '0')}:${reminder.time.minute.toString().padLeft(2, '0')}",
        expiryDate: reminder.expiry_date,
        isEnabled: _isEnabled,
      ),
    );
  }
}

// Small helper to clone Reminder with changes for local updates
extension _CopyReminder on Reminder {
  Reminder copyWith({
    String? userId,
    int? id,
    String? title,
    TimeOfDay? time,
    DateTime? expiry_date,
    DateTime? reminderDate,
    int? index,
    bool? isEnabled,
    DateTime? issue_date,
  }) {
    return Reminder(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      expiry_date: expiry_date ?? this.expiry_date,
      reminderDate: reminderDate ?? this.reminderDate,
      index: index ?? this.index,
      isEnabled: isEnabled ?? this.isEnabled,
      issue_date: issue_date ?? this.issue_date,
    );
  }
}

// ADDED: smooth, bounce overscroll + stretch
class _SmoothScrollBehavior extends ScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
